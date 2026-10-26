// lib/TradeLicense/screens/trade_license_details_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../../RJSC/screens/rjsc_attachment_viewer.dart';
import '../../Vat/service/center_admin_bridge.dart'; // ✅ for AdvocateBrief
import '../models/trade_license_response_dto.dart';
import '../models/trade_license_model.dart';
import '../models/trade_license_registration_process_model.dart';
import '../services/trade_license_service.dart';
import '../services/trade_license_registration_process_service.dart';
import 'trade_license_update_screen.dart';
import 'widgets/trade_license_payment_section.dart';
import 'my_trade_license_process_control_screen.dart'; // ✅ NEW

class TradeLicenseDetailsScreen extends StatefulWidget {
  final TradeLicenseResponseDTO license;
  final bool isOwner;

  const TradeLicenseDetailsScreen({
    super.key,
    required this.license,
    required this.isOwner,
  });

  @override
  State<TradeLicenseDetailsScreen> createState() =>
      _TradeLicenseDetailsScreenState();
}

class _TradeLicenseDetailsScreenState extends State<TradeLicenseDetailsScreen> {
  static const Color _primaryGreen = Color(0xFF1E7A3A);

  late TradeLicenseResponseDTO _l;
  bool _isDeleting = false;
  bool _isBusy = false;
  String? _currentUserId;
  String? _currentUserName;

  /// ✅ True when current user is the Center Admin of THIS TL's process
  ///    (i.e. registrationProcess.userId == currentUserId)
  bool get _isCenterAdminOfThis {
    final rp = _l.tradeLicenseRegistrationProcess;
    return rp != null &&
        _currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        rp.userId == _currentUserId;
  }

  bool get _hasProcess => _l.tradeLicenseRegistrationProcess != null;

  @override
  void initState() {
    super.initState();
    _l = widget.license;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await AuthService.getUserId();
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
      _currentUserName = '';
    });
  }

  Future<void> _reload() async {
    if (_l.id == null) return;
    try {
      final res = await TradeLicenseService.findById(_l.id!);
      final fresh = TradeLicenseService.parseSingle(res);
      if (fresh != null && mounted) {
        setState(() => _l = fresh);
      }
    } catch (_) {}
  }

  // ============ DELETE (whole TL) ============
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Trade License?'),
        content: const Text(
            'This action cannot be undone. Are you sure you want to delete this trade license?'),
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

    setState(() => _isDeleting = true);
    final userId = await AuthService.getUserId() ?? '';
    final res = await TradeLicenseService.deleteTradeLicense(
      id: _l.id ?? '',
      userId: userId,
    );
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade license deleted'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message'] ?? 'Failed to delete'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ============ EDIT TL ============
  Future<void> _openEdit() async {
    final model = TradeLicenseModel(
      id: _l.id,
      userId: _l.userId,
      buisnessName: _l.buisnessName,
      mobileNumber: _l.mobileNumber,
      emailAdress: _l.emailAdress,
      buisnessType: _l.buisnessType,
      buisnessCategory: _l.buisnessCategory,
      documents: _l.documents,
    );
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TradeLicenseUpdateScreen(existingLicense: model),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // ============ ACCEPT PROCESS (as Center Admin) ============
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
              'You will become the registration process controller for this Trade License filing.',
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
                  const Icon(Icons.gavel,
                      size: 16, color: _primaryGreen),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBusy = true);
    try {
      final process = TradeLicenseRegistrationProcessModel(
        userId: _currentUserId!,
        advocateId: advocate.id,
        status: false,
        tradeLicenseId: _l.id ?? '',
        steps: const ['accepted'],
      );

      await TradeLicenseRegistrationProcessService.addProcess(
        userId: _currentUserId!,
        process: process,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Trade License registration process accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ============ UPDATE PROCESS ============
  Future<void> _openEditProcess() async {
    final process = _l.tradeLicenseRegistrationProcess;
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

    try {
      final list = await CenterAdminBridge.myAdvocates(_currentUserId ?? '');
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
              title: const Text('Update Trade License Process'),
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
                                  size: 16, color: _primaryGreen),
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
                              foregroundColor: _primaryGreen,
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
                                  color: _primaryGreen.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryGreen,
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
                      backgroundColor: _primaryGreen),
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

    final updated = TradeLicenseRegistrationProcessModel(
      id: process.id,
      userId: process.userId,
      advocateId: selectedAdvocate?.id ?? process.advocateId,
      status: status,
      tradeLicenseId: _l.id ?? '',
      steps: steps,
    );

    setState(() => _isBusy = true);
    try {
      await TradeLicenseRegistrationProcessService.updateProcess(
        id: process.id ?? '',
        userId: _currentUserId!,
        process: updated,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade License process updated'),
          backgroundColor: Colors.green,
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ============ DELETE PROCESS ============
  Future<void> _confirmDeleteProcess() async {
    final process = _l.tradeLicenseRegistrationProcess;
    if (process == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Trade License Process?'),
        content: const Text(
          'This will remove your registration process for this Trade License filing. '
          'The Trade License record itself will remain.',
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

    setState(() => _isBusy = true);
    try {
      await TradeLicenseRegistrationProcessService.deleteProcess(
        id: process.id ?? '',
        userId: _currentUserId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade License process deleted'),
          backgroundColor: Colors.green,
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ============ OPEN MY TL PROCESS CONTROL ============
  Future<void> _openMyTlProcessControl() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTradeLicenseProcessControlScreen(),
      ),
    );
    if (mounted) await _reload();
  }

  // ============ ADVOCATE PICKER ============
  Future<AdvocateBrief?> _pickAdvocate() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return null;

    List<AdvocateBrief> advocates;
    try {
      advocates = await CenterAdminBridge.myAdvocates(_currentUserId!);
    } catch (e) {
      if (!mounted) return null;
      _snack('Failed to load advocates: $e', isError: true);
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
                'Pick the advocate who will handle this Trade License filing',
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
                        backgroundColor: _primaryGreen.withOpacity(0.1),
                        child: const Icon(Icons.gavel,
                            color: _primaryGreen, size: 20),
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

  Future<void> _openDocument(String attachmentId) async {
    final token = await AuthService.getToken() ?? '';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Document Viewer',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: RJSCAttachmentViewer(
            attachmentId: attachmentId,
            jwtToken: token,
          ),
        ),
      ),
    );
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreeConsultantPage(
          currentUserId: _currentUserId,
          currentUserName: _currentUserName,
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : _primaryGreen,
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final process = _l.tradeLicenseRegistrationProcess;
    final isApproved = process != null && process.status == true;
    final isPending = process == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Trade License Details',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
        actions: [
          if (widget.isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'edit') _openEdit();
                if (v == 'delete') _confirmDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Color(0xFF1E7A3A)),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: (_isDeleting || _isBusy)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(isApproved, isPending),
                  const SizedBox(height: 16),

                  // ---------- Business Information ----------
                  _section('Business Information', [
                    _row('Business Name', _l.buisnessName),
                    _row('Business Type', _l.buisnessType),
                    _row('Category', _l.buisnessCategory),
                  ]),
                  const SizedBox(height: 16),

                  // ---------- Contact Information ----------
                  _section('Contact Information', [
                    _row('Owner / Applicant', _l.userName),
                    _row('Mobile', _l.mobileNumber),
                    _row('Email', _l.emailAdress),
                  ]),
                  const SizedBox(height: 16),

                  // ---------- Documents ----------
                  _section('Documents', [
                    if (_l.documents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.folder_off_outlined,
                                color: Colors.grey.shade400, size: 20),
                            const SizedBox(width: 8),
                            Text('No documents uploaded',
                                style: TextStyle(
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    else
                      ..._l.documents.asMap().entries.map((e) {
                        return _docTile(
                          index: e.key + 1,
                          id: e.value,
                          onTap: () => _openDocument(e.value),
                        );
                      }),
                  ]),
                  const SizedBox(height: 16),

                  // ---------- Application Status ----------
                  _section('Application Status', [
                    if (isPending)
                      _row('Status', 'Pending Review')
                    else if (process != null) ...[
                      _row('Status',
                          process.status == true ? 'Approved' : 'Processing'),
                      if (process.advocateName.isNotEmpty)
                        _row('Assigned Advocate', process.advocateName),
                      if (process.steps.isNotEmpty)
                        _row('Progress', process.steps.join(' → ')),
                    ],
                    if (_l.id != null) _row('Application ID', _l.id!),
                  ]),

                  // ---------- CENTER ADMIN CONTROLS ----------
                  if (_isCenterAdminOfThis || !_hasProcess) ...[
                    const SizedBox(height: 16),
                    _centerAdminControls(),
                  ],

                  // ---------- Payment Section (owner OR center admin) ----------
                  if ((widget.isOwner || _isCenterAdminOfThis) &&
                      _l.id != null) ...[
                    const SizedBox(height: 16),
                    TradeLicensePaymentSection(
                      tradeLicenseId: _l.id!,
                      isOwner: widget.isOwner, // ✅ pay button only for owner
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ---------- Chat with Executive ----------
                  OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with Executive'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: _primaryGreen),
                      foregroundColor: _primaryGreen,
                    ),
                  ),

                  // ---------- Owner-only actions ----------
                  if (widget.isOwner) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Trade License'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: _primaryGreen),
                        foregroundColor: _primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Trade License'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ============ Center Admin Controls ============
  Widget _centerAdminControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryGreen.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Center Admin Controls',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shortcut to My TL Processes
          OutlinedButton.icon(
            onPressed: _openMyTlProcessControl,
            icon: const Icon(Icons.list_alt),
            label: const Text('My Trade License Processes'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              side: const BorderSide(color: _primaryGreen),
              foregroundColor: _primaryGreen,
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
                backgroundColor: _primaryGreen,
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
                backgroundColor: _primaryGreen,
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

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _header(bool isApproved, bool isPending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryGreen.withOpacity(0.1),
            ),
            child: const Icon(Icons.store,
                color: _primaryGreen, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            _l.buisnessName.isEmpty ? 'Untitled' : _l.buisnessName,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_l.buisnessType.isEmpty ? '-' : _l.buisnessType,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          _statusChip(isApproved, isPending),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E7A3A))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _docTile({
    required int index,
    required String id,
    required VoidCallback onTap,
  }) {
    final isPdf = id.toLowerCase().contains('pdf');
    return Material(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: isPdf ? Colors.red : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document $index',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Tap to view',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.visibility_outlined,
                  size: 18, color: Color(0xFF1E7A3A)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool isApproved, bool isPending) {
    final color = isApproved
        ? const Color(0xFF2E7D32)
        : (isPending ? const Color(0xFFE65100) : Colors.grey);
    final label = isApproved
        ? 'Approved'
        : (isPending ? 'Pending Review' : 'Unknown');
    final icon = isApproved
        ? Icons.check_circle
        : (isPending ? Icons.hourglass_empty : Icons.help);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}