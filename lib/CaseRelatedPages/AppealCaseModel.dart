class AppealCase {
  final String id;
  final String caseId;
  final String reason;
  final DateTime appealDate;

  AppealCase({
    required this.id,
    required this.caseId,
    required this.reason,
    required this.appealDate,
  });

  factory AppealCase.fromJson(Map<String, dynamic> json) {
    return AppealCase(
      id: json['id'],
      caseId: json['caseId'],
      reason: json['reason'],
      appealDate: DateTime.parse(json['appealDate']),
    );
  }
}
