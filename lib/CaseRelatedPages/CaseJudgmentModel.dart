// CaseJudgmentModel.dart
import '../CaseRelatedPages/case_model.dart';

/// Mirrors backend `CaseJudgment` entity — used for add/update responses.
class CaseJudgment {
  final String id;
  final String caseId;
  final String result;
  final DateTime date;
  final String? judgmentAttachmentId;

  CaseJudgment({
    required this.id,
    required this.caseId,
    required this.result,
    required this.date,
    this.judgmentAttachmentId,
  });

  factory CaseJudgment.fromJson(Map<String, dynamic> json) {
    return CaseJudgment(
      id: (json['id'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      result: (json['result'] ?? '').toString(),
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      judgmentAttachmentId: json['judgmentAttachmentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'result': result,
        'date': date.toUtc().toIso8601String(),
        'judgmentAttachmentId': judgmentAttachmentId,
      };
}

/// Mirrors backend `CaseJudgementResponse` DTO.
/// All GET endpoints return this shape (with nested `judgementCase`).
class CaseJudgmentResponse {
  final String id;
  final String caseId;
  final String result;
  final String? judgmentAttachmentId;
  final DateTime date;
  final CaseModel? judgementCase;

  CaseJudgmentResponse({
    required this.id,
    required this.caseId,
    required this.result,
    this.judgmentAttachmentId,
    required this.date,
    this.judgementCase,
  });

  factory CaseJudgmentResponse.fromJson(Map<String, dynamic> json) {
    return CaseJudgmentResponse(
      id: (json['id'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      result: (json['result'] ?? '').toString(),
      judgmentAttachmentId: json['judgmentAttachmentId']?.toString(),
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      judgementCase: json['judgementCase'] != null
          ? CaseModel.fromJson(json['judgementCase'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'result': result,
        'judgmentAttachmentId': judgmentAttachmentId,
        'date': date.toUtc().toIso8601String(),
        'judgementCase': judgementCase?.toJson(),
      };
}