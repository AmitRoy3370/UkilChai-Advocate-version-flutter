import '../Utils/AdvocateSpeciality.dart';

class CaseRequest {
  final String id;
  final String caseName;
  final AdvocateSpeciality caseType;
  final String userId, userName;
  final DateTime requestDate;
  final List<String> attachmentId;
  final String? requestedAdvocateId, requestAdvocateName; // new

  CaseRequest({
    required this.id,
    required this.caseName,
    required this.caseType,
    required this.userId,
    required this.userName,
    required this.requestDate,
    required this.attachmentId,
    this.requestedAdvocateId, // new
    this.requestAdvocateName, // new
  });

  factory CaseRequest.fromJson(Map<String, dynamic> json) {
    return CaseRequest(
      id: json['id']?.toString() ?? "",
      caseName: json['caseName'] ?? "",
      caseType: AdvocateSpecialityExt.fromApi(json['caseType'] ?? ""),
      userId: json['userId'] ?? "",
      userName: json['userName'] ?? "",
      attachmentId: List<String>.from(json['attachmentId'] ?? []),
      requestedAdvocateId: json['requestedAdvocateId'], // new
      requestAdvocateName: json['requestAdvocateName'], // new
      requestDate: json['issuedTime'] != null
          ? DateTime.parse(json['issuedTime'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "caseName": caseName,
    "caseType": caseType.apiValue,
    "userId": userId,
    if (requestedAdvocateId != null) "requestedAdvocateId": requestedAdvocateId,
  };
}
