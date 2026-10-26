import 'case_model.dart'; // Import your existing CaseModel

class CaseTrackingStage {
  final String? id;
  final String caseId;
  final String caseStage; // Maps to CasePayment enum
  final String? trackingTime; // ISO 8601 String
  final int stageNumber;
  final bool visibility;
  final CaseModel? trackingCase; // The nested Case object

  CaseTrackingStage({
    this.id,
    required this.caseId,
    required this.caseStage,
    this.trackingTime,
    this.stageNumber = 1,
    this.visibility = false,
    this.trackingCase,
  });

  factory CaseTrackingStage.fromJson(Map<String, dynamic> json) {
    return CaseTrackingStage(
      id: json['id']?.toString(),
      caseId: json['caseId']?.toString() ?? '',
      caseStage: json['caseStage']?.toString() ?? '',
      trackingTime: json['trackingTime']?.toString(),
      stageNumber: (json['stageNumber'] ?? 1).toInt(),
      visibility: json['visibility'] ?? false,
      trackingCase: json['trackingCase'] != null 
          ? CaseModel.fromJson(json['trackingCase']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'caseId': caseId,
      'caseStage': caseStage,
      if (trackingTime != null) 'trackingTime': trackingTime,
      'stageNumber': stageNumber,
      'visibility': visibility,
    };
  }

  // Helper to format the enum name nicely for the UI
  String get prettyStageName {
    String name = caseStage.replaceAll("CASE_", "").replaceAll("_PAYMENT", "");
    return name
        .split("_")
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : "")
        .join(" ");
  }
}