// lib/vat/screens/vat_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vat_response_model.dart';
import '../models/vat_registration_process_model.dart';
import '../service/vat_service.dart';
import '../service/vat_registration_process_service.dart';
import '../../Vat/service/center_admin_bridge.dart';
import 'vat_update_page.dart';
import 'vat_payment_page.dart';
import 'my_vat_process_control_page.dart';
import '../../RJSC/screens/rjsc_attachment_viewer.dart';

class VatDetailsPage extends StatefulWidget {
  final VatResponseModel vat;
  final String? currentUserId;

  const VatDetailsPage({
    super.key,
    required this.vat,
    required this.currentUserId,
  });

  @override
  State<VatDetailsPage> createState() => _VatDetailsPageState();
}

class _VatDetailsPageState extends State<VatDetailsPage> {
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  late VatResponseModel _vat;
  bool _busy = false;

  // ✅ Ownership flags
  bool get _isMine =>
      widget.currentUserId != null &&
      widget.currentUserId!.isNotEmpty &&
      widget.currentUserId == _vat.userId;

  /// ✅ True when current user is the Center Admin of THIS VAT's process
  ///    (i.e. registrationProcess.userId == currentUserId)
  bool get _isCenterAdminOfThis {
    final rp = _vat.vatRegistrationProcessResponseDTO;
    return rp != null &&
        widget.currentUserId != null &&
        widget.currentUserId!.isNotEmpty &&
        rp.userId == widget.currentUserId;
  }

  bool get _hasProcess =>
      _vat.vatRegistrationProcessResponseDTO != null;

  @override
  void initState() {
    super.initState();
    _vat = widget.vat;
  }

  // ============ RELOAD ============
  Future<void> _reload() async {
    if (_vat.id == null) return;
    try {
      final fresh = await VatService.findById(_vat.id!);
      if (mounted) setState(() => _vat = fresh);
    } catch (_) {}
  }

  // ============ DELETE VAT ============
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete VAT?'),
        content: const Text(
          'This will permanently delete this VAT and its registration process. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await VatService.deleteVat(
        id: _vat.id!,
        userId: widget.currentUserId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VAT deleted successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed: $e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ============ EDIT VAT ============
  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VatUpdatePage(vat: _vat.toVatModel()),
      ),
    );
    if (updated == true) {
      await _reload();
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ============ PAYMENT ============
  Future<void> _openPayment() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VatPaymentPage(
          vat: _vat,
          currentUserId: widget.currentUserId,
          canPay: _isMine, // ✅ pay button only for the VAT owner
        ),
      ),
    );
    if (changed == true) {
      setState(() {});
    }
  }

  // ============ ACCEPT (as Center Admin) ============
  Future<void> _confirmAccept() async {
    final advocate = await _pickAdvocate();
    if (advocate == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept as Center Admin?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You will become the registration process controller for this VAT filing.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, size: 16, color: _primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assigned Advocate: ${advocate.name}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final process = VatRegistrationProcessModel(
        vatId: _vat.id ?? '',
        userId: widget.currentUserId!,
        advocateId: advocate.id,
        status: false,
        steps: const ['accepted'],
      );

      await VatRegistrationProcessService.addProcess(
        userId: widget.currentUserId!,
        process: process,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VAT registration process accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _reload();
    } catch (e) {
      _snack('Failed: $e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ============ UPDATE PROCESS ============
  Future<void> _openEditProcess() async {
    final process = _vat.vatRegistrationProcessResponseDTO;
    if (process == null) return;

    final stepControllers = process.steps
        .map((s) => TextEditingController(text: s))
        .toList();
    if (stepControllers.isEmpty) stepControllers.add(TextEditingController());

    bool status = process.status;

    AdvocateBrief? selectedAdvocate = AdvocateBrief(
      id: process.advocateId,
      name: process.advocateName.isNotEmpty
          ? process.advocateName
          : process.advocateId,
    );

    // Refresh advocate list and try to find matching entry
    try {
      final list =
          await CenterAdminBridge.myAdvocates(widget.currentUserId ?? '');
      for (final a in list) {
        if (a.id == process.advocateId) {
          selectedAdvocate = a;
          break;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void addStep() => setLocal(
                () => stepControllers.add(TextEditingController()));

            void removeStep(int i) {
              if (stepControllers.length <= 1) return;
              setLocal(() {
                stepControllers[i].dispose();
                stepControllers.removeAt(i);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Update VAT Process'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Advocate',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await _pickAdvocate();
                          if (picked != null) {
                            setLocal(() => selectedAdvocate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.gavel,
                                  size: 16, color: _primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedAdvocate?.name ??
                                      'Select advocate',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Steps',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: addStep,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Step',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 32),
                              foregroundColor: _primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(stepControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: stepControllers[i],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Describe step ${i + 1}...',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Remove step',
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: stepControllers.length <= 1
                                      ? Colors.grey.shade300
                                      : Colors.red,
                                ),
                                onPressed: stepControllers.length <= 1
                                    ? null
                                    : () => removeStep(i),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Mark as completed (status = true)'),
                        value: status,
                        onChanged: (v) => setLocal(() => status = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      for (final c in stepControllers) {
        c.dispose();
      }
      return;
    }

    final steps = <String>[];
    for (final c in stepControllers) {
      final v = c.text.trim();
      if (v.isNotEmpty) steps.add(v);
    }

    final updated = VatRegistrationProcessModel(
      id: process.id,
      vatId: _vat.id ?? '',
      userId: process.userId,
      advocateId: selectedAdvocate?.id ?? process.advocateId,
      status: status,
      steps: steps,
    );

    setState(() => _busy = true);
    try {
      await VatRegistrationProcessService.updateProcess(
        id: process.id ?? '',
        userId: widget.currentUserId!,
        process: updated,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VAT process updated'),
          backgroundColor: Colors.green,
        ),
      );
      await _reload();
    } catch (e) {
      _snack('Failed: $e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ============ DELETE PROCESS ============
  Future<void> _confirmDeleteProcess() async {
    final process = _vat.vatRegistrationProcessResponseDTO;
    if (process == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete VAT Process?'),
        content: const Text(
          'This will remove your registration process for this VAT filing. '
          'The VAT record itself will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await VatRegistrationProcessService.deleteProcess(
        id: process.id ?? '',
        userId: widget.currentUserId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VAT process deleted'),
          backgroundColor: Colors.green,
        ),
      );
      await _reload();
    } catch (e) {
      _snack('Failed: $e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ============ OPEN MY VAT PROCESS CONTROL ============
  Future<void> _openMyVatProcessControl() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyVatProcessControlPage(),
      ),
    );
    if (mounted) await _reload();
  }

  // ============ ADVOCATE PICKER ============
  Future<AdvocateBrief?> _pickAdvocate() async {
    if (widget.currentUserId == null ||
        widget.currentUserId!.isEmpty) {
      return null;
    }

    List<AdvocateBrief> advocates;
    try {
      advocates =
          await CenterAdminBridge.myAdvocates(widget.currentUserId!);
    } catch (e) {
      _snack('Failed to load advocates: $e', true);
      return null;
    }

    if (!mounted) return null;

    if (advocates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You have no advocates connected. Please add one first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    return showModalBottomSheet<AdvocateBrief>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select an Advocate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick the advocate who will handle this VAT filing',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: advocates.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (context, i) {
                    final a = advocates[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.gavel,
                            color: _primaryBlue, size: 20),
                      ),
                      title: Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'ID: ${a.id}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.grey),
                      onTap: () => Navigator.pop(context, a),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ OPEN VIEWER ============
  Future<void> _openViewer(String attachmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RJSCAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: token,
        ),
      ),
    );
  }

  // ============ SNACK ============
  void _snack(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final process = _vat.vatRegistrationProcessResponseDTO;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'VAT Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (_isMine) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: _primaryBlue),
              tooltip: 'Edit',
              onPressed: _busy ? null : _openEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _busy ? null : _confirmDelete,
            ),
          ],
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header card ----
                  _headerCard(),

                  const SizedBox(height: 14),

                  // ---- Registration progress ----
                  if (process != null) _processCard(process),

                  const SizedBox(height: 14),

                  // ---- Business Info ----
                  _sectionCard(
                    title: 'Business Information',
                    icon: Icons.info_outline,
                    rows: [
                      _kv('Business Name', _vat.buisnessName),
                      _kv('Owner',
                          _vat.userName.isEmpty ? '-' : _vat.userName),
                      _kv('TIN No.', _vat.tinNo),
                      _kv('Trade License No.', _vat.tradeLicenseNo),
                      _kv('Business Address', _vat.adress),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---- Business Details ----
                  _sectionCard(
                    title: 'Business Details',
                    icon: Icons.business_center_outlined,
                    rows: [
                      _kv('Nature of Business', _vat.natureOfBuisness),
                      _kv('Annual Turnover', _vat.annualTurnOver),
                      _kv('Main Product / Service', _vat.mainProduct),
                      _kv('No. of Employees', '${_vat.numberOfEmployee}'),
                      _kv('No. of Businesses', '${_vat.numberOfBuisness}'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---- Documents ----
                  if (_vat.documents.isNotEmpty)
                    _sectionCard(
                      title: 'Documents (${_vat.documents.length})',
                      icon: Icons.attach_file,
                      children: [
                        ..._vat.documents.asMap().entries.map((e) {
                          final idx = e.key + 1;
                          final id = e.value;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: _primaryBlue,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Document $idx',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility,
                                      color: _primaryBlue, size: 20),
                                  onPressed: () => _openViewer(id),
                                  tooltip: 'View',
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // ── CENTER ADMIN CONTROLS ──
                  if (_isCenterAdminOfThis || !_hasProcess) ...[
                    _centerAdminControls(),
                    const SizedBox(height: 14),
                  ],

                  // ── PAYMENT CTA ──
                  // Visible to owner AND center admin.
                  // The `canPay` flag inside VatPaymentPage controls the
                  // "Pay" button (owner-only).
                  if (_isMine || _isCenterAdminOfThis) ...[
                    _paymentCta(),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ============ Center Admin Controls ============
  Widget _centerAdminControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryBlue.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: _primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Center Admin Controls',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shortcut to My VAT Processes
          OutlinedButton.icon(
            onPressed: _openMyVatProcessControl,
            icon: const Icon(Icons.list_alt),
            label: const Text('My VAT Processes'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              side: const BorderSide(color: _primaryBlue),
              foregroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (!_hasProcess) ...[
            ElevatedButton.icon(
              onPressed: _confirmAccept,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept Registration Process'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ] else if (_isCenterAdminOfThis) ...[
            ElevatedButton.icon(
              onPressed: _openEditProcess,
              icon: const Icon(Icons.edit_note),
              label: const Text('Update Registration Process'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _confirmDeleteProcess,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Registration Process'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ Header Card ============
  Widget _headerCard() {
    final process = _vat.vatRegistrationProcessResponseDTO;
    final isApproved = process != null && process.status == true;
    final color = isApproved ? Colors.green : Colors.orange;
    final label = isApproved ? 'Approved' : 'Pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryBlue,
            _primaryBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vat.buisnessName.isEmpty
                          ? 'Unnamed Business'
                          : _vat.buisnessName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Application ID: VAT-${_vat.id?.substring(0, _vat.id!.length > 8 ? 8 : _vat.id!.length).toUpperCase() ?? '?'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Badge: yours / admin
              if (_isMine)
                _headerBadge(icon: Icons.person, label: 'Yours')
              else if (_isCenterAdminOfThis)
                _headerBadge(
                    icon: Icons.admin_panel_settings, label: 'Admin'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApproved ? Icons.check_circle : Icons.hourglass_top,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============ Registration Process Card ============
  Widget _processCard(VatRegistrationProcessResponseModel p) {
    return _sectionCard(
      title: 'Registration Progress',
      icon: Icons.track_changes,
      children: [
        _kv('Advocate', p.advocateName.isEmpty ? '-' : p.advocateName),
        _kv('Status', p.status ? 'Active' : 'Inactive'),
        const SizedBox(height: 8),
        if (p.steps.isNotEmpty) ...[
          Text(
            'Steps (${p.steps.length})',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          ...p.steps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryBlue,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ============ Payment CTA ============
  Widget _paymentCta() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payments,
                color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payments',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Total: ৳ 5,000',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openPayment,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Reusable UI ============
  Widget _sectionCard({
    required String title,
    required IconData icon,
    List<Widget>? children,
    List<Widget>? rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: _primaryBlue, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows != null) ...rows,
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? '-' : v,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}