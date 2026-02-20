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
      id: json['id'],
      advocateId: json['advocateId'],
      caseId: json['caseId'],
      issuedDate: DateTime.parse(json['issuedDate']),
      attachmentsId:
      List<String>.from(json['attachmentsId'] ?? []),
    );
  }
}
