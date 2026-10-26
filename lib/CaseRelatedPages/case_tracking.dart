import 'dart:convert';

import 'package:advocatechaiadvocate/CaseRelatedPages/CaseJudgmentAttachmentViewer.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/payment_service.dart';
import '../CaseRelatedPages/payment_details_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ChatRelatedPages/chat_screen.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../Utils/case_stages.dart' as CASE_STAGES;
import '../Utils/responsive_helper.dart';
import 'case_close_service.dart';
import 'case_judgment_service.dart';
import 'CaseJudgmentModel.dart';

import 'package:advocatechaiadvocate/CaseRelatedPages/CaseCloseModel.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/document_draft_service.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/_TimelineStep.dart';
import '../CaseRelatedPages/ReadStatusModel.dart';
import 'ScheduleAppealHearingPage.dart';
import 'package:file_picker/file_picker.dart';

import 'AppealHearingModel.dart';
import 'DocumentDraftAttachmentViewer.dart';
import 'HearingAttachmentViewer.dart';
import 'HearingModel.dart';
import 'appeal_hearing_service.dart';
import 'case_tracking_model.dart';
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

  DocumentDraftResponse? documentDrafts;
  CaseJudgmentResponse? caseJudgment;
  CaseClose? caseClose;
  List<TimelineStep> timelineSteps = [];
  List<HearingResponse> hearings = [];
  bool? isClosed;
  bool hasDraft = false;
  int selectedStars = 0;
  String? ratingId;
  bool ratingLoaded = false;
  String? presentUsersAdvocateId;

  // ✅ NEW: hold error messages so UI can surface them
  String? _judgmentLoadError;
  String? _draftLoadError;

  bool _isUploadingDraft = false;
  List<PlatformFile> _selectedDocumentsDraftsNewFiles = [];
  List<String> _documentDraftsExistingAttachments = [];
  Set<String> _documentDraftsAttachmentsToDelete = {};

  bool _isUploadingHearing = false;
  List<PlatformFile> _selectedHearingNewFiles = [];
  List<String> _hearingExistingAttachments = [];
  Set<String> _hearingAttachmentsToDelete = {};

  bool _isSavingPrice = false;
  TextEditingController _priceController = TextEditingController();
  int _hearingPriceCount = 0;

  PlatformFile? _selectedJudgmentFile;
  bool _isUploadingJudgment = false;

  List<ReadStatus> readStatuses = [];
  bool _isUpdatingReadStatus = false;

  List<CaseTrackingStage> caseTrackings = [];
  bool _isUpdatingCaseTracking = false;

  Map<String, double> stagePrices = {};
  Map<String, PaymentDetails> stagePayments = {};

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
    // Reset errors each load
    _judgmentLoadError = null;
    _draftLoadError = null;

    final draftService = DocumentDraftService(widget.token!);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    presentUsersAdvocateId = prefs.getString("advocateId");

    print("present users advocate id :- $presentUsersAdvocateId");
    print("caseTracking loadAllData for caseId :- ${widget.caseId}");
    print("token length :- ${widget.token?.length}");

    try {
      await _loadMyRating();
    } catch (e) {
      print("rating load error :- $e");
    }

    // ---------- DOCUMENT DRAFT ----------
    try {
      print("📄 fetching document draft for case ${widget.caseId}...");
      documentDrafts = await draftService.findByCase(widget.caseId!);
      print("📄 document draft result :- $documentDrafts");
      hasDraft = documentDrafts != null;
    } catch (e, st) {
      print("❌ DOCUMENT DRAFT LOAD ERROR: $e");
      print(st);
      documentDrafts = null;
      hasDraft = false;
      _draftLoadError = e.toString();
    }

    // ---------- HEARINGS ----------
    try {
      print("⚖️ collecting hearings...");
      hearings = await HearingService.getByCase(
        widget.token!,
        widget.caseId!,
      );
      print("⚖️ hearings count :- ${hearings.length}");
    } catch (e) {
      print("⚠️ hearing load error :- $e");
      hearings = [];
    }

    // ---------- HEARING PRICE COUNT ----------
    try {
      _hearingPriceCount = await PaymentService.getHearingPaymentCount(
        widget.token!,
        widget.caseId!,
      );
      print("💵 hearing price count :- $_hearingPriceCount");
    } catch (e) {
      print("⚠️ hearing price count error :- $e");
      _hearingPriceCount = 0;
    }

    // ---------- CASE CLOSE ----------
    try {
      caseClose = await CaseCloseService.findByCaseId(
        widget.token!,
        widget.caseId!,
      );
      isClosed = caseClose != null && caseClose?.open == false;
    } catch (e) {
      print("⚠️ case close load error :- $e");
    }

    // ---------- CASE TRACKINGS ----------
    try {
      print("🗂 collecting case trackings...");
      caseTrackings = await _getCaseTrackingsByCase();
      caseTrackings.sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
    } catch (e) {
      print("⚠️ error loading case trackings: $e");
      caseTrackings = [];
    }

    // Build dynamic timeline
    timelineSteps = caseTrackings.map((ct) {
      final price = stagePayments[ct.caseStage]?.price;
      return TimelineStep(
        title: _prettyStageName(ct.caseStage),
        subtitle: "Stage ${ct.stageNumber}",
        date: "",
        icon: Icons.timeline,
        color: Colors.deepPurple,
        completed: true,
        price: price,
      );
    }).toList();

    // ---------- STAGE PAYMENTS ----------
    try {
      final payments = await _getPaymentsByCase(widget.caseId!);
      setState(() {
        stagePayments = {for (var p in payments) p.paymentFor.toString(): p};
      });
    } catch (e) {
      print("⚠️ Error loading stage prices: $e");
      stagePayments = {};
    }

    // ---------- CASE JUDGMENT (LOUD) ----------
    try {
      print("🏛 fetching case judgment for case ${widget.caseId}...");
      final judgmentRes = await CaseJudgmentService.getByCase(widget.caseId!);
      print("🏛 judgment result :- $judgmentRes");

      if (judgmentRes != null) {
        caseJudgment = judgmentRes;
        print("🏛 judgment loaded: id=${caseJudgment!.id}, result=${caseJudgment!.result}");
      } else {
        // 404 → no judgment. Legitimately null. Not an error.
        caseJudgment = null;
        print("🏛 no judgment exists for this case (null)");
      }
    } catch (e, st) {
      // This is a REAL failure — surface it in the UI
      print("❌ CASE JUDGMENT LOAD ERROR: $e");
      print(st);
      caseJudgment = null;
      _judgmentLoadError = e.toString();
    }

    // ---------- READ STATUSES ----------
    try {
      print("👁 collecting read statuses...");
      readStatuses = await _getReadStatusesByCase();
      print("👁 read statuses count :- ${readStatuses.length}");
    } catch (e) {
      print("⚠️ read status load error :- $e");
      readStatuses = [];
    }
  }

  Future<List<PaymentDetails>> _getPaymentsByCase(String caseId) async {
    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}payment/case/$caseId"),
      headers: {'Authorization': 'Bearer ${widget.token!}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PaymentDetails.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payments: ${response.statusCode}');
    }
  }

  Future<List<CaseTrackingStage>> _getCaseTrackingsByCase() async {
    final response = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}caseTracking/case/${widget.caseId!}",
      ),
      headers: {'Authorization': 'Bearer ${widget.token!}'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => CaseTrackingStage.fromJson(j)).toList();
    }
    throw Exception('Failed to load trackings');
  }

  Future<bool> _addCaseTracking(String caseStage, DateTime selectedDateTime,
      bool? visibility) async {
    final userId = widget.advocateUserId ??
        (await SharedPreferences.getInstance()).getString('userId');
    final response = await http.post(
      Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/add/$userId"),
      headers: {
        'Authorization': 'Bearer ${widget.token!}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        "caseId": widget.caseId!,
        "caseStage": caseStage,
        "trackingTime": selectedDateTime.toUtc().toIso8601String(),
        "visibility": visibility!
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> _updateCaseTracking(String id, String caseStage,
      DateTime selectedDateTime, bool? visibility) async {
    final userId = widget.advocateUserId ??
        (await SharedPreferences.getInstance()).getString('userId');
    final response = await http.put(
      Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/update/$id/$userId"),
      headers: {
        'Authorization': 'Bearer ${widget.token!}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        "caseId": widget.caseId!,
        "caseStage": caseStage,
        "trackingTime": selectedDateTime.toUtc().toIso8601String(),
        "visibility": visibility!
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> _deleteCaseTracking(String id) async {
    final userId = widget.advocateUserId ??
        (await SharedPreferences.getInstance()).getString('userId');
    final response = await http.delete(
      Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/delete/$id/$userId"),
      headers: {'Authorization': 'Bearer ${widget.token!}'},
    );
    return response.statusCode == 200;
  }

  Future<bool> _swapCaseTrackings(String id1, String id2) async {
    final response = await http.put(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}caseTracking/swap?caseTrackingId1=$id1&caseTrackingId2=$id2",
      ),
      headers: {'Authorization': 'Bearer ${widget.token!}'},
    );
    return response.statusCode == 200;
  }

  String _prettyStageName(String stage) {
    String shortName = CASE_STAGES.CaseStages.getShortName(stage);

    if (shortName != stage && shortName.length < 25) {
      return shortName;
    }

    String name = stage.replaceAll("CASE_", "").replaceAll("_PAYMENT", "");
    String formatted = name
        .split("_")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");

    return formatted;
  }

  Future<List<ReadStatus>> _getReadStatusesByCase() async {
    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}read-status/case/${widget.caseId!}"),
      headers: {
        'Authorization': 'Bearer ${widget.token!}',
        'content-type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ReadStatus.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load read statuses: ${response.statusCode}');
    }
  }

  Future<bool> _addReadStatus(String statusText) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.advocateUserId ?? prefs.getString('userId');
    if (userId == null) throw Exception("User ID not found");

    final response = await http.post(
      Uri.parse("${BASE_URL.Urls().baseURL}read-status/$userId"),
      headers: {
        'Authorization': 'Bearer ${widget.token!}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        "caseId": widget.caseId!,
        "advocateId": widget.advocateId!,
        "status": statusText,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception("Failed to add read status: ${response.statusCode}");
    }
  }

  Future<bool> _updateReadStatus(String id, String statusText) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.advocateUserId ?? prefs.getString('userId');
    if (userId == null) throw Exception("User ID not found");

    final response = await http.put(
      Uri.parse("${BASE_URL.Urls().baseURL}read-status/$id/$userId"),
      headers: {
        'Authorization': 'Bearer ${widget.token!}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        "caseId": widget.caseId!,
        "advocateId": widget.advocateId!,
        "status": statusText,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception("Failed to update read status: ${response.statusCode}");
    }
  }

  Future<T> _showLoadingDialog<T>({
    required Future<T> Function() task,
    String loadingMessage = "Processing...",
  }) async {
    if (!mounted) return await task();

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
      setState(() => _loadFuture = _loadAllData());
      if (context.mounted) Navigator.pop(context);
      return result;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking files: $e")));
    }
  }

  void _showDocumentDraftBottomSheet() {
    final draftService = DocumentDraftService(widget.token!);
    final isUpdate = documentDrafts != null;

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

                      if (_documentDraftsExistingAttachments.isNotEmpty ||
                          _selectedDocumentsDraftsNewFiles.isNotEmpty)
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              ..._documentDraftsExistingAttachments.map((
                                attId,
                              ) {
                                final willDelete =
                                    _documentDraftsAttachmentsToDelete
                                        .contains(attId);
                                return ListTile(
                                  leading: Icon(
                                    willDelete
                                        ? Icons.delete_forever
                                        : Icons.attach_file,
                                    color:
                                        willDelete ? Colors.red : Colors.blue,
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
                                          _documentDraftsAttachmentsToDelete
                                              .remove(attId);
                                        } else {
                                          _documentDraftsAttachmentsToDelete
                                              .add(attId);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),

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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
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
                                      setModalState(
                                        () => _isUploadingDraft = true,
                                      );

                                      try {
                                        if (isUpdate) {
                                          await draftService.updateDraft(
                                            draftId: documentDrafts!.id,
                                            advocateId:
                                                documentDrafts!.advocateId,
                                            caseId: documentDrafts!.caseId,
                                            userId: widget.advocateUserId!,
                                            existingFiles:
                                                _documentDraftsExistingAttachments
                                                    .where((id) =>
                                                        !_documentDraftsAttachmentsToDelete
                                                            .contains(id))
                                                    .toList(),
                                            newFiles:
                                                _selectedDocumentsDraftsNewFiles,
                                          );
                                        } else {
                                          await draftService.addDraft(
                                            advocateId: widget.advocateId ?? "",
                                            caseId: widget.caseId!,
                                            userId: widget.advocateUserId!,
                                            files:
                                                _selectedDocumentsDraftsNewFiles,
                                          );
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isUpdate
                                                    ? "✓ Document draft updated successfully"
                                                    : "✓ Document draft created successfully",
                                              ),
                                              backgroundColor: Colors.green,
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                          Navigator.pop(context);

                                          setState(() {
                                            _loadFuture = _loadAllData();
                                            _selectedDocumentsDraftsNewFiles
                                                .clear();
                                            _documentDraftsAttachmentsToDelete
                                                .clear();
                                            _documentDraftsExistingAttachments
                                                .clear();
                                          });
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "✗ Error: ${e.toString()}",
                                              ),
                                              backgroundColor: Colors.red,
                                              duration:
                                                  const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      } finally {
                                        setModalState(
                                          () => _isUploadingDraft = false,
                                        );
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking file: $e")));
    }
  }

  void _showCaseJudgmentDialog({CaseJudgmentResponse? existing}) {
    final isUpdate = existing != null;
    final resultController = TextEditingController(
      text: existing?.result ?? "",
    );
    DateTime selectedDate = existing?.date ?? DateTime.now();
    _selectedJudgmentFile = null;

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
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId');

                          if (isUpdate) {
                            await CaseJudgmentService.updateJudgment(
                              judgmentId: existing!.id,
                              caseId: widget.caseId!,
                              result: resultController.text,
                              userId: userId!,
                              oldAttachmentId:
                                  existing.judgmentAttachmentId,
                              file: _selectedJudgmentFile,
                              date: selectedDate,
                            );
                          } else {
                            await CaseJudgmentService.addJudgment(
                              caseId: widget.caseId!,
                              result: resultController.text,
                              userId: userId!,
                              file: _selectedJudgmentFile,
                              date: selectedDate,
                            );
                          }

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
                            Navigator.pop(ctx);

                            setState(() {
                              _loadFuture = _loadAllData();
                            });
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
                    : Text(
                        isUpdate ? "Update" : "Add",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Price updated to ৳$newPrice")));
        setState(() {
          _loadFuture = _loadAllData();
        });
      } else {
        throw Exception("Failed to save price");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSavingPrice = false);
    }
  }

  void _showPriceEditDialog(
    String title,
    String? paymentTypeEnumStr,
    bool isAddMode,
  ) async {
    if (paymentTypeEnumStr == null) return;

    final controller = TextEditingController();
    final currentPayment = stagePayments[paymentTypeEnumStr];
    if (currentPayment != null)
      controller.text = currentPayment.price.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isAddMode ? "Set Price for $title" : "Update Price for $title",
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Price (৳)",
            prefixText: "৳ ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a valid price > 0"),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);

              await _showLoadingDialog(
                loadingMessage:
                    isAddMode ? "Setting price..." : "Updating price...",
                task: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token');
                  final userId =
                      prefs.getString('userId') ?? widget.advocateUserId;
                  if (userId == null) throw Exception("User ID not found");

                  final url = isAddMode
                      ? "${BASE_URL.Urls().baseURL}payment/add/$userId"
                      : "${BASE_URL.Urls().baseURL}payment/update/${currentPayment!.id}/$userId";

                  final response = isAddMode
                      ? await http.post(
                          Uri.parse(url),
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            "caseId": widget.caseId,
                            "paymentFor": paymentTypeEnumStr,
                            "price": price,
                            "userId": userId,
                          }),
                        )
                      : await http.put(
                          Uri.parse(url),
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            "caseId": widget.caseId,
                            "paymentFor": paymentTypeEnumStr,
                            "price": price,
                            "userId": userId,
                          }),
                        );

                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    await _loadAllData();
                  } else {
                    throw Exception("Failed: ${response.statusCode}");
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✓ Price set to ৳$price"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
            child: Text(isAddMode ? "Set Price" : "Update"),
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking files: $e")));
    }
  }

  Future<void> _showHearingBottomSheet(HearingResponse? hearing) async {
    final isUpdate = hearing != null;
    final nextNumber = hearings.isEmpty
        ? 1
        : hearings
                .map((h) => h.hearingNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;

    final hearingNumber = isUpdate ? hearing.hearingNumber : nextNumber;

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
                            ..._hearingExistingAttachments.map((attId) {
                              final willDelete = _hearingAttachmentsToDelete
                                  .contains(attId);
                              return ListTile(
                                leading: Icon(
                                  willDelete
                                      ? Icons.delete_forever
                                      : Icons.attach_file,
                                  color:
                                      willDelete ? Colors.red : Colors.blue,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                                    setModalState(
                                      () => _isUploadingHearing = true,
                                    );

                                    try {
                                      final filteredExisting =
                                          _hearingExistingAttachments
                                              .where(
                                                (id) =>
                                                    !_hearingAttachmentsToDelete
                                                        .contains(id),
                                              )
                                              .toList();

                                      http.Response response;

                                      if (isUpdate) {
                                        response = await HearingService
                                            .updateHearing(
                                          token: widget.token!,
                                          hearingId: hearing!.id,
                                          userId: widget.advocateUserId!,
                                          caseId: hearing.caseId,
                                          hearingNumber: hearing.hearingNumber,
                                          existingFiles: filteredExisting,
                                          files: _selectedHearingNewFiles,
                                        );
                                      } else {
                                        response =
                                            await HearingService.addHearing(
                                          token: widget.token!,
                                          userId: widget.advocateUserId!,
                                          caseId: widget.caseId!,
                                          hearingNumber: hearingNumber,
                                          files: _selectedHearingNewFiles,
                                        );
                                      }

                                      if (response.statusCode == 200 ||
                                          response.statusCode == 201) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isUpdate
                                                    ? "✓ Hearing #$hearingNumber updated successfully"
                                                    : "✓ New hearing #$hearingNumber added successfully",
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          setState(() {
                                            _loadFuture = _loadAllData();
                                            _selectedHearingNewFiles.clear();
                                            _hearingAttachmentsToDelete
                                                .clear();
                                            _hearingExistingAttachments
                                                .clear();
                                          });

                                          Navigator.pop(context, true);
                                        } else {
                                          Navigator.pop(context, false);
                                        }
                                      } else {
                                        Navigator.pop(context, false);
                                        throw Exception("Operation failed");
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "✗ Error: ${e.toString()}",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } finally {
                                      setModalState(
                                        () => _isUploadingHearing = false,
                                      );
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Rating saved")));
        _loadFuture = _loadAllData();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Rating not saved")));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Rating updated")));
        _loadFuture = _loadAllData();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Rating not updated")));
      }
    }
  }

  // ==================== RESPONSIVE HELPERS ====================
  Widget _buildMainLeftContent(double spacing) {
    return Column(
      children: [
        _caseSummaryCard(),
        SizedBox(height: spacing),
        _caseTrackingCard(),
        SizedBox(height: spacing),
        // ✅ Judgment tile OR error card OR add button
        if (caseJudgment != null)
          _caseJudgmentTile(caseJudgment!)
        else if (_judgmentLoadError != null)
          _judgmentErrorCard()
        else
          IconButton(
            onPressed: () async {
              _showCaseJudgmentDialog();
            },
            icon: const Icon(Icons.add),
          ),
        SizedBox(height: spacing),
        if (widget.userId != null) _advocateRatingCard(),
      ],
    );
  }

  Widget _judgmentErrorCard() {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: const Text(
          "Could not load case judgment",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        subtitle: Text(
          _judgmentLoadError ?? "",
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              _loadFuture = _loadAllData();
            });
          },
        ),
      ),
    );
  }

  Widget _buildMainRightContent(double spacing) {
    return Column(
      children: [
        if (documentDrafts != null)
          _documentDraftTile(documentDrafts!)
        else if (_draftLoadError != null)
          Card(
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.error, color: Colors.orange),
              title: const Text(
                "Could not load document draft",
                style: TextStyle(color: Colors.orange),
              ),
              subtitle: Text(
                _draftLoadError ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _loadFuture = _loadAllData();
                  });
                },
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.grey),
              title: const Text("Document Draft"),
              subtitle: const Text("Not created yet"),
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
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _showDocumentDraftBottomSheet,
            ),
          ),
        SizedBox(height: spacing),
        _hearingCard(),
        SizedBox(height: spacing),
        _readStatusCard(),
        SizedBox(height: spacing),
        if (widget.userId != null) _caseCloseButton(),
        const SizedBox(height: 16),
        if (widget.userId != null)
          ElevatedButton(
            onPressed: () {
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
                fontSize: ResponsiveHelper.fontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final spacing = ResponsiveHelper.padding(context, 12);

    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text("Ukil App"),
        centerTitle: true,
        backgroundColor: Colors.green,
        toolbarHeight: ResponsiveHelper.buttonHeight(context) * 1.2,
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainLeftContent(spacing),
                      SizedBox(height: spacing * 2),
                      _buildMainRightContent(spacing),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMainLeftContent(spacing)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildMainRightContent(spacing)),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.buttonHeight(context),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: ResponsiveHelper.iconSize(context, 18)),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.fontSize(context, 14),
            color: textColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.cardRadius(context) * 0.6,
            ),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _caseSummaryCard() {
    final padding = ResponsiveHelper.padding(context, 12);
    final fontSize = ResponsiveHelper.fontSize(context, 18);
    final subFontSize = ResponsiveHelper.fontSize(context, 14);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(ResponsiveHelper.cardRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Case Summary",
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 12)),
            Text(
              "Case title :- ${widget.caseName}",
              style: TextStyle(fontSize: subFontSize),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 6)),
            Text(
              "Lawyer : ${widget.caseLawyer}",
              style: TextStyle(fontSize: subFontSize),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 6)),
            Text(
              "Issued Time : ${widget.issuedTime}",
              style: TextStyle(fontSize: subFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

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
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;

    final matchingStage = caseTrackings.firstWhere(
      (ct) => _prettyStageName(ct.caseStage) == step.title,
      orElse: () =>
          CaseTrackingStage(caseId: "", caseStage: "", stageNumber: 0),
    );

    final stageEnumStr =
        matchingStage.caseStage.isNotEmpty ? matchingStage.caseStage : null;
    final currentPayment =
        stageEnumStr != null ? stagePayments[stageEnumStr] : null;
    final currentPrice = currentPayment?.price ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 380;

    final iconSize = isVerySmallScreen
        ? ResponsiveHelper.iconSize(context, 18)
        : ResponsiveHelper.iconSize(context, 20);
    final priceFontSize = ResponsiveHelper.fontSize(context, 14);

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
                if (step.date != null && step.date!.isNotEmpty)
                  Text(step.date!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          if (isAdvocate)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentPrice > 0)
                  Text(
                    "৳${currentPrice.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: priceFontSize,
                      color: Colors.green,
                    ),
                  )
                else
                  Text(
                    "No price",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: priceFontSize - 1,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    currentPrice > 0 ? Icons.edit : Icons.add_circle,
                    color: Colors.green,
                    size: iconSize,
                  ),
                  onPressed: () => _showPriceEditDialog(
                    step.title,
                    stageEnumStr,
                    currentPayment == null,
                  ),
                ),
                if (currentPrice > 0)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: iconSize),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Price"),
                          content: const Text("Delete this stage price?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      await _showLoadingDialog(
                        loadingMessage: "Deleting price...",
                        task: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId') ??
                              widget.advocateUserId;
                          final token = prefs.getString('jwt_token');

                          final response = await http.delete(
                            Uri.parse(
                              "${BASE_URL.Urls().baseURL}payment/${currentPayment!.id}/$userId",
                            ),
                            headers: {'Authorization': 'Bearer $token'},
                          );

                          return response.statusCode == 200;
                        },
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✓ Price deleted"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() => _loadFuture = _loadAllData());
                      }
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _hearingCard() {
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;

    final canAddNextHearing = _hearingPriceCount >= hearings.length + 1;

    final padding = ResponsiveHelper.padding(context, 12);
    final titleSize = ResponsiveHelper.fontSize(context, 18);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hearings",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 12)),
            if (hearings.isEmpty)
              Text(
                "No hearing scheduled",
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(context, 14),
                  color: Colors.grey,
                ),
              ),
            ...hearings.map(_hearingTile),
            SizedBox(height: ResponsiveHelper.padding(context, 12)),
            if (isAdvocate)
              Column(
                children: [
                  if (!canAddNextHearing)
                    _buildResponsiveButton(
                      icon: Icons.attach_money,
                      label: "Set Price for Hearing #${hearings.length + 1}",
                      color: Colors.green,
                      onPressed: () {
                        _showPriceEditDialog(
                          "Hearing #${hearings.length + 1}",
                          "CASE_HEARING_PAYMENT",
                          true,
                        );
                      },
                    ),
                  if (canAddNextHearing)
                    _buildResponsiveButton(
                      icon: Icons.add,
                      label: "Add New Hearing",
                      color: Colors.green,
                      onPressed: () async {
                        await _showHearingBottomSheet(null);
                        setState(() => _loadFuture = _loadAllData());
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _hearingTile(HearingResponse hearing) {
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;

    final titleSize = ResponsiveHelper.fontSize(context, 15);
    final subSize = ResponsiveHelper.fontSize(context, 12);

    return Card(
      margin:
          EdgeInsets.symmetric(vertical: ResponsiveHelper.padding(context, 6)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.cardRadius(context) * 0.7,
        ),
      ),
      child: ExpansionTile(
        leading:
            Icon(Icons.gavel, size: ResponsiveHelper.iconSize(context, 20)),
        title: Row(
          children: [
            Text(
              "Hearing #${hearing.hearingNumber}",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: ResponsiveHelper.iconSize(context, 18),
                    ),
                    onPressed: () async {
                      _showHearingBottomSheet(hearing);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (presentUsersAdvocateId != null &&
                    widget.advocateId == presentUsersAdvocateId)
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Hearing"),
                          content: Text(
                            "Are you sure you want to delete Hearing #${hearing.hearingNumber}?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      await _showLoadingDialog(
                        loadingMessage:
                            "Deleting hearing #${hearing.hearingNumber}...",
                        task: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          final userId = prefs.getString('userId');

                          bool deleted = await HearingService.removeHearing(
                            token!,
                            hearing.id,
                            userId!,
                          );

                          if (!deleted) {
                            throw Exception("Failed to delete hearing");
                          }
                        },
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "✓ Hearing #${hearing.hearingNumber} deleted successfully",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.delete,
                      size: ResponsiveHelper.iconSize(context, 18),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          "Date: ${_formatDate(hearing.issuedDate)}",
          style: TextStyle(fontSize: subSize),
        ),
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
          if (hearing.attachmentsId.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.padding(context, 12),
              ),
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
                              final result = Navigator.push(
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

                              if (result == true) {
                                setState(() => _loadFuture = _loadAllData());
                              }
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

  Widget _documentDraftTile(DocumentDraftResponse draft) {
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
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Document Draft"),
                                content: const Text(
                                  "Are you sure you want to delete this document draft?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            await _showLoadingDialog(
                              loadingMessage: "Deleting document draft...",
                              task: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                final token = prefs.getString('jwt_token');
                                final userId = prefs.getString('userId');

                                final ok = await DocumentDraftService(
                                        token ?? widget.token!)
                                    .deleteDraft(draft.id, userId!);

                                if (!ok) {
                                  throw Exception(
                                      "Failed to delete document draft");
                                }
                              },
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "✓ Document draft deleted successfully",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
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

  void _showDraftAttachmentSheet(DocumentDraftResponse draft) {
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

  Widget _caseJudgmentTile(CaseJudgmentResponse caseJudgment) {
    final isAdvocate = presentUsersAdvocateId != null &&
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
                      onPressed: () =>
                          _deleteJudgmentWithFeedback(caseJudgment),
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

  Future<void> _deleteJudgmentWithFeedback(
      CaseJudgmentResponse judgment) async {
    // 1. Ask for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Case Judgment"),
        content: const Text(
          "Are you sure you want to delete this judgment?",
        ),
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

    // 2. Perform delete and CLEAR STATE ON SUCCESS ONLY
    try {
      await _showLoadingDialog(
        loadingMessage: "Deleting case judgment...",
        task: () async {
          final bool ok =
              await CaseJudgmentService.remove(judgment.id);

          if (!ok) {
            throw Exception(
                "Backend rejected delete (probably not your case)");
          }
        },
      );

      if (!mounted) return;

      // ✅ Delete succeeded — clear local state and refresh
      setState(() {
        caseJudgment = null;
        _judgmentLoadError = null;
        _loadFuture = _loadAllData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✓ Case judgment deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✗ Delete failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _caseCloseButton() {
    if (caseClose == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
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
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
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
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
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
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
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
    final padding = ResponsiveHelper.padding(context, 12);
    final titleSize = ResponsiveHelper.fontSize(context, 18);
    final starSize = ResponsiveHelper.iconSize(context, 30);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rate Advocate",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 10)),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < selectedStars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: starSize,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedStars = index + 1;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                );
              }),
            ),
            Text(
              "Score: ${selectedStars * 20} / 100",
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 10)),
            ElevatedButton(
              onPressed: selectedStars == 0 ? null : _submitRating,
              child: Text(ratingId == null ? "Submit Rating" : "Update Rating"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readStatusCard() {
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Read Statuses",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (readStatuses.isEmpty)
              const Text(
                "No read status submitted yet",
                style: TextStyle(color: Colors.grey),
              ),
            ...readStatuses.map(_readStatusTile),
            const SizedBox(height: 16),
            if (isAdvocate)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add New Read Status",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => _showReadStatusBottomSheet(null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readStatusTile(ReadStatus rs) {
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.visibility, color: Colors.blue),
        title: Text(
          rs.status,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Issued: ${_formatDate(rs.issuedTime)}",
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: isAdvocate
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) async {
                  if (value == "edit") {
                    _showReadStatusBottomSheet(rs);
                  } else if (value == "delete") {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Read Status"),
                        content: const Text(
                          "Are you sure you want to delete this read status?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    await _showLoadingDialog(
                      loadingMessage: "Deleting read status...",
                      task: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId =
                            widget.advocateUserId ?? prefs.getString('userId');
                        if (userId == null)
                          throw Exception("User ID not found");

                        final response = await http.delete(
                          Uri.parse(
                            "${BASE_URL.Urls().baseURL}read-status/${rs.id}/$userId",
                          ),
                          headers: {'Authorization': 'Bearer ${widget.token!}'},
                        );

                        if (response.statusCode != 200) {
                          throw Exception("Failed to delete");
                        }
                        return true;
                      },
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✓ Read status deleted successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: "edit",
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.green),
                      title: Text("Edit"),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: "delete",
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text("Delete"),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _showReadStatusBottomSheet(ReadStatus? existing) {
    final isUpdate = existing != null;
    final statusController = TextEditingController(
      text: existing?.status ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
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
                      isUpdate ? "Update Read Status" : "Add New Read Status",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: statusController,
                      decoration: const InputDecoration(
                        labelText: "Read Status",
                        hintText: "e.g. Case file reviewed by advocate",
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: _isUpdatingReadStatus
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isUpdatingReadStatus
                            ? "Saving..."
                            : (isUpdate ? "Update" : "Save"),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _isUpdatingReadStatus
                          ? null
                          : () async {
                              setModalState(() => _isUpdatingReadStatus = true);

                              try {
                                final success = isUpdate
                                    ? await _updateReadStatus(
                                        existing!.id!,
                                        statusController.text,
                                      )
                                    : await _addReadStatus(
                                        statusController.text,
                                      );

                                if (!success) {
                                  throw Exception(
                                    "Failed to do the changes at here....",
                                  );
                                }

                                await _loadAllData();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isUpdate
                                            ? "✓ Read status updated successfully"
                                            : "✓ Read status added successfully",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);

                                  setState(() {
                                    _loadFuture = _loadAllData();
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("✗ Error: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(
                                  () => _isUpdatingReadStatus = false,
                                );
                              }
                            },
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

  Widget _caseTrackingCard() {
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;

    final padding = ResponsiveHelper.padding(context, 12);
    final titleSize = ResponsiveHelper.fontSize(context, 18);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(ResponsiveHelper.cardRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Timeline Stages",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.padding(context, 12)),
            if (caseTrackings.isEmpty)
              Text(
                "No stages added yet",
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(context, 14),
                  color: Colors.grey,
                ),
              ),
            ...caseTrackings.map(_caseTrackingTile),
            const SizedBox(height: 16),
            if (isAdvocate)
              _buildResponsiveButton(
                icon: Icons.add,
                label: "Add New Stage",
                color: Colors.green,
                onPressed: () => _showCaseTrackingBottomSheet(null),
              ),
          ],
        ),
      ),
    );
  }

  void _showCaseTrackingBottomSheet(CaseTrackingStage? existing) {
    final isUpdate = existing != null;
    bool isVisible = existing?.visibility ?? true;
    String? selectedStage = existing?.caseStage;

    DateTime selectedDateTime = existing?.trackingTime != null
        ? (DateTime.tryParse(existing!.trackingTime!) ?? DateTime.now())
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (pickedDate != null && context.mounted) {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(selectedDateTime),
                          );

                          if (pickedTime != null && context.mounted) {
                            setModalState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(selectedDateTime),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isVisible ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Visibility",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    isVisible
                                        ? "Visible to clients"
                                        : "Hidden from clients",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isVisible
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: isVisible,
                            onChanged: (value) {
                              setModalState(() {
                                isVisible = value;
                              });
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                            activeTrackColor: Colors.green.shade200,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      isUpdate
                          ? "Update Timeline Stage"
                          : "Add New Timeline Stage",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: selectedStage,
                      decoration: const InputDecoration(
                        labelText: "Select Stage",
                        border: OutlineInputBorder(),
                      ),
                      items: CASE_STAGES.CaseStages()
                          .allCasePaymentStages
                          .map(
                            (stage) => DropdownMenuItem<String>(
                              value: stage,
                              child: Text(_prettyStageName(stage)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() => selectedStage = value);
                      },
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: _isUpdatingCaseTracking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isUpdatingCaseTracking
                            ? "Saving..."
                            : (isUpdate ? "Update" : "Save"),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: (_isUpdatingCaseTracking ||
                              selectedStage == null)
                          ? null
                          : () async {
                              setModalState(
                                () => _isUpdatingCaseTracking = true,
                              );

                              try {
                                await _showLoadingDialog(
                                  loadingMessage: "Saving stage...",
                                  task: () async {
                                    final success = isUpdate
                                        ? await _updateCaseTracking(
                                            existing!.id!,
                                            selectedStage!,
                                            selectedDateTime,
                                            isVisible,
                                          )
                                        : await _addCaseTracking(
                                            selectedStage!,
                                            selectedDateTime,
                                            isVisible,
                                          );

                                    if (!success) {
                                      throw Exception(
                                          "Failed to save stage...");
                                    }
                                  },
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isUpdate
                                            ? "✓ Timeline stage updated"
                                            : "✓ New timeline stage added",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("✗ Error: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(
                                  () => _isUpdatingCaseTracking = false,
                                );
                              }
                            },
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

  Widget _caseTrackingTile(CaseTrackingStage ct) {
    final isAdvocate = presentUsersAdvocateId != null &&
        presentUsersAdvocateId == widget.advocateId;
    final index = caseTrackings.indexOf(ct);
    final canUp = index > 0;
    final canDown = index < caseTrackings.length - 1;
    final currentPayment = stagePayments[ct.caseStage];
    final currentPrice = currentPayment?.price ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 480;
    final isVerySmall = screenWidth < 380;

    final double titleSize =
        isVerySmall ? 12.0 : (isSmallMobile ? 13.0 : 14.0);
    final double subtitleSize =
        isVerySmall ? 10.0 : (isSmallMobile ? 11.0 : 12.0);

    String stageName = _prettyStageName(ct.caseStage);
    if (isSmallMobile && stageName.length > 28) {
      stageName = stageName.substring(0, 25) + '...';
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isVerySmall ? 8 : 10),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isVerySmall ? 8 : 10,
          horizontal: isVerySmall ? 10 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.timeline,
              color: Colors.deepPurple,
              size: isVerySmall ? 16 : 18,
            ),
            SizedBox(width: isVerySmall ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stageName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: titleSize,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  SizedBox(height: isVerySmall ? 2 : 4),
                  Text(
                    "Stage #${ct.stageNumber}",
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (ct.trackingTime != null &&
                      (ct.visibility == null || ct.visibility == true))
                    Text(
                      "${ct.trackingTime}",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: subtitleSize,
                      ),
                    ),
                ],
              ),
            ),
            if (!isAdvocate && currentPrice > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmall ? 4 : 6,
                  vertical: isVerySmall ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "৳${currentPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: subtitleSize - 1,
                  ),
                ),
              ),
            if (isAdvocate)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentPrice > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 4 : 6,
                        vertical: isVerySmall ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "৳${currentPrice.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: subtitleSize - 1,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 4 : 6,
                        vertical: isVerySmall ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Set",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                          fontSize: subtitleSize - 1,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.green,
                      size: isVerySmall ? 16 : 18,
                    ),
                    onPressed: () => _showPriceEditDialog(
                      stageName,
                      ct.caseStage,
                      currentPayment == null,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isVerySmall ? 28 : 32,
                      minHeight: isVerySmall ? 28 : 32,
                    ),
                    splashRadius: 16,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: isVerySmall ? 16 : 18),
                    onSelected: (v) async {
                      if (v == "edit") {
                        _showCaseTrackingBottomSheet(ct);
                      } else if (v == "delete") {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              "Delete Stage",
                              style: TextStyle(fontSize: titleSize + 2),
                            ),
                            content: Text(
                              "Delete \"$stageName\"?",
                              style: TextStyle(fontSize: subtitleSize),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(fontSize: subtitleSize),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Delete",
                                  style: TextStyle(fontSize: subtitleSize),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        await _showLoadingDialog(
                          loadingMessage: "Deleting stage...",
                          task: () async {
                            final ok = await _deleteCaseTracking(ct.id!);
                            if (!ok) {
                              throw Exception("Failed to delete stage");
                            }
                          },
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✓ Stage deleted"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else if (v == "up" && canUp) {
                        await _showLoadingDialog(
                          loadingMessage: "Moving stage up...",
                          task: () async {
                            await _swapCaseTrackings(
                              caseTrackings[index - 1].id!,
                              ct.id!,
                            );
                          },
                        );
                      } else if (v == "down" && canDown) {
                        await _showLoadingDialog(
                          loadingMessage: "Moving stage down...",
                          task: () async {
                            await _swapCaseTrackings(
                              ct.id!,
                              caseTrackings[index + 1].id!,
                            );
                          },
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: "edit", child: Text("Edit")),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                      if (canUp)
                        const PopupMenuItem(
                          value: "up",
                          child: Text("Move Up"),
                        ),
                      if (canDown)
                        const PopupMenuItem(
                          value: "down",
                          child: Text("Move Down"),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}