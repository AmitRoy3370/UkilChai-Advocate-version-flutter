// lib/Copyright/screens/copyright_details_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../../RJSC/screens/rjsc_attachment_viewer.dart';
import '../models/copyright_response_dto.dart';
import '../models/copyright_model.dart';
import '../models/copyright_registration_process_model.dart';
import '../services/copyright_service.dart';
import '../services/copyright_registration_process_service.dart';
import '../services/center_admin_bridge.dart';
import 'copyright_update_screen.dart';
import 'widgets/copyright_payment_section.dart';
import 'copyright_process_control_screen.dart';

class CopyrightDetailsScreen extends StatefulWidget {
  final CopyrightResponseDTO copyright;
  final bool isOwner;

  const CopyrightDetailsScreen({
    super.key,
    required this.copyright,
    required this.isOwner,
  });

  @override
  State<CopyrightDetailsScreen> createState() => _CopyrightDetailsScreenState();
}

class _CopyrightDetailsScreenState extends State<CopyrightDetailsScreen> {
  late CopyrightResponseDTO _c;
  bool _isDeleting = false;
  bool _isBusy = false;

  String _myUserId = '';
  bool _isCenterAdminOfThis = false;

  @override
  void initState() {
    super.initState();
    _c = widget.copyright;
    _resolveUser();
  }

  Future<void> _resolveUser() async {
    final id = await AuthService.getUserId() ?? '';
    if (!mounted) return;
    setState(() {
      _myUserId = id;
      _isCenterAdminOfThis = _c.registrationProcess != null &&
          _c.registrationProcess!.userId == id &&
          id.isNotEmpty;
    });
  }

  Future<void> _reload() async {
    if (_c.id == null) return;
    final res = await CopyrightService.findById(_c.id!);
    final fresh = CopyrightService.parseSingle(res);
    if (fresh != null && mounted) {
      setState(() {
        _c = fresh;
        _isCenterAdminOfThis = _c.registrationProcess != null &&
            _c.registrationProcess!.userId == _myUserId &&
            _myUserId.isNotEmpty;
      });
    }
  }

  // ---------- Delete Copyright ----------
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Copyright?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this copyright registration?',
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

    setState(() => _isDeleting = true);

    final userId = await AuthService.getUserId() ?? '';
    final res = await CopyrightService.deleteCopyright(
      id: _c.id ?? '',
      userId: userId,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copyright deleted successfully'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to delete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- Edit Copyright (owner only) ----------
  Future<void> _openEdit() async {
    final model = CopyrightModel(
      id: _c.id,
      userId: _c.userId,
      author: _c.author,
      typeOfWork: _c.typeOfWork,
      yearOfCreation: _c.yearOfCreation,
      titleOfWork: _c.titleOfWork,
      description: _c.description,
      applicationName: _c.userName,
      mobileNumber: _c.mobileNumber,
      email: _c.email,
      adress: _c.adress,
      documents: _c.documents,
    );

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CopyrightUpdateScreen(existingCopyright: model),
      ),
    );

    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // ---------- Document viewer ----------
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
            title: const Text(
              'Document Viewer',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          body: RJSCAttachmentViewer(
            attachmentId: attachmentId,
            jwtToken: token,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ADVOCATE PICKER
  // =========================================================================
  Future<AdvocateBrief?> _pickAdvocate() async {
    List<AdvocateBrief> advocates;
    try {
      advocates = await CenterAdminBridge.myAdvocates(_myUserId);
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load advocates: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    if (!mounted) return null;

    if (advocates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have no advocates connected. Please add one first.',
          ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick the advocate who will handle this copyright',
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
                        backgroundColor:
                            const Color(0xFF1A3FBF).withOpacity(0.1),
                        child: const Icon(Icons.gavel,
                            color: Color(0xFF1A3FBF), size: 20),
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

  // =========================================================================
  // CENTER ADMIN ACTIONS
  // =========================================================================

  // ---------- Accept (create registration process owned by me) ----------
  Future<void> _confirmAcceptAsCenterAdmin() async {
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
              'You will become the registration process controller for this copyright.',
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
                      size: 16, color: Color(0xFF1A3FBF)),
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
                backgroundColor: const Color(0xFF1A3FBF)),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBusy = true);

    final process = CopyrightRegistrationProcessModel(
      copyrightId: _c.id ?? '',
      userId: _myUserId,
      advocateId: advocate.id,
      stpes: const ['accepted'],
      status: false,
    );

    final res = await CopyrightRegistrationProcessService.addProcess(
      userId: _myUserId,
      process: process,
    );

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration process accepted successfully'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to accept'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- Remove the whole copyright ----------
  Future<void> _confirmRemoveNoProcess() async {
    await _confirmDelete();
  }

  // =========================================================================
  // Edit registration process — with a proper step builder
  // =========================================================================
  Future<void> _openEditRegistrationProcess() async {
    final process = _c.registrationProcess;
    if (process == null) return;

    // Working copies for the dialog
    final List<TextEditingController> stepControllers = process.stpes
        .map((s) => TextEditingController(text: s))
        .toList();
    if (stepControllers.isEmpty) {
      stepControllers.add(TextEditingController());
    }

    bool status = process.status;

    AdvocateBrief? selectedAdvocate = AdvocateBrief(
      id: process.advocateId,
      name: process.advocateName.isNotEmpty
          ? process.advocateName
          : process.advocateId,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void addStep() {
              setLocal(() {
                stepControllers.add(TextEditingController());
              });
            }

            void removeStep(int index) {
              if (stepControllers.length <= 1) return;
              setLocal(() {
                stepControllers[index].dispose();
                stepControllers.removeAt(index);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Update Registration Process'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- Advocate ----------
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
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.gavel,
                                  size: 16, color: Color(0xFF1A3FBF)),
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

                      const SizedBox(height: 16),

                      // ---------- Steps header + add button ----------
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
                              foregroundColor: const Color(0xFF1A3FBF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // ---------- Step rows ----------
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
                                  color: const Color(0xFF1A3FBF)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A3FBF),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: stepControllers[i],
                                  textInputAction:
                                      TextInputAction.next,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText:
                                        'Describe step ${i + 1}...',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12),
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

                      // ---------- Status ----------
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
                      backgroundColor: const Color(0xFF1A3FBF)),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // ---------- Persist if saved ----------
    if (saved != true) {
      for (final c in stepControllers) {
        c.dispose();
      }
      return;
    }

    // Build the ordered list of non-empty steps
    final steps = <String>[];
    for (final c in stepControllers) {
      final v = c.text.trim();
      if (v.isNotEmpty) steps.add(v);
    }

    final updated = CopyrightRegistrationProcessModel(
      id: process.id,
      copyrightId: process.copyrightId,
      userId: process.userId,
      advocateId: selectedAdvocate?.id ?? process.advocateId,
      stpes: steps,
      status: status,
    );

    setState(() => _isBusy = true);

    final res = await CopyrightRegistrationProcessService.updateProcess(
      id: process.id ?? '',
      userId: _myUserId,
      process: updated,
    );

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration process updated'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- Delete registration process ----------
  Future<void> _confirmDeleteRegistrationProcess() async {
    final process = _c.registrationProcess;
    if (process == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Registration Process?'),
        content: const Text(
          'This will remove your registration process for this copyright. '
          'The copyright record itself will remain.',
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

    final res = await CopyrightRegistrationProcessService.deleteProcess(
      id: process.id ?? '',
      userId: _myUserId,
    );

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration process deleted'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to delete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- Open "My Copyright Processes" ----------
  Future<void> _openMyProcessControlScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CopyrightProcessControlScreen(),
      ),
    );
    if (mounted) await _reload();
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final process = _c.registrationProcess;
    final isApproved = process != null && process.status == true;
    final hasProcess = process != null;
    final isPending = !hasProcess;

    final showOwnerActions = widget.isOwner;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Copyright Details',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          if (showOwnerActions)
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
                      Icon(Icons.edit, size: 18, color: Color(0xFF1A3FBF)),
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
      body: _isDeleting || _isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(isApproved, isPending),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Work Information',
                    children: [
                      _infoRow('Author / Creator', _c.author),
                      _infoRow('Type of Work', _c.typeOfWork),
                      _infoRow('Year of Creation',
                          _c.yearOfCreation.year.toString()),
                      _infoRow('Description', _c.description),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Applicant Information',
                    children: [
                      _infoRow('Name', _c.userName),
                      _infoRow('Mobile', _c.mobileNumber),
                      _infoRow('Email', _c.email),
                      _infoRow('Address', _c.adress),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Documents',
                    children: [
                      if (_c.documents.isEmpty)
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
                        ..._c.documents.asMap().entries.map((e) {
                          return _documentTile(
                            index: e.key + 1,
                            attachmentId: e.value,
                            onTap: () => _openDocument(e.value),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Application Status',
                    children: [
                      if (isPending)
                        _infoRow('Status', 'Pending Review')
                      else if (process != null) ...[
                        _infoRow(
                            'Status',
                            process.status == true
                                ? 'Approved'
                                : 'Processing'),
                        if (process.advocateName.isNotEmpty)
                          _infoRow(
                              'Assigned Advocate', process.advocateName),
                        if (process.stpes.isNotEmpty)
                          _infoRow('Progress', process.stpes.join(' → ')),
                        if (process.userName.isNotEmpty)
                          _infoRow('Controller', process.userName),
                      ],
                      if (_c.id != null) _infoRow('Application ID', _c.id!),
                    ],
                  ),

                  // =========================================================
                  // ✅ NEW: Progress Timeline (shows all steps)
                  // =========================================================
                  if (hasProcess && process.stpes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _section(
                      title: 'Progress Timeline',
                      children: [
                        _timeline(
                          steps: process.stpes,
                          isApproved: isApproved,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  if (_c.id != null &&
                      (widget.isOwner || _isCenterAdminOfThis))
                    CopyrightPaymentSection(
                      copyrightId: _c.id!,
                      isOwner: widget.isOwner,
                    ),
                  const SizedBox(height: 16),
                  if (_isCenterAdminOfThis || !hasProcess)
                    _centerAdminSection(hasProcess),
                  const SizedBox(height: 30),
                  if (widget.isOwner) ...[
                    OutlinedButton.icon(
                      onPressed: _openEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Copyright'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Color(0xFF1A3FBF)),
                        foregroundColor: const Color(0xFF1A3FBF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Copyright'),
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

  // =========================================================================
  // ✅ NEW: TIMELINE WIDGET
  // =========================================================================
  //
  // Renders a vertical timeline of steps:
  //   ●  Step 1: accepted
  //   │
  //   ●  Step 2: in-review
  //   │
  //   ●  Step 3: submitted
  //
  // Color rules:
  //   - If process.status == true → all nodes green + check icon
  //   - Otherwise → all nodes blue; last node is the "current" (larger
  //     ring), rest are "visited" (filled)
  //   - Any step whose text contains "completed"/"approved"/"done"
  //     is rendered green regardless of the overall status.
  Widget _timeline({
    required List<String> steps,
    required bool isApproved,
  }) {
    const green = Color(0xFF2E7D32);
    const blue = Color(0xFF1A3FBF);
    const greyLine = Color(0xFFE0E0E0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isLast = i == steps.length - 1;
        final text = steps[i];

        final lower = text.toLowerCase();
        final markedDone = lower.contains('complete') ||
            lower.contains('approve') ||
            lower.contains('done') ||
            lower.contains('finished');

        final bool done = isApproved || markedDone;
        final bool current = !isApproved && isLast && !markedDone;

        final Color nodeColor = done ? green : blue;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- Node column (dot + connector) --------
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    // Node
                    Container(
                      width: current ? 26 : 22,
                      height: current ? 26 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? nodeColor
                            : (current
                                ? Colors.white
                                : nodeColor.withOpacity(0.15)),
                        border: Border.all(
                          color: nodeColor,
                          width: current ? 3 : 2,
                        ),
                        boxShadow: current
                            ? [
                                BoxShadow(
                                  color: nodeColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(Icons.check,
                              size: 13, color: Colors.white)
                          : (current
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: nodeColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: nodeColor,
                                  ),
                                )),
                    ),
                    // Connector
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: done ? green.withOpacity(0.5) : greyLine,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // -------- Text column --------
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 18,
                    top: 1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Step ${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: done ? green : blue,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (current) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: blue,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                          if (done && isApproved && isLast) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DONE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: green,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        text.isEmpty ? '—' : text,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight:
                              current ? FontWeight.w600 : FontWeight.w500,
                          color: done ? Colors.black87 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // =========================================================================
  // CENTER ADMIN SECTION
  // =========================================================================
  Widget _centerAdminSection(bool hasProcess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A3FBF).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: Color(0xFF1A3FBF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Center Admin Controls',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3FBF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openMyProcessControlScreen,
            icon: const Icon(Icons.list_alt),
            label: const Text('My Copyright Processes'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              side: const BorderSide(color: Color(0xFF1A3FBF)),
              foregroundColor: const Color(0xFF1A3FBF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!hasProcess) ...[
            ElevatedButton.icon(
              onPressed: _confirmAcceptAsCenterAdmin,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept Registration Process'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3FBF),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _confirmRemoveNoProcess,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Remove Registration'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ] else if (_isCenterAdminOfThis) ...[
            ElevatedButton.icon(
              onPressed: _openEditRegistrationProcess,
              icon: const Icon(Icons.edit_note),
              label: const Text('Update Registration Process'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3FBF),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _confirmDeleteRegistrationProcess,
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

  // =========================================================================
  // WIDGETS
  // =========================================================================

  Widget _headerCard(bool isApproved, bool isPending) {
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
              color: const Color(0xFF1A3FBF).withOpacity(0.1),
            ),
            child: const Icon(Icons.copyright,
                color: Color(0xFF1A3FBF), size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            _c.titleOfWork.isEmpty ? 'Untitled' : _c.titleOfWork,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _c.typeOfWork.isEmpty ? '-' : _c.typeOfWork,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _statusChip(isApproved, isPending),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3FBF),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTile({
    required int index,
    required String attachmentId,
    required VoidCallback onTap,
  }) {
    final lower = attachmentId.toLowerCase();
    final isPdf = lower.contains('pdf') || lower.endsWith('.pdf');
    final isImage = lower.contains('jpg') ||
        lower.contains('jpeg') ||
        lower.contains('png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.png');

    IconData icon = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    Color bgColor = Colors.grey.shade50;

    if (isPdf) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red;
      bgColor = Colors.red.shade50;
    } else if (isImage) {
      icon = Icons.image;
      iconColor = Colors.blue;
      bgColor = Colors.blue.shade50;
    }

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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document $index',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.visibility_outlined,
                  size: 18, color: Color(0xFF1A3FBF)),
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}