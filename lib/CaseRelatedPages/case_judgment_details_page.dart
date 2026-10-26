// lib/CaseRelatedPages/case_judgment_details_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/responsive_helper.dart';
import 'CaseJudgmentModel.dart';
import 'case_judgment_service.dart';
import 'CaseJudgmentAttachmentViewer.dart';

class CaseJudgmentDetailsPage extends StatefulWidget {
  final CaseJudgmentResponse judgment;
  final String token;

  /// Advocate userId used for add/update/delete `?userId=`. Falls back to
  /// SharedPreferences value when null.
  final String? advocateUserId;

  /// Optional override. If null, derived from `judgment.judgementCase?.advocateId`.
  final String? advocateId;

  const CaseJudgmentDetailsPage({
    super.key,
    required this.judgment,
    required this.token,
    this.advocateUserId,
    this.advocateId,
  });

  @override
  State<CaseJudgmentDetailsPage> createState() =>
      _CaseJudgmentDetailsPageState();
}

class _CaseJudgmentDetailsPageState extends State<CaseJudgmentDetailsPage> {
  late CaseJudgmentResponse _judgment;

  bool _isAdvocate = false;
  bool _isUploading = false;

  PlatformFile? _newFile;

  @override
  void initState() {
    super.initState();
    _judgment = widget.judgment;
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final myAdvocateId = prefs.getString('advocateId');

    final judgmentAdvocateId =
        widget.advocateId ?? _judgment.judgementCase?.advocateId;



    if (!mounted) return;
    setState(() {
      _isAdvocate = myAdvocateId != null &&
          judgmentAdvocateId != null &&
          myAdvocateId == judgmentAdvocateId;
    });
  }

  // ---------- Date formatting ----------
  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)} ${_monthShort(d.month)} ${d.year}";
  }

  String _monthShort(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  Future<String?> _resolveUserId() async {
    if (widget.advocateUserId != null) return widget.advocateUserId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // ---------- Edit dialog ----------
  Future<void> _openEditDialog() async {
    final resultController =
        TextEditingController(text: _judgment.result);
    DateTime selectedDate = _judgment.date;
    _newFile = null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Case Judgment"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Result field
                  TextField(
                    controller: resultController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Judgment Result",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Date: ${_formatDate(selectedDate)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text("Pick"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setDialogState(
                                () => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Existing attachment
                  if (_judgment.judgmentAttachmentId != null) ...[
                    const Text(
                      "Existing attachment:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.attach_file,
                        color: Colors.blue,
                      ),
                      title: Text(
                        _judgment.judgmentAttachmentId!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // New file
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _newFile == null
                          ? (_judgment.judgmentAttachmentId == null
                              ? "Attach file (optional)"
                              : "Replace attachment")
                          : _newFile!.name,
                    ),
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                      );
                      if (res != null && res.files.isNotEmpty) {
                        setDialogState(() => _newFile = res.files.first);
                      }
                    },
                  ),
                  if (_newFile != null)
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text("Clear selection"),
                      onPressed: () =>
                          setDialogState(() => _newFile = null),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUploading ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (resultController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Judgment result cannot be empty"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => _isUploading = true);
                        try {
                          final userId = await _resolveUserId();
                          if (userId == null) {
                            throw Exception("User ID not found");
                          }

                          await CaseJudgmentService.updateJudgment(
                            judgmentId: _judgment.id,
                            caseId: _judgment.caseId,
                            result: resultController.text.trim(),
                            userId: userId,
                            oldAttachmentId:
                                _judgment.judgmentAttachmentId,
                            file: _newFile,
                            date: selectedDate,
                          );

                          final updated = await CaseJudgmentService.getById(
                            _judgment.id,
                          );

                          if (mounted) {
                            setState(() => _judgment = updated);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "✓ Case judgment updated successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✗ Error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setDialogState(() => _isUploading = false);
                          }
                        }
                      },
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Delete ----------
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Case Judgment"),
        content: const Text(
          "Are you sure you want to delete this judgment?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final ok = await CaseJudgmentService.remove(_judgment.id);
      if (!ok) throw Exception("Backend rejected delete");

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Case judgment deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✗ Delete failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.padding(context, 12);
    final titleSize = ResponsiveHelper.fontSize(context, 20);
    final labelSize = ResponsiveHelper.fontSize(context, 14);
    final valueSize = ResponsiveHelper.fontSize(context, 15);

    final jCase = _judgment.judgementCase;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Judgment Details"),
        backgroundColor: Colors.green,
        actions: [
          if (_isAdvocate)
            IconButton(
              tooltip: "Edit judgment",
              icon: const Icon(Icons.edit),
              onPressed: _openEditDialog,
            ),
          if (_isAdvocate)
            IconButton(
              tooltip: "Delete judgment",
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Judgment summary ----------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel,
                            color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Case Judgment",
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),

                    const Text(
                      "Result:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _judgment.result,
                        style: TextStyle(fontSize: valueSize),
                      ),
                    ),

                    SizedBox(height: spacing),
                    _row("Issued Date",
                        _formatDate(_judgment.date), labelSize, valueSize),
                    SizedBox(height: 6),
                    _row("Judgment ID", _judgment.id, labelSize, valueSize),
                    SizedBox(height: 6),
                    _row("Case ID", _judgment.caseId, labelSize, valueSize),

                    if (jCase != null) ...[
                      SizedBox(height: 6),
                      _row("Case Name", jCase.caseName, labelSize,
                          valueSize),
                      SizedBox(height: 6),
                      _row("Case Type", jCase.caseType, labelSize,
                          valueSize),
                      SizedBox(height: 6),
                      _row("Advocate",
                          jCase.displayAdvocateName, labelSize, valueSize),
                      SizedBox(height: 6),
                      _row("Client", jCase.displayUserName, labelSize,
                          valueSize),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: spacing * 1.5),

            // ---------- Attachment ----------
            Text(
              "Attachment",
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),

            if (_judgment.judgmentAttachmentId == null ||
                _judgment.judgmentAttachmentId!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No attachment",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.blue,
                  ),
                  title: Text(
                    _judgment.judgmentAttachmentId!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseJudgmentAttachmentView(
                          attachmentId: _judgment.judgmentAttachmentId!,
                          jwtToken: widget.token,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    double labelSize,
    double valueSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: valueSize)),
        ),
      ],
    );
  }
}