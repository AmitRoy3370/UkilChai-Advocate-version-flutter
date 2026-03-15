class ReadStatus {
  final String? id;
  final String caseId;
  final String advocateId;
  final String status;
  final DateTime issuedTime;

  ReadStatus({
    this.id,
    required this.caseId,
    required this.advocateId,
    required this.status,
    required this.issuedTime,
  });

  factory ReadStatus.fromJson(Map<String, dynamic> json) {
    return ReadStatus(
      id: json['id'] as String?,
      caseId: json['caseId'] as String,
      advocateId: json['advocateId'] as String,
      status: json['status'] as String,
      issuedTime: DateTime.parse(json['issuedTime'] as String),
    );
  }
}