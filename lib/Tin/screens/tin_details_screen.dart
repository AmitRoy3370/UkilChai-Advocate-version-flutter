// lib/Tin/screens/tin_details_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../../RJSC/screens/rjsc_attachment_viewer.dart';

import '../models/tin_response_dto.dart';
import '../models/tin_registration_process_model.dart';
import '../services/tin_service.dart';
import '../services/center_admin_bridge.dart';
import '../services/tin_registration_process_service.dart';
import 'tin_update_screen.dart';
import 'my_tin_process_control_screen.dart';

class TinDetailsScreen extends StatefulWidget {
  final TinResponseDTO tin;
  final bool isOwner;

  const TinDetailsScreen({
    super.key,
    required this.tin,
    required this.isOwner,
  });

  @override
  State<TinDetailsScreen> createState() => _TinDetailsScreenState();
}

class _TinDetailsScreenState extends State<TinDetailsScreen> {
  static const Color _primaryGreen = Color(0xFF1E7A3A);

  late TinResponseDTO _t;
  bool _isDeleting = false;
  bool _isBusy = false;
  String? _currentUserId;
  String? _currentUserName;

  /// Cached CenterAdmin._id for this user (the id the backend expects
  /// as `centerAdminId` in `TinRegistrationProcess`).
  String? _currentCenterAdminId;

  /// ✅ True when current user is the Center Admin of THIS TIN's process
  bool get _isCenterAdminOfThis {
    final rp = _t.registrationProcess;
    return rp != null &&
        _currentCenterAdminId != null &&
        _currentCenterAdminId!.isNotEmpty &&
        rp.centerAdminId == _currentCenterAdminId;
  }

  bool get _hasProcess => _t.registrationProcess != null;

  @override
  void initState() {
    super.initState();
    _t = widget.tin;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await AuthService.getUserId();
    if (!mounted) return;

    setState(() {
      _currentUserId = userId;
      _currentUserName = '';
    });

    // ✅ Prefetch the CenterAdmin document id for this user.
    if (userId != null && userId.isNotEmpty) {
      try {
        final adminId = await CenterAdminBridge.myCenterAdminId(userId);
        if (!mounted) return;
        setState(() => _currentCenterAdminId = adminId);
        debugPrint('🟩 [TinDetails] myCenterAdminId = $adminId');
      } catch (e) {
        debugPrint('⚠️ [TinDetails] could not resolve center admin id: $e');
      }
    }
  }

  Future<void> _reload() async {
    if (_t.id == null) return;
    try {
      final res = await TinService.findById(_t.id!);
      final fresh = TinService.parseSingle(res);
      if (fresh != null && mounted) setState(() => _t = fresh);
    } catch (_) {}
  }

  // ============ DELETE (whole TIN) ============
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete TIN?'),
        content: const Text(
            'This action cannot be undone. Are you sure you want to delete this TIN registration?'),
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
    final res = await TinService.deleteTin(id: _t.id ?? '', userId: userId);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TIN deleted successfully'),
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

  // ============ EDIT TIN ============
  Future<void> _openEdit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TinUpdateScreen(tin: _t),
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
              'You will become the registration process controller for this TIN filing.',
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
      // ✅ Resolve the CenterAdmin._id (the backend expects this, not userId)
      String centerAdminId = _currentCenterAdminId ?? '';
      if (centerAdminId.isEmpty) {
        centerAdminId =
            await CenterAdminBridge.myCenterAdminId(_currentUserId!);
        if (mounted) _currentCenterAdminId = centerAdminId;
      }

      debugPrint('🟦 [Accept TIN] centerAdminId=$centerAdminId '
          'userId=$_currentUserId advocateId=${advocate.id} '
          'tinId=${_t.id}');

      final process = TinRegistrationProcessModel(
        centerAdminId: centerAdminId, // ✅ CenterAdmin._id
        advocateId: advocate.id,
        tinId: _t.id ?? '',
        steps: const ['accepted'],
      );

      final res = await TinRegistrationProcessService.addProcess(
        userId: _currentUserId!,
        process: process,
      );

      debugPrint('🟦 [Accept TIN] response = $res');

      if (res['status'] != 'success') {
        throw Exception(
            res['message']?.toString() ?? 'Failed to accept process');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('TIN registration process accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Small delay to let the backend cache/Mongo settle
      await Future.delayed(const Duration(milliseconds: 300));
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
              title: const Text('Update TIN Process'),
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

    // ✅ Keep the existing centerAdminId (already the CenterAdmin._id)
    final updated = TinRegistrationProcessModel(
      id: process.id,
      centerAdminId: process.centerAdminId,
      advocateId: selectedAdvocate?.id ?? process.advocateId,
      tinId: _t.id ?? '',
      steps: steps,
    );

    setState(() => _isBusy = true);
    try {
      final res = await TinRegistrationProcessService.updateProcess(
        id: process.id ?? '',
        userId: _currentUserId!,
        process: updated,
      );

      debugPrint('🟦 [Update TIN] response = $res');

      if (res['status'] != 'success') {
        throw Exception(
            res['message']?.toString() ?? 'Failed to update process');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TIN process updated'),
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
        title: const Text('Delete TIN Process?'),
        content: const Text(
          'This will remove your registration process for this TIN filing. '
          'The TIN record itself will remain.',
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
      final res = await TinRegistrationProcessService.deleteProcess(
        id: process.id ?? '',
        userId: _currentUserId!,
      );

      debugPrint('🟦 [Delete TIN Process] response = $res');

      if (res['status'] != 'success') {
        throw Exception(
            res['message']?.toString() ?? 'Failed to delete process');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TIN process deleted'),
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

  // ============ OPEN MY TIN PROCESS CONTROL ============
  Future<void> _openMyTinProcessControl() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTinProcessControlScreen(),
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
                'Pick the advocate who will handle this TIN filing',
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
    final process = _t.registrationProcess;
    final steps = process?.steps ?? [];
    final isApproved =
        steps.isNotEmpty && steps.last.toLowerCase().contains('approved');
    final isPending = process == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('TIN Details',
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
                  _section('Personal Information', [
                    _row('Full Name', _t.fullName),
                    _row('Father Name', _t.fatherName),
                    _row('Mother Name', _t.motherName),
                    _row('Date of Birth', _formatDate(_t.dateOfBirth)),
                    _row('Mobile Number', _t.phone),
                  ]),
                  const SizedBox(height: 16),
                  _section('Address Information', [
                    _row('Present Address', _t.presentAdress),
                    _row('Permanent Address', _t.permanentAdress),
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
                      _row('Status', isApproved ? 'Approved' : 'Processing'),
                      if (process.centerAdminName.isNotEmpty)
                        _row('Center Admin', process.centerAdminName),
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

                  const SizedBox(height: 20),
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
                  if (widget.isOwner) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit TIN'),
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
                      label: const Text('Delete TIN'),
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
              const Text(
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

          OutlinedButton.icon(
            onPressed: _openMyTinProcessControl,
            icon: const Icon(Icons.list_alt),
            label: const Text('My TIN Processes'),
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

  // ============ Reusable widgets ============

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
            child: const Icon(Icons.badge_outlined,
                color: _primaryGreen, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            _t.fullName.isEmpty ? 'Untitled' : _t.fullName,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_t.phone.isEmpty ? '-' : _t.phone,
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
                  color: _primaryGreen)),
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
                  size: 18, color: _primaryGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool isApproved, bool isPending) {
    final color = isApproved
        ? const Color(0xFF2E7D32)
        : (isPending ? const Color(0xFFE65100) : const Color(0xFF1A3FBF));
    final label = isApproved
        ? 'Approved'
        : (isPending ? 'Pending Review' : 'Processing');
    final icon = isApproved
        ? Icons.check_circle
        : (isPending ? Icons.hourglass_empty : Icons.sync);

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