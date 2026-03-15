class CaseTrackingStage {
  final String? id;
  final String caseId;
  final String caseStage;   // exact enum value
  final int stageNumber;

  CaseTrackingStage({
    this.id,
    required this.caseId,
    required this.caseStage,
    required this.stageNumber,
  });

  factory CaseTrackingStage.fromJson(Map<String, dynamic> json) {
    return CaseTrackingStage(
      id: json['id'],
      caseId: json['caseId'],
      caseStage: json['caseStage'],
      stageNumber: json['stageNumber'],
    );
  }
}