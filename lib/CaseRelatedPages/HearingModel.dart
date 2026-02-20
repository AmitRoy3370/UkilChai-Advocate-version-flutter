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
      id: json['id'],
      caseId: json['caseId'],
      hearingNumber: json['hearningNumber'],
      issuedDate: DateTime.parse(json['issuedDate']),
      attachmentsId:
      (json['attachmentsId'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}
