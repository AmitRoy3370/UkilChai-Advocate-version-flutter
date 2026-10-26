// HearingModel.dart

import 'case_model.dart';

class HearingResponse {
  final String id;
  final String caseId;
  final int hearingNumber;
  final DateTime issuedDate;
  final List<String> attachmentsId;
  final CaseModel? hearingCase;

  HearingResponse({
    required this.id,
    required this.caseId,
    required this.hearingNumber,
    required this.issuedDate,
    required this.attachmentsId,
    this.hearingCase,
  });

  factory HearingResponse.fromJson(Map<String, dynamic> json) {
    return HearingResponse(
      id: (json['id'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      hearingNumber: (json['hearningNumber'] ?? 0) as int,
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'].toString())
          : DateTime.now(),
      attachmentsId: (json['attachmentsId'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      hearingCase: json['hearingCase'] != null
          ? CaseModel.fromJson(json['hearingCase'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'hearningNumber': hearingNumber,
        'issuedDate': issuedDate.toUtc().toIso8601String(),
        'attachmentsId': attachmentsId,
        'hearingCase': hearingCase?.toJson(),
      };
}

/// Simple model used when sending add/update requests
class Hearing {
  final String id;
  final String caseId;
  final int hearingNumber;
  final DateTime issuedDate;
  final List<String> attachmentsId;

  Hearing({
    required this.id,
    required this.caseId,
    required this.hearingNumber,
    required this.issuedDate,
    required this.attachmentsId,
  });

  factory Hearing.fromJson(Map<String, dynamic> json) {
    return Hearing(
      id: (json['id'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      hearingNumber: (json['hearningNumber'] ?? 0) as int,
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'].toString())
          : DateTime.now(),
      attachmentsId: (json['attachmentsId'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
    );
  }
}