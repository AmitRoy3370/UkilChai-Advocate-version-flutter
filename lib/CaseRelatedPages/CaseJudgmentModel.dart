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
      id: json['id'],
      caseId: json['caseId'],
      result: json['result'],
      date: DateTime.parse(json['date']),
      judgmentAttachmentId: json['judgmentAttachmentId'],
    );
  }
}
