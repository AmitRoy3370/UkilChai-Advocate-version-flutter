import 'dart:convert';

import 'package:advocatechaiadvocate/CaseRelatedPages/CaseJudgmentAttachmentViewer.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ChatRelatedPages/chat_screen.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'case_close_service.dart';
import 'case_judgment_service.dart';
import 'CaseJudgmentModel.dart';

import 'package:advocatechaiadvocate/CaseRelatedPages/CaseCloseModel.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/document_draft_service.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/_TimelineStep.dart';
import 'CaseJudgmentModel.dart';
import 'ScheduleAppealHearingPage.dart';
import 'case_judgment_service.dart';
import 'package:file_picker/file_picker.dart';

import 'AppealHearingModel.dart';
import 'DocumentDraftAttachmentViewer.dart';
import 'HearingAttachmentViewer.dart';
import 'HearingModel.dart';
import 'appeal_hearing_service.dart';
import 'document_draft.dart';
import 'hearing_service.dart';

class CaseTracking extends StatefulWidget {
  final String? caseId;
  final String? caseName;
  final String? caseLawyer;
  final String? issuedTime;
  final String? token;
  final String? userId;
  final String? advocateUserId;
  final String? userName;
  final String? advocateId;

  const CaseTracking({
    super.key,
    required this.caseId,
    required this.caseName,
    required this.caseLawyer,
    required this.issuedTime,
    required this.token,
    this.userId,
    this.advocateUserId,
    this.userName,
    this.advocateId,
  });

  @override
  State<CaseTracking> createState() => _CaseTrackingState();
}

class _CaseTrackingState extends State<CaseTracking> {
  late Future<void> _loadFuture;
  DocumentDraft? documentDrafts;
  CaseJudgment? caseJudgment;
  CaseClose? caseClose;
  List<TimelineStep> timelineSteps = [];
  List<Hearing> hearings = [];
  bool? isClosed;
  bool hasDraft = false;
  int selectedStars = 0;
  String? ratingId;
  bool ratingLoaded = false;
  String? presentUsersAdvocateId;

  // Add near other state variables
  bool _isUploadingDraft = false;
  List<PlatformFile> _selectedDocumentsDraftsNewFiles = [];
  List<String> _documentDraftsExistingAttachments = []; // for update mode
  Set<String> _documentDraftsAttachmentsToDelete =
  {}; // user wants to remove these

  // ====================== HEARING STATES ======================
  bool _isUploadingHearing = false;
  List<PlatformFile> _selectedHearingNewFiles = [];
  List<String> _hearingExistingAttachments = [];
  Set<String> _hearingAttachmentsToDelete = {};

  // ====================== PRICE STATES ======================
  bool _isSavingPrice = false;

  TextEditingController _priceController = TextEditingController();

  // ====================== HEARING PRICE RULE STATE ======================
  int _hearingPriceCount = 0;

  // ====================== JUDGMENT STATES ======================
  PlatformFile? _selectedJudgmentFile;
  bool _isUploadingJudgment = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadAllData();
  }

  Future<bool> isMyCase() async {
    final prefs = await SharedPreferences.getInstance();
    final myUserId = prefs.getString('userId');
    return myUserId != null && myUserId == widget.userId;
  }

  Future<void> _loadAllData() async {
    final draftService = DocumentDraftService(widget.token!);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    presentUsersAdvocateId = prefs.getString("advocateId");

    print("present users advocate id :- $presentUsersAdvocateId");

    try {
      await _loadMyRating();
    } catch (e) {}

    try {
      // ---------- DOCUMENT DRAFT ----------
      documentDrafts = await draftService.findByCase(widget.caseId!);

      print(
        "${documentDrafts?.caseId} ${documentDrafts?.advocateId} ${documentDrafts?.issuedDate} of case tracking page",
      );

      hasDraft = documentDrafts != null;
    } catch (e) {
      print(e);
    }

    try {
      print("collecting all hearings....");

      try {
        // ---------- HEARINGS ----------
        hearings = await HearingService.getByCase(
          widget.token!,
          widget.caseId!,
        );
      } catch (e) {}

      print("collecting all hearing price count....");

      _hearingPriceCount = await PaymentService.getHearingPaymentCount(
        widget.token!,
        widget.caseId!,
      );

      print(
        "collected total price set for hearing is :- $_hearingPriceCount and total hearing has :- ${hearings.length}",
      );
    } catch (e) {
      _hearingPriceCount = 0;
      print(
        "find some $e for collecting total hearing count and setted hearing price count",
      );
    }

    try {
      caseClose = await CaseCloseService.findByCaseId(
        widget.token!,
        widget.caseId!,
      );

      isClosed = caseClose != null && caseClose?.open == false;
    } catch (e) {}

    final documentDraftPrice = await PaymentService.getCasePaymentPrice(
      widget.token!,
      widget.caseId!,
      "CASE_DOCUMENT_DRAFT_PAYMENT",
    );

    final hearingPrice = await PaymentService.getCasePaymentPrice(
      widget.token!,
      widget.caseId!,
      "CASE_HEARING_PAYMENT",
    );

    final filingPrice = await PaymentService.getCasePaymentPrice(
      widget.token!,
      widget.caseId!,
      "CASE_FILING_PAYMENT",
    );

    final paperFinalizePrice = await PaymentService.getCasePaymentPrice(
      widget.token!,
      widget.caseId!,
      "PAPER_FINALIZE_PAYMENT",
    );

    final closingPrice = await PaymentService.getCasePaymentPrice(
      widget.token!,
      widget.caseId!,
      "CASE_CLOSING_PAYMENT",
    );

    timelineSteps = [
      TimelineStep(
        title: "Document Drafting",
        subtitle: hasDraft ? "Status: In Progress" : "Status: Pending",
        date: hasDraft ? _formatDate(documentDrafts!.issuedDate) : "",
        icon: Icons.description,
        color: hasDraft ? Colors.orange : Colors.grey,
        completed: hasDraft,
        price: documentDraftPrice,
      ),

      TimelineStep(
        title: "Hearing Date Issued",
        subtitle: hearings.isNotEmpty ? "Scheduled" : "Pending",
        date: hearings.isNotEmpty ? _formatDate(hearings.first.issuedDate) : "",
        icon: Icons.calendar_today,
        color: hearings.isNotEmpty ? Colors.blue : Colors.grey,
        completed: hearings.isNotEmpty,
        price: hearingPrice,
      ),

      TimelineStep(
        title: "Case Filing / Registration",
        subtitle: "In progress",
        date: hearings.isNotEmpty ? _formatDate(hearings.first.issuedDate) : "",
        icon: Icons.calendar_today,
        color: Colors.blue,
        completed: hearings.isNotEmpty,
        price: filingPrice,
      ),

      TimelineStep(
        title: "Paper Finalize",
        subtitle: "Pending",
        date: hearings.isNotEmpty ? _formatDate(hearings.first.issuedDate) : "",
        icon: Icons.emoji_events,
        color: Colors.grey,
        completed: hearings.isNotEmpty ? true : false,
        price: paperFinalizePrice,
      ),

      TimelineStep(
        title: "Case Close",
        subtitle: caseClose == null
            ? "Pending"
            : caseClose?.open == true
            ? "In Progress"
            : "Closed",
        date: "",
        icon: Icons.stop,
        color: Colors.grey,
        completed: caseClose != null && caseClose?.open == false,
        price: closingPrice,
      ),
    ];

    print("collecting the case judgment.....");

    try {
      final judgmentRes = await CaseJudgmentService.getByCase(widget.caseId!);

      print(
        "judgment response in load all data of case tracking :- $judgmentRes}",
      );

      if (judgmentRes != null) {
        caseJudgment = judgmentRes;

        print(
          "${caseJudgment?.caseId} ${caseJudgment?.result} ${caseJudgment?.date} of case judgment page",
        );
      }
    } catch (e) {
      print("error in loading case judgment :- $e");
    }
  }

  Future<T> _showLoadingDialog<T>({
    required Future<T> Function() task,
    String loadingMessage = "Processing...",
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loadingMessage),
            ],
          ),
        );
      },
    );

    try {
      final result = await task();
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      return result;
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _pickDocumentDraftsFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedDocumentsDraftsNewFiles.addAll(
            result.files.where((f) => f.bytes != null),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking files: $e")));
    }
  }

  void _showDocumentDraftBottomSheet() {
    final draftService = DocumentDraftService(widget.token!);
    final isUpdate = documentDrafts != null;

    // For update mode — initialize existing files
    if (isUpdate && _documentDraftsExistingAttachments.isEmpty) {
      _documentDraftsExistingAttachments = List.from(
        documentDrafts!.attachmentsId,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUpdate
                            ? "Update Document Draft"
                            : "Add Document Draft",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Selected / Existing files list
                      if (_documentDraftsExistingAttachments.isNotEmpty ||
                          _selectedDocumentsDraftsNewFiles.isNotEmpty)
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              // Existing files (only in update mode)
                              ..._documentDraftsExistingAttachments.map((
                                  attId,
                                  ) {
                                final willDelete =
                                _documentDraftsAttachmentsToDelete.contains(
                                  attId,
                                );
                                return ListTile(
                                  leading: Icon(
                                    willDelete
                                        ? Icons.delete_forever
                                        : Icons.attach_file,
                                    color: willDelete
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
                                  title: Text(
                                    "File $attId",
                                    style: TextStyle(
                                      decoration: willDelete
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: willDelete ? Colors.red : null,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      willDelete
                                          ? Icons.restore
                                          : Icons.delete_outline,
                                      color: willDelete
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        if (willDelete) {
                                          _documentDraftsExistingAttachments
                                              .remove(attId);
                                        } else {
                                          //_documentDraftsExistingAttachments.remove(attId);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),

                              // Newly selected files
                              ..._selectedDocumentsDraftsNewFiles
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                int idx = entry.key;
                                PlatformFile file = entry.value;
                                return ListTile(
                                  leading: const Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                  ),
                                  title: Text(file.name),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        _selectedDocumentsDraftsNewFiles
                                            .removeAt(idx);
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.attach_file),
                              label: const Text("Add Files"),
                              onPressed: () async {
                                await _pickDocumentDraftsFiles();
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_selectedDocumentsDraftsNewFiles.isNotEmpty ||
                              _documentDraftsAttachmentsToDelete.isNotEmpty ||
                              !isUpdate)
                            ElevatedButton.icon(
                              icon: _isUploadingDraft
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isUploadingDraft
                                    ? "Saving..."
                                    : (isUpdate ? "Update" : "Save"),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: _isUploadingDraft
                                  ? null
                                  : () async {
                                setModalState(() => _isUploadingDraft = true);

                                // Disable the button by showing loading state
                                try {
                                  bool success;

                                  if (isUpdate) {
                                    success = await draftService.updateDraft(
                                      draftId: documentDrafts!.id,
                                      advocateId: documentDrafts!.advocateId,
                                      caseId: documentDrafts!.caseId,
                                      userId: widget.advocateUserId!,
                                      existingFiles: _documentDraftsExistingAttachments,
                                      newFiles: _selectedDocumentsDraftsNewFiles,
                                    );
                                  } else {
                                    success = await draftService.addDraft(
                                      advocateId: widget.advocateId ?? "",
                                      caseId: widget.caseId!,
                                      userId: widget.advocateUserId!,
                                      files: _selectedDocumentsDraftsNewFiles,
                                    );
                                  }

                                  if (success) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isUpdate
                                                ? "✓ Document draft updated successfully"
                                                : "✓ Document draft created successfully",
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      Navigator.pop(context); // Close bottom sheet

                                      // Update UI
                                      setState(() {
                                        _loadFuture = _loadAllData();
                                        _selectedDocumentsDraftsNewFiles.clear();
                                        _documentDraftsAttachmentsToDelete.clear();
                                        _documentDraftsExistingAttachments.clear();
                                      });
                                    }
                                  } else {
                                    throw Exception("Operation failed");
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("✗ Error: ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() => _isUploadingDraft = false);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickJudgmentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedJudgmentFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
    }
  }

  void _showCaseJudgmentDialog({CaseJudgment? existing}) {
    final isUpdate = existing != null;
    final resultController = TextEditingController(
      text: existing?.result ?? "",
    );
    DateTime selectedDate = existing?.date ?? DateTime.now();
    _selectedJudgmentFile = null; // reset file

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isUpdate ? "Update Case Judgment" : "Add Case Judgment",
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: resultController,
                    decoration: const InputDecoration(
                      labelText: "Judgment Result",
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: const Text("Pick Date"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _selectedJudgmentFile?.name ??
                          "Select Attachment (Optional)",
                    ),
                    onPressed: () async {
                      await _pickJudgmentFile();
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isUploadingJudgment
                    ? null
                    : () async {
                  setDialogState(() => _isUploadingJudgment = true);

                  try {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId');

                    final response = isUpdate
                        ? await CaseJudgmentService.updateJudgment(
                      judgmentId: existing!.id,
                      caseId: widget.caseId!,
                      result: resultController.text,
                      userId: userId!,
                      oldAttachmentId: existing.judgmentAttachmentId,
                      file: _selectedJudgmentFile,
                      date: selectedDate,
                    )
                        : await CaseJudgmentService.addJudgment(
                      caseId: widget.caseId!,
                      result: resultController.text,
                      userId: userId!,
                      file: _selectedJudgmentFile,
                      date: selectedDate,
                    );

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isUpdate
                                  ? "✓ Judgment updated successfully"
                                  : "✓ Judgment added successfully",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(ctx); // Close dialog

                        setState(() {
                          _loadFuture = _loadAllData();
                        });
                      }
                    } else {
                      throw Exception("Failed with status: ${response.statusCode}");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✗ Error: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    setDialogState(() => _isUploadingJudgment = false);
                  }
                },
                child: _isUploadingJudgment
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(isUpdate ? "Update" : "Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _paymentTypeForTitle(String title) {
    switch (title) {
      case "Document Drafting":
        return "CASE_DOCUMENT_DRAFT_PAYMENT";
      case "Hearing Date Issued":
        return "CASE_HEARING_PAYMENT";
      case "Case Filing / Registration":
        return "CASE_FILING_PAYMENT";
      case "Paper Finalize":
        return "PAPER_FINALIZE_PAYMENT";
      case "Case Close":
        return "CASE_CLOSING_PAYMENT";
      default:
        return null;
    }
  }

  Future<void> _savePaymentPrice(String paymentType, double newPrice) async {
    setState(() => _isSavingPrice = true);
    try {
      final success = await PaymentService.saveOrUpdatePrice(
        token: widget.token!,
        userId: widget.advocateUserId!,
        caseId: widget.caseId!,
        paymentType: paymentType,
        price: newPrice,
      );

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Price updated to ৳$newPrice")));
        setState(() {
          _loadFuture = _loadAllData(); // refresh prices in timeline
        });
      } else {
        throw Exception("Failed to save price");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSavingPrice = false);
    }
  }

  void _showPriceEditDialog(String title, String? paymentType, bool add) async {
    if (paymentType == null) return;

    final controller = TextEditingController();

    // Prefill current price
    final current = await PaymentService.getCasePaymentPrice(
      widget.token!,
      widget.caseId!,
      paymentType,
    );
    if (current != null) controller.text = current.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit $title Price"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "New Price",
            prefixText: "৳ ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                Navigator.pop(ctx); // Close price dialog

                await _showLoadingDialog(
                  loadingMessage: "Saving price...",
                  task: () async {
                    if (add) {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token');
                      final userId = prefs.getString('userId');

                      final response = await http.post(
                        Uri.parse("${BASE_URL.Urls().baseURL}payment/add/$userId"),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'content-type': 'application/json',
                        },
                        body: jsonEncode({
                          "caseId": widget.caseId,
                          "paymentFor": paymentType,
                          "price": price,
                          "userId": userId,
                        }),
                      );

                      if (response.statusCode != 200 && response.statusCode != 201) {
                        throw Exception("Failed to update price");
                      }
                    }

                    await _savePaymentPrice(paymentType, price);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✓ Price updated to ৳$price"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickHearingFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedHearingNewFiles.addAll(
            result.files.where((f) => f.bytes != null),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking files: $e")));
    }
  }

  void _showHearingBottomSheet(Hearing? hearing) {
    final isUpdate = hearing != null;
    final nextNumber = hearings.isEmpty
        ? 1
        : hearings.map((h) => h.hearingNumber).reduce((a, b) => a > b ? a : b) +
        1;

    final hearingNumber = isUpdate ? hearing.hearingNumber : nextNumber;

    // Reset lists
    setState(() {
      _selectedHearingNewFiles.clear();
      _hearingAttachmentsToDelete.clear();
      if (isUpdate) {
        _hearingExistingAttachments = List.from(hearing.attachmentsId);
      } else {
        _hearingExistingAttachments.clear();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUpdate
                          ? "Update Hearing #$hearingNumber"
                          : "Add New Hearing #$hearingNumber",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_hearingExistingAttachments.isNotEmpty ||
                        _selectedHearingNewFiles.isNotEmpty)
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // Existing files
                            ..._hearingExistingAttachments.map((attId) {
                              final willDelete = _hearingAttachmentsToDelete
                                  .contains(attId);
                              return ListTile(
                                leading: Icon(
                                  willDelete
                                      ? Icons.delete_forever
                                      : Icons.attach_file,
                                  color: willDelete ? Colors.red : Colors.blue,
                                ),
                                title: Text(
                                  "File $attId",
                                  style: TextStyle(
                                    decoration: willDelete
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: willDelete ? Colors.red : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    willDelete
                                        ? Icons.restore
                                        : Icons.delete_outline,
                                    color: willDelete
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  onPressed: () => setModalState(() {
                                    if (willDelete) {
                                      _hearingAttachmentsToDelete.remove(attId);
                                    } else {
                                      _hearingAttachmentsToDelete.add(attId);
                                    }
                                  }),
                                ),
                              );
                            }),

                            // New files
                            ..._selectedHearingNewFiles.asMap().entries.map((
                                entry,
                                ) {
                              final idx = entry.key;
                              final file = entry.value;
                              return ListTile(
                                leading: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                title: Text(file.name),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => setModalState(() {
                                    _selectedHearingNewFiles.removeAt(idx);
                                  }),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text("Add Files"),
                            onPressed: () async {
                              await _pickHearingFiles();
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _isUploadingHearing
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.save),
                            label: Text(
                              _isUploadingHearing
                                  ? "Saving..."
                                  : (isUpdate ? "Update" : "Save"),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: _isUploadingHearing
                                ? null
                                : () async {
                              setModalState(() => _isUploadingHearing = true);

                              try {
                                final filteredExisting = _hearingExistingAttachments
                                    .where((id) => !_hearingAttachmentsToDelete.contains(id))
                                    .toList();

                                var response;

                                if (isUpdate) {
                                  response = await HearingService.updateHearing(
                                    token: widget.token!,
                                    hearingId: hearing!.id,
                                    userId: widget.advocateUserId!,
                                    caseId: hearing.caseId,
                                    hearingNumber: hearing.hearingNumber,
                                    existingFiles: filteredExisting,
                                    files: _selectedHearingNewFiles,
                                  );
                                } else {
                                  response = await HearingService.addHearing(
                                    token: widget.token!,
                                    userId: widget.advocateUserId!,
                                    caseId: widget.caseId!,
                                    hearingNumber: hearingNumber,
                                    files: _selectedHearingNewFiles,
                                  );
                                }

                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isUpdate
                                              ? "✓ Hearing #$hearingNumber updated successfully"
                                              : "✓ New hearing #$hearingNumber added successfully",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context); // Close bottom sheet

                                    setState(() {
                                      _loadFuture = _loadAllData();
                                      _selectedHearingNewFiles.clear();
                                      _hearingAttachmentsToDelete.clear();
                                      _hearingExistingAttachments.clear();
                                    });
                                  }
                                } else {
                                  throw Exception("Operation failed");
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("✗ Error: ${e.toString()}"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(() => _isUploadingHearing = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitRating() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final ratingValue = selectedStars * 20;

    final body = jsonEncode({
      "advocateId": widget.advocateId,
      "rating": ratingValue,
      "userId": widget.userId,
    });

    if (ratingId == null) {
      final response = await http.post(
        Uri.parse(
          "${BASE_URL.Urls().baseURL}advocate-rating/add/${widget.userId}",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'content-type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Rating saved")));

        _loadFuture = _loadAllData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Rating not saved")));
      }
    } else {
      final response = await http.put(
        Uri.parse(
          "${BASE_URL.Urls().baseURL}advocate-rating/update/$ratingId/${widget.userId}",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'content-type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Rating updated")));

        _loadFuture = _loadAllData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Rating not updated")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text("Ukil App"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= LEFT SIDE =================
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _caseSummaryCard(),
                      const SizedBox(height: 16),
                      _timelineCard(),
                      const SizedBox(height: 16),
                      if (caseJudgment != null)
                        _caseJudgmentTile(caseJudgment!),
                      if (caseJudgment == null)
                        IconButton(
                          onPressed: () async {
                            _showCaseJudgmentDialog();

                            setState(() {
                              //_loadAllData();
                            });
                          },
                          icon: Icon(Icons.add),
                        ),
                      const SizedBox(height: 16),
                      if (widget.userId != null) _advocateRatingCard(),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ================= RIGHT SIDE (HEARINGS) =================
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (documentDrafts != null)
                        _documentDraftTile(documentDrafts!)
                      else
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.description,
                              color: Colors.grey,
                            ),
                            title: Text("Document Draft"),
                            subtitle: Text("Not created yet"),
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (presentUsersAdvocateId != null &&
                          widget.advocateId == presentUsersAdvocateId)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              documentDrafts == null ? Icons.add : Icons.edit,
                              size: 20,
                            ),
                            label: Text(
                              documentDrafts == null
                                  ? "Add Document Draft"
                                  : "Update Document Draft",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: documentDrafts == null
                                  ? Colors.green
                                  : Colors.green,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: () {
                              _showDocumentDraftBottomSheet();
                            },
                          ),
                        ),

                      const SizedBox(height: 16),
                      _hearingCard(),
                      const SizedBox(height: 16),
                      if (widget.userId != null) _caseCloseButton(),
                      const SizedBox(height: 16),
                      if (widget.userId != null)
                        ElevatedButton(
                          onPressed: () {
                            print(
                              "in case tracking other user :- ${widget.advocateUserId} and name :- ${widget.caseLawyer} and my name :- ${widget.userName} and my id :- ${widget.userId}",
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUser: widget.advocateUserId,
                                  othersName: widget.caseLawyer,
                                  myName: widget.userName,
                                  currentUser: widget.userId,
                                ),
                              ),
                            );
                          },

                          child: Text(
                            "Chat with ${widget.caseLawyer}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= CASE SUMMARY =================
  Widget _caseSummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Case Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text("Case title :- ${widget.caseName}"),
            const SizedBox(height: 8),
            Text("Lawyer : ${widget.caseLawyer}"),
            const SizedBox(height: 8),
            Text("Issued Time : ${widget.issuedTime}"),
          ],
        ),
      ),
    );
  }

  // ================= TIMELINE =================
  Widget _timelineCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: timelineSteps.map(_timelineTile).toList()),
      ),
    );
  }

  Widget _timelineTile(TimelineStep step) {
    final canEdit =
        (presentUsersAdvocateId != null &&
            widget.advocateId == presentUsersAdvocateId) &&
            step.title != "Hearing Date Issued";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(step.icon, color: step.color),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: step.completed ? Colors.black : Colors.grey,
                  ),
                ),
                Text(step.subtitle),
                if (step.date != null)
                  Text(step.date!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          if (step.price != null)
            Row(
              children: [
                if (step.price != null)
                  Text(
                    "৳${step.price}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),

                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.green),
                    onPressed: () {
                      final type = _paymentTypeForTitle(step.title);
                      _showPriceEditDialog(step.title, type, false);
                    },
                  ),
              ],
            ),
          if (step.price == null)
            Row(
              children: [
                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId &&
                    canEdit)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                    onPressed: () {
                      final type = _paymentTypeForTitle(step.title);
                      _showPriceEditDialog(step.title, type, false);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ================ Hearing Card ===============
  Widget _hearingCard() {
    final isAdvocate =
        presentUsersAdvocateId != null &&
            presentUsersAdvocateId == widget.advocateId;

    // Correct logic: To add the NEXT hearing, price for it must be set first
    final canAddNextHearing = _hearingPriceCount >= hearings.length + 1;

    print(
      "total set hearing for price :- $_hearingPriceCount and total hearing :- ${hearings.length}",
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hearings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (hearings.isEmpty) const Text("No hearing scheduled"),

            ...hearings.map(_hearingTile),

            const SizedBox(height: 16),

            if (isAdvocate)
              Column(
                children: [
                  // 1. Hearing Price button - only when next price is NOT set
                  if (!canAddNextHearing)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(
                        "Set Price for Hearing #${hearings.length + 1}",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        _showPriceEditDialog(
                          "Hearing #${hearings.length + 1}",
                          "CASE_HEARING_PAYMENT",
                          true,
                        );
                      },
                    ),

                  // 2. Add Hearing button - only when price is already set
                  if (canAddNextHearing)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Hearing"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        _showHearingBottomSheet(null);
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _hearingTile(Hearing hearing) {
    final isAdvocate =
        presentUsersAdvocateId != null &&
            presentUsersAdvocateId == widget.advocateId;

    // Get price for this specific hearing (using hearing number)
    final paymentType = "CASE_HEARING_PAYMENT"; // same type for all hearings
    // We will show the price fetched for the case, but button allows update

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),

      child: ExpansionTile(
        leading: const Icon(Icons.gavel),
        title: Row(
          children: [
            Text("Hearing #${hearing.hearingNumber}"),
            const SizedBox(width: 8),
            Row(
              children: [
                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text(""),

                    onPressed: () async {
                      _showHearingBottomSheet(hearing);
                    },
                  ),
                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId)
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Hearing"),
                          content: Text("Are you sure you want to delete Hearing #${hearing.hearingNumber}?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      await _showLoadingDialog(
                        loadingMessage: "Deleting hearing #${hearing.hearingNumber}...",
                        task: () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          final userId = prefs.getString('userId');

                          bool deleted = await HearingService.removeHearing(
                            token!,
                            hearing.id,
                            userId!,
                          );

                          if (deleted) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("✓ Hearing #${hearing.hearingNumber} deleted successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {
                                _loadFuture = _loadAllData();
                              });
                            }
                          } else {
                            throw Exception("Failed to delete hearing");
                          }
                        },
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: Text(""),
                  ),
              ],
            ),
          ],
        ),
        subtitle: Text("Date: ${_formatDate(hearing.issuedDate)}"),
        trailing: hearing.attachmentsId.isNotEmpty
            ? Column(
          children: [
            Text(
              "${hearing.attachmentsId.length} files",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),


          ],
        )
            : null,
        children: [
          // ---------- ATTACHMENTS ----------
          if (hearing.attachmentsId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: hearing.attachmentsId
                    .map(
                      (attachmentId) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(attachmentId),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HearingAttachmentView(
                            attachmentId: attachmentId,
                            jwtToken: widget.token!,
                          ),
                        ),
                      );
                    },
                  ),
                )
                    .toList(),
              ),
            ),

          // ---------- APPEAL HEARINGS (FutureBuilder) ----------
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FutureBuilder<AppealHearing?>(
              future: AppealHearingService.getByHearing(
                widget.token!,
                hearing.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Failed to load appeal hearings",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final appeals = snapshot.data ?? null;

                if (appeals == null) {
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No appeal hearing for this hearing",
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (widget.userId != null)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ScheduleAppealHearingPage(
                                        token: widget.token!,
                                        hearingId: hearing.id,
                                        userId: widget.userId!,
                                        needUpdate: false,
                                      ),
                                ),
                              );
                            },
                            child: Text(
                              "Schedule Appeal Hearing",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        "Appeal Hearings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (appeals != null) _appealTile(appeals),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentDraftTile(DocumentDraft draft) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: const Icon(Icons.description, color: Colors.green),
          title: const Text("Document Draft"),
          subtitle: Text("Issued: ${_formatDate(draft.issuedDate)}"),
          trailing: draft.attachmentsId.isEmpty
              ? null
              : SizedBox(
            width: 110,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "${draft.attachmentsId.length} files",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Document Draft"),
                          content: const Text("Are you sure you want to delete this document draft?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      await _showLoadingDialog(
                        loadingMessage: "Deleting document draft...",
                        task: () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          final userId = prefs.getString('userId');

                          final response = await http.delete(
                            Uri.parse(
                              "${BASE_URL.Urls().baseURL}document-draft/${draft.id}?userId=$userId",
                            ),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'content-type': 'application/json',
                            },
                          );

                          if (response.statusCode == 200) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✓ Document draft deleted successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {
                                _loadFuture = _loadAllData();
                              });
                            }
                          } else {
                            throw Exception("Failed to delete");
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
          onTap: () {
            if (draft.attachmentsId.isNotEmpty) {
              _showDraftAttachmentSheet(draft);
            }
          },
        ),
      ),
    );
  }

  void _showDraftAttachmentSheet(DocumentDraft draft) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Document Draft Attachments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...draft.attachmentsId.map(
                      (attachmentId) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(attachmentId),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentDraftAttachmentView(
                              attachmentId: attachmentId,
                              jwtToken: widget.token!,
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
      },
    );
  }

  Widget _appealTile(AppealHearing appeal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        color: Colors.grey.shade100,
        child: ListTile(
          leading: const Icon(Icons.history, color: Colors.deepOrange),
          title: Text(appeal.reason),
          subtitle: appeal.appealHearingTime != null
              ? Text("Appeal Date: ${_formatDate(appeal.appealHearingTime!)}")
              : const Text("Appeal date not scheduled"),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "update" && await isMyCase()) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleAppealHearingPage(
                      token: widget.token!,
                      hearingId: appeal.hearingId,
                      userId: widget.userId!,
                      needUpdate: true,
                    ),
                  ),
                );

                if (result == true) {
                  setState(() {
                    _loadFuture = _loadAllData();
                  });
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "update", child: Text("Update")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _caseJudgmentTile(CaseJudgment caseJudgment) {
    final isAdvocate =
        presentUsersAdvocateId != null &&
            presentUsersAdvocateId == widget.advocateId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.description, color: Colors.green),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Case Judgment"),
            const SizedBox(height: 8),
            Text(caseJudgment.result),
            Text("Issued: ${_formatDate(caseJudgment.date)}"),
          ],
        ),
        subtitle: caseJudgment.judgmentAttachmentId == null
            ? null
            : Text(
          caseJudgment.judgmentAttachmentId!,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: isAdvocate
            ? SizedBox(
          width: 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    _showCaseJudgmentDialog(existing: caseJudgment),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Case Judgment"),
                      content: const Text("Are you sure you want to delete this judgment?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  await _showLoadingDialog(
                    loadingMessage: "Deleting case judgment...",
                    task: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('userId');

                      if (userId == null) throw Exception("User not logged in");

                      final result = await CaseJudgmentService.remove(
                        caseJudgment.id,

                      );

                      if (result.statusCode == 200) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✓ Case judgment deleted successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {
                            _loadFuture = _loadAllData();
                            this.caseJudgment = null;

                          });
                        }
                      } else {
                        throw Exception("Failed to delete (${result.statusCode})");
                      }
                    },
                  );
                },
              ),
            ],
          ),
        )
            : null,
        onTap: caseJudgment.judgmentAttachmentId != null
            ? () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaseJudgmentAttachmentView(
              attachmentId: caseJudgment.judgmentAttachmentId!,
              jwtToken: widget.token!,
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget _caseCloseButton() {
    if (caseClose == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            print("Open case action");

            CaseClose tempCaseClose = CaseClose.callingConstructor(
              widget.caseId!,
              widget.userId!,
              false,
              DateTime.now().toUtc(),
            );

            try {
              tempCaseClose = await CaseCloseService.addCaseClose(
                widget.token!,
                widget.userId!,
                tempCaseClose,
              );

              tempCaseClose.closedDate = DateTime.parse(
                DateTime.now().toIso8601String().replaceAll("+00:00", "Z"),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Case closed successfully")),
              );

              setState(() {
                caseClose = tempCaseClose;
                isClosed = true;
                _loadFuture = _loadAllData();
              });
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text("Close Case"),
        ),
      );
    }

    if (caseClose!.open == true) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            print("Close case action");

            CaseClose? tempCaseClose = await CaseCloseService.findByCaseId(
              widget.token,
              widget.caseId,
            );

            String? id = tempCaseClose?.id;

            tempCaseClose?.open = false;

            tempCaseClose?.closedDate = DateTime.parse(
              DateTime.now().toIso8601String().replaceAll("+00:00", "Z"),
            );

            try {
              CaseClose _tempCaseClose = await CaseCloseService.updateCaseClose(
                widget.token!,
                id,
                widget.userId!,
                tempCaseClose,
              );

              _tempCaseClose.closedDate = DateTime.parse(
                DateTime.now().toIso8601String().replaceAll("+00:00", "Z"),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Case closed successfully")),
              );

              setState(() {
                caseClose = _tempCaseClose;
                isClosed = true;
                _loadFuture = _loadAllData();
              });
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text("Close Case"),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        onPressed: () async {
          CaseClose? tempCaseClose = await CaseCloseService.findByCaseId(
            widget.token,
            widget.caseId,
          );

          String? id = tempCaseClose?.id;

          tempCaseClose?.open = true;

          tempCaseClose?.closedDate = DateTime.parse(
            DateTime.now().toIso8601String().replaceAll("+00:00", "Z"),
          );

          try {
            CaseClose _tempCaseClose = await CaseCloseService.updateCaseClose(
              widget.token!,
              id,
              widget.userId!,
              tempCaseClose,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Case re open successfully")),
            );

            setState(() {
              caseClose = _tempCaseClose;
              isClosed = true;
              _loadFuture = _loadAllData();
            });
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
        child: const Text("Case Close"),
      ),
    );
  }

  Future<void> _loadMyRating() async {
    if (widget.userId == null || widget.advocateId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate-rating/user/${widget.userId}",
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final List<dynamic> list = jsonDecode(res.body);

      for (var item in list) {
        if (item["advocateId"] == widget.advocateId) {
          ratingId = item["id"];
          selectedStars = ((item["rating"] ?? 0) / 20).round();
          break;
        }
      }
    }

    ratingLoaded = true;
  }

  Widget _advocateRatingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rate Advocate",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < selectedStars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedStars = index + 1;
                    });
                  },
                );
              }),
            ),

            Text("Score: ${selectedStars * 20} / 100"),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: selectedStars == 0 ? null : _submitRating,
              child: Text(ratingId == null ? "Submit Rating" : "Update Rating"),
            ),
          ],
        ),
      ),
    );
  }
}