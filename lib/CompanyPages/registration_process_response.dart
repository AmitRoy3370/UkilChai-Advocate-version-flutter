// lib/CompanyPages/registration_process_response.dart
class RegistrationProcessResponse {
  String? id;
  String companyId;
  String companyName;
  String advocateId;
  String advocateName;
  String userId;
  String userName;
  bool status;
  double shareValuePerShare;
  List<String> steps;

  RegistrationProcessResponse({
    this.id,
    required this.companyId,
    required this.companyName,
    required this.advocateId,
    required this.advocateName,
    required this.userId,
    required this.userName,
    required this.status,
    required this.shareValuePerShare,
    this.steps = const [],
  });

  factory RegistrationProcessResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationProcessResponse(
      id: json['id'],
      companyId: json['companyId'] ?? '',
      companyName: json['companyName'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      status: json['status'] ?? false,
      shareValuePerShare: (json['shareValuePerShare'] ?? 0).toDouble(),
      steps: json['steps'] != null
          ? List<String>.from(json['steps'])
          : [],
    );
  }
}