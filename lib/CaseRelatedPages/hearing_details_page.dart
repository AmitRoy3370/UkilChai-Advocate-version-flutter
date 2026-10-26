// lib/CaseRelatedPages/hearing_details_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/responsive_helper.dart';
import 'HearingModel.dart';
import 'HearingAttachmentViewer.dart';
import 'hearing_service.dart';

class HearingDetailsPage extends StatefulWidget {
  final HearingResponse hearing;
  final String token;
  final String advocateUserId; // userId of the advocate (used for add/update API)
  final String advocateId;     // advocateId (used to check ownership)

  const HearingDetailsPage({
    super.key,
    required this.hearing,
    required this.token,
    required this.advocateUserId,
    required this.advocateId,
  });

  @override
  State<HearingDetailsPage> createState() => _HearingDetailsPageState();
}

class _HearingDetailsPageState extends State<HearingDetailsPage> {
  late HearingResponse _hearing;
  bool _isAdvocate = false;
  bool _isUploading = false;

  // Edit-mode file state
  List<PlatformFile> _newFiles = [];
  List<String> _existingAttachments = [];
  Set<String> _attachmentsToDelete = {};

  @override
  void initState() {
    super.initState();
    _hearing = widget.hearing;
    _existingAttachments = List.from(_hearing.attachmentsId);
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final myAdvocateId = prefs.getString('advocateId');
    if (!mounted) return;
    setState(() {
      _isAdvocate =
          myAdvocateId != null && myAdvocateId == widget.advocateId;
    });
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${d.day.toString().padLeft(2, '0')} "
        "${_monthShort(d.month)} ${d.year}, "
        "${two(d.hour)}:${two(d.minute)}";
  }

  String _monthShort(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  // ============================================================
  // EDIT DIALOG
  // ============================================================
  Future<void> _openEditDialog() async {
    _newFiles = [];
    _existingAttachments = List.from(_hearing.attachmentsId);
    _attachmentsToDelete = {};

    DateTime selectedDate = _hearing.issuedDate;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Edit Hearing #${_hearing.hearingNumber}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----- Date picker -----
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
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedDate.hour,
                                selectedDate.minute,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ----- Existing files -----
                  if (_existingAttachments.isNotEmpty) ...[
                    const Text(
                      "Existing attachments:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._existingAttachments.map((attId) {
                      final willDelete = _attachmentsToDelete.contains(attId);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          willDelete
                              ? Icons.delete_forever
                              : Icons.attach_file,
                          color: willDelete ? Colors.red : Colors.blue,
                        ),
                        title: Text(
                          attId,
                          style: TextStyle(
                            decoration: willDelete
                                ? TextDecoration.lineThrough
                                : null,
                            color: willDelete ? Colors.red : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            willDelete ? Icons.restore : Icons.delete_outline,
                            color: willDelete ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              if (willDelete) {
                                _attachmentsToDelete.remove(attId);
                              } else {
                                _attachmentsToDelete.add(attId);
                              }
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // ----- New files -----
                  if (_newFiles.isNotEmpty) ...[
                    const Text(
                      "New attachments:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._newFiles.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final f = entry.value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                        ),
                        title: Text(f.name),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setDialogState(() => _newFiles.removeAt(idx));
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Add new files"),
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                      );
                      if (res != null && res.files.isNotEmpty) {
                        setDialogState(() {
                          _newFiles.addAll(
                            res.files.where((f) => f.bytes != null),
                          );
                        });
                      }
                    },
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
                        setDialogState(() => _isUploading = true);
                        try {
                          final filteredExisting = _existingAttachments
                              .where((id) => !_attachmentsToDelete.contains(id))
                              .toList();

                          final response =
                              await HearingService.updateHearing(
                            token: widget.token,
                            hearingId: _hearing.id,
                            userId: widget.advocateUserId,
                            caseId: _hearing.caseId,
                            hearingNumber: _hearing.hearingNumber,
                            issuedDate: selectedDate,
                            existingFiles: filteredExisting,
                            files: _newFiles,
                          );

                          if (response.statusCode == 200 ||
                              response.statusCode == 201) {
                            // Re-fetch the updated hearing
                            final updated = await HearingService.getById(
                              widget.token,
                              _hearing.id,
                            );

                            if (mounted) {
                              setState(() {
                                _hearing = updated;
                                _existingAttachments =
                                    List.from(_hearing.attachmentsId);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "✓ Hearing updated successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            throw Exception(
                                "Failed: ${response.statusCode} ${response.body}");
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

  // ============================================================
  // DELETE
  // ============================================================
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Hearing"),
        content: Text(
          "Are you sure you want to delete hearing #${_hearing.hearingNumber}?",
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
      final deleted = await HearingService.removeHearing(
        widget.token,
        _hearing.id,
        widget.advocateUserId,
      );

      if (!deleted) {
        throw Exception("Backend rejected delete");
      }

      if (mounted) {
        Navigator.pop(context, true); // return `true` → parent refreshes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Hearing deleted"),
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

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.padding(context, 12);
    final titleSize = ResponsiveHelper.fontSize(context, 20);
    final labelSize = ResponsiveHelper.fontSize(context, 14);
    final valueSize = ResponsiveHelper.fontSize(context, 15);

    return Scaffold(
      appBar: AppBar(
        title: Text("Hearing #${_hearing.hearingNumber}"),
        backgroundColor: Colors.green,
        actions: [
          if (_isAdvocate)
            IconButton(
              tooltip: "Edit hearing",
              icon: const Icon(Icons.edit),
              onPressed: _openEditDialog,
            ),
          if (_isAdvocate)
            IconButton(
              tooltip: "Delete hearing",
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
            // ---------- Hearing Card ----------
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
                        const Icon(Icons.gavel, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Hearing #${_hearing.hearingNumber}",
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    _row("Issued Date",
                        _formatDate(_hearing.issuedDate), labelSize, valueSize),
                    SizedBox(height: 6),
                    _row("Case ID", _hearing.caseId, labelSize, valueSize),
                    if (_hearing.hearingCase != null) ...[
                      SizedBox(height: 6),
                      _row(
                        "Case Name",
                        _hearing.hearingCase!.caseName,
                        labelSize,
                        valueSize,
                      ),
                      SizedBox(height: 6),
                      _row(
                        "Case Type",
                        _hearing.hearingCase!.caseType,
                        labelSize,
                        valueSize,
                      ),
                      SizedBox(height: 6),
                      _row(
                        "Advocate",
                        _hearing.hearingCase!.displayAdvocateName,
                        labelSize,
                        valueSize,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: spacing * 1.5),

            // ---------- Attachments ----------
            Text(
              "Attachments (${_hearing.attachmentsId.length})",
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),

            if (_hearing.attachmentsId.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No attachments",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            ..._hearing.attachmentsId.map(
              (attId) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.blue,
                  ),
                  title: Text(attId, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HearingAttachmentView(
                          attachmentId: attId,
                          jwtToken: widget.token,
                        ),
                      ),
                    );
                  },
                ),
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
          width: 110,
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
          child: Text(
            value,
            style: TextStyle(fontSize: valueSize),
          ),
        ),
      ],
    );
  }
}