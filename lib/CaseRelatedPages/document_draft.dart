// document_draft.dart
import '../CaseRelatedPages/case_model.dart';

/// Simple model — used when constructing requests / returning raw draft.
class DocumentDraft {
  final String id;
  final String advocateId;
  final String caseId;
  final DateTime issuedDate;
  final List<String> attachmentsId;

  DocumentDraft({
    required this.id,
    required this.advocateId,
    required this.caseId,
    required this.issuedDate,
    required this.attachmentsId,
  });

  factory DocumentDraft.fromJson(Map<String, dynamic> json) {
    return DocumentDraft(
      id: (json['id'] ?? '').toString(),
      advocateId: (json['advocateId'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'].toString())
          : DateTime.now(),
      attachmentsId:
          List<String>.from(json['attachmentsId'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'advocateId': advocateId,
        'caseId': caseId,
        'issuedDate': issuedDate.toUtc().toIso8601String(),
        'attachmentsId': attachmentsId,
      };
}

/// Mirrors backend `DocumentDraftResponse` DTO.
/// GET endpoints (findById, findByAdvocate, findByCase, all, after, before)
/// return this shape — NOT the plain `DocumentDraft`.
class DocumentDraftResponse {
  final String id;
  final String advocateId;
  final String caseId;
  final DateTime issuedDate;
  final List<String> attachmentsId;
  final CaseModel? documentDraftedCase;

  DocumentDraftResponse({
    required this.id,
    required this.advocateId,
    required this.caseId,
    required this.issuedDate,
    required this.attachmentsId,
    this.documentDraftedCase,
  });

  factory DocumentDraftResponse.fromJson(Map<String, dynamic> json) {
    return DocumentDraftResponse(
      id: (json['id'] ?? '').toString(),
      advocateId: (json['advocateId'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'].toString())
          : DateTime.now(),
      attachmentsId:
          List<String>.from(json['attachmentsId'] ?? const []),
      documentDraftedCase: json['documentDraftedCase'] != null
          ? CaseModel.fromJson(
              json['documentDraftedCase'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'advocateId': advocateId,
        'caseId': caseId,
        'issuedDate': issuedDate.toUtc().toIso8601String(),
        'attachmentsId': attachmentsId,
        'documentDraftedCase': documentDraftedCase?.toJson(),
      };
}