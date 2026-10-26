// lib/CompanyPages/registration_process.dart
class RegistrationProcess {
  String? id;
  String companyId;
  String advocateId;
  String userId;
  bool status;
  double shareValuePerShare;
  List<String> steps;

  RegistrationProcess({
    this.id,
    required this.companyId,
    required this.advocateId,
    required this.userId,
    required this.status,
    required this.shareValuePerShare,
    this.steps = const [],
  });

  factory RegistrationProcess.fromJson(Map<String, dynamic> json) {
    return RegistrationProcess(
      id: json['id'],
      companyId: json['companyId'] ?? '',
      advocateId: json['advocateId'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? false,
      shareValuePerShare: (json['shareValuePerShare'] ?? 0).toDouble(),
      steps: json['steps'] != null
          ? List<String>.from(json['steps'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'advocateId': advocateId,
      'userId': userId,
      'status': status,
      'shareValuePerShare': shareValuePerShare,
      'steps': steps,
    };
  }
}