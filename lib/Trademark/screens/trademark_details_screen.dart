// lib/Trademark/screens/trademark_details_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../../RJSC/screens/rjsc_attachment_viewer.dart';
import '../../Vat/service/center_admin_bridge.dart'; // ✅ for AdvocateBrief
import '../models/trademark_response_dto.dart';
import '../models/trademark_model.dart';
import '../models/trademark_registration_process_model.dart';
import '../services/trademark_service.dart';
import '../services/trademark_registration_process_service.dart';
import 'trademark_update_screen.dart';
import 'widgets/trademark_payment_section.dart';
import 'my_trademark_process_control_screen.dart'; // ✅ NEW

class TrademarkDetailsScreen extends StatefulWidget {
  final TrademarkResponse trademark;
  final bool isOwner;

  const TrademarkDetailsScreen({
    super.key,
    required this.trademark,
    required this.isOwner,
  });

  @override
  State<TrademarkDetailsScreen> createState() =>
      _TrademarkDetailsScreenState();
}

class _TrademarkDetailsScreenState extends State<TrademarkDetailsScreen> {
  static const Color _primaryPurple = Color(0xFF6A1B9A);

  late TrademarkResponse _t;
  bool _isDeleting = false;
  bool _isBusy = false;
  String? _currentUserId;
  String? _currentUserName;

  /// ✅ True when current user is the Center Admin of THIS Trademark's process
  ///    (i.e. registrationProcess.centerAdminUserId == currentUserId)
  bool get _isCenterAdminOfThis {
    final rp = _t.registrationProcess;
    return rp != null &&
        _currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        rp.centerAdminUserId == _currentUserId;
  }

  bool get _hasProcess => _t.registrationProcess != null;

  @override
  void initState() {
    super.initState();
    _t = widget.trademark;
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
    if (_t.id == null) return;
    try {
      final res = await TrademarkService.findById(_t.id!);
      final fresh = TrademarkService.parseSingle(res);
      if (fresh != null && mounted) setState(() => _t = fresh);
    } catch (_) {}
  }

  // ============ DELETE (whole Trademark) ============
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Trademark?'),
        content: const Text(
            'This action cannot be undone. Are you sure you want to delete this trademark?'),
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
    final res = await TrademarkService.deleteTrademark(
      id: _t.id ?? '',
      userId: userId,
    );
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trademark deleted'),
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

  // ============ EDIT ============
  Future<void> _openEdit() async {
    final model = TrademarkModel(
      id: _t.id,
      userId: _t.userId,
      legalProtection: _t.legalProtection,
      nationWiseValidity: _t.nationWiseValidity,
      applicationType: _t.applicationType,
      applicationName: _t.applicationName,
      governmentFee: _t.governmentFee,
      organaizationalName: _t.organaizationalName,
      trademarkName: _t.trademarkName,
      trademarkType: _t.trademarkType,
      classOfGoods: _t.classOfGoods,
      adress: _t.adress,
      email: _t.email,
      mobileNumber: _t.mobileNumber,
      documents: _t.documents,
    );
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrademarkUpdateScreen(existingTrademark: model),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  // ============ ACCEPT PROCESS ============
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
              'You will become the registration process controller for this Trademark filing.',
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
                      size: 16, color: _primaryPurple),
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
                backgroundColor: _primaryPurple),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBusy = true);
    try {
      final process = TrademarkRegistrationProcessModel(
        userId: _currentUserId!,
        advocateId: advocate.id,
        tradeMarkId: _t.id ?? '',
        status: false,
        steps: const ['accepted'],
      );

      await TrademarkRegistrationProcessService.addProcess(
        userId: _currentUserId!,
        process: process,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Trademark registration process accepted successfully'),
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
    final process = _t.registrationProcess;
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
              title: const Text('Update Trademark Process'),
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
                                  size: 16, color: _primaryPurple),
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
                              foregroundColor: _primaryPurple,
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
                                  color: _primaryPurple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryPurple,
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
                      backgroundColor: _primaryPurple),
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

    final updated = TrademarkRegistrationProcessModel(
      id: process.id,
      userId: process.centerAdminUserId,
      advocateId: selectedAdvocate?.id ?? process.advocateId,
      tradeMarkId: _t.id ?? '',
      status: status,
      steps: steps,
    );

    setState(() => _isBusy = true);
    try {
      await TrademarkRegistrationProcessService.updateProcess(
        id: process.id ?? '',
        userId: _currentUserId!,
        process: updated,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trademark process updated'),
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
    final process = _t.registrationProcess;
    if (process == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Trademark Process?'),
        content: const Text(
          'This will remove your registration process for this Trademark filing. '
          'The Trademark record itself will remain.',
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
      await TrademarkRegistrationProcessService.deleteProcess(
        id: process.id ?? '',
        userId: _currentUserId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trademark process deleted'),
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

  // ============ OPEN MY TM PROCESS CONTROL ============
  Future<void> _openMyTmProcessControl() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTrademarkProcessControlScreen(),
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
                'Pick the advocate who will handle this Trademark filing',
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
                        backgroundColor: _primaryPurple.withOpacity(0.1),
                        child: const Icon(Icons.gavel,
                            color: _primaryPurple, size: 20),
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
        backgroundColor: isError ? Colors.red : _primaryPurple,
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final process = _t.registrationProcess;
    final isApproved = process != null && process.status == true;
    final isPending = process == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Trademark Details',
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
                      Icon(Icons.edit, size: 18, color: Color(0xFF6A1B9A)),
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
                  _section('Trademark Information', [
                    _row('Trademark Name', _t.trademarkName),
                    _row('Trademark Type', _t.trademarkType),
                    _row('Class of Goods', _t.classOfGoods),
                    _row('Organization', _t.organaizationalName),
                    _row('Legal Protection', _t.legalProtection),
                    _row('Nation Validity', _t.nationWiseValidity),
                    _row('Government Fee',
                        '৳ ${_t.governmentFee.toStringAsFixed(0)}'),
                  ]),
                  const SizedBox(height: 16),
                  _section('Applicant Information', [
                    _row('Applicant Type', _t.applicationType),
                    _row('Applicant Name', _t.applicationName),
                    _row('Mobile', _t.mobileNumber),
                    _row('Email', _t.email),
                    _row('Address', _t.adress),
                  ]),
                  const SizedBox(height: 16),
                  _section('Documents', [
                    if (_t.documents.isEmpty)
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
                      ..._t.documents.asMap().entries.map((e) {
                        return _docTile(
                          index: e.key + 1,
                          id: e.value,
                          onTap: () => _openDocument(e.value),
                        );
                      }),
                  ]),
                  const SizedBox(height: 16),
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
                    if (_t.id != null) _row('Application ID', _t.id!),
                  ]),

                  // ---------- CENTER ADMIN CONTROLS ----------
                  if (_isCenterAdminOfThis || !_hasProcess) ...[
                    const SizedBox(height: 16),
                    _centerAdminControls(),
                  ],

                  // ---------- Payment Section (owner OR center admin) ----------
                  if ((widget.isOwner || _isCenterAdminOfThis) &&
                      _t.id != null) ...[
                    const SizedBox(height: 16),
                    TrademarkPaymentSection(
                      trademarkId: _t.id!,
                      isOwner: widget.isOwner, // ✅ pay button owner only
                    ),
                  ],

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with Executive'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Color(0xFF6A1B9A)),
                      foregroundColor: const Color(0xFF6A1B9A),
                    ),
                  ),
                  if (widget.isOwner) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Trademark'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Color(0xFF6A1B9A)),
                        foregroundColor: const Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Trademark'),
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
        border: Border.all(color: _primaryPurple.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: _primaryPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Center Admin Controls',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _openMyTmProcessControl,
            icon: const Icon(Icons.list_alt),
            label: const Text('My Trademark Processes'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              side: const BorderSide(color: _primaryPurple),
              foregroundColor: _primaryPurple,
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
                backgroundColor: _primaryPurple,
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
                backgroundColor: _primaryPurple,
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

  // ============ Reusable widgets ============

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
              color: _primaryPurple.withOpacity(0.1),
            ),
            child: const Icon(Icons.verified,
                color: _primaryPurple, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            _t.trademarkName.isEmpty ? 'Untitled' : _t.trademarkName,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_t.trademarkType.isEmpty ? '-' : _t.trademarkType,
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
                  color: _primaryPurple)),
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
                  size: 18, color: _primaryPurple),
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