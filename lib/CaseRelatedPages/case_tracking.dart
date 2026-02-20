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
      // ---------- HEARINGS ----------
      hearings = await HearingService.getByCase(widget.token!, widget.caseId!);
    } catch (e) {}

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

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
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
                      const SizedBox(height: 16),
                      _advocateRatingCard(),
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
                      _hearingCard(),
                      const SizedBox(height: 16),
                      _caseCloseButton(),
                      const SizedBox(height: 16),

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

          // PRICE ON RIGHT
          if (step.price != null)
            Text(
              "৳${step.price}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  // ================= HEARING CARD =================
  Widget _hearingCard() {
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
          ],
        ),
      ),
    );
  }

  Widget _hearingTile(Hearing hearing) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.gavel),
        title: Text("Hearing #${hearing.hearingNumber}"),
        subtitle: Text("Date: ${_formatDate(hearing.issuedDate)}"),
        trailing: hearing.attachmentsId.isNotEmpty
            ? Text(
                "${hearing.attachmentsId.length} files",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
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
          leading: const Icon(Icons.description, color: Colors.orange),
          title: const Text("Document Draft"),
          subtitle: Text("Issued: ${_formatDate(draft.issuedDate)}"),
          trailing: draft.attachmentsId.isEmpty
              ? null
              : Text(
                  "${draft.attachmentsId.length} files",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.orange),
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
        onTap: () {
          print(
            "case judgment attachment id :- ${caseJudgment.judgmentAttachmentId}",
          );

          if (caseJudgment.judgmentAttachmentId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CaseJudgmentAttachmentView(
                  attachmentId: caseJudgment.judgmentAttachmentId!,
                  jwtToken: widget.token!,
                ),
              ),
            );

            CaseJudgmentAttachmentView(
              attachmentId: caseJudgment.judgmentAttachmentId!,
              jwtToken: widget.token!,
            );
          }
        },
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
