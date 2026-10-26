// lib/CaseRelatedPages/case_model.dart
class CaseModel {
  final String id;
  final String caseName;
  final String userId;
  final String userName;
  final String? userFullName;
  final String advocateId;
  final String advocateName;
  final String? advocateFullName;
  final String caseType;
  final List<String> attachmentsId;
  final String issuedTime;

  CaseModel({
    required this.id,
    required this.caseName,
    required this.userId,
    required this.userName,
    this.userFullName,
    required this.advocateId,
    required this.advocateName,
    this.advocateFullName,
    required this.caseType,
    required this.attachmentsId,
    required this.issuedTime,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: (json["id"] ?? '').toString(),
      caseName: (json["caseName"] ?? '').toString(),
      userId: (json["userId"] ?? '').toString(),
      userName: (json["userName"] ?? '').toString(),
      userFullName: json["userFullName"]?.toString(),
      advocateId: (json["advocateId"] ?? '').toString(),
      advocateName: (json["advocateName"] ?? '').toString(),
      advocateFullName: json["advocateFullName"]?.toString(),
      caseType: (json["caseType"] ?? '').toString(),
      attachmentsId: json["attachmentsId"] == null
          ? <String>[]
          : List<String>.from(json["attachmentsId"] as List),
      issuedTime: (json["issuedTime"] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "caseName": caseName,
        "userId": userId,
        "userName": userName,
        "userFullName": userFullName,
        "advocateId": advocateId,
        "advocateName": advocateName,
        "advocateFullName": advocateFullName,
        "caseType": caseType,
        "attachmentsId": attachmentsId,
        "issuedTime": issuedTime,
      };

  // Convenience for showing names in UI
  String get displayAdvocateName =>
      (advocateFullName?.isNotEmpty == true) ? advocateFullName! : advocateName;

  String get displayUserName =>
      (userFullName?.isNotEmpty == true) ? userFullName! : userName;
}

/// Mirrors backend `CaseListResponseDTO`.
class CasePageModel {
  final List<CaseModel> responses;
  final int page;
  final int size;
  final int totalElement;
  final String? nextPage;
  final String? previousPage;

  CasePageModel({
    required this.responses,
    required this.page,
    required this.size,
    required this.totalElement,
    this.nextPage,
    this.previousPage,
  });

  factory CasePageModel.fromJson(Map<String, dynamic> json) {
    final list = (json["responses"] as List? ?? const [])
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CasePageModel(
      responses: list,
      page: (json["page"] ?? 0) as int,
      size: (json["size"] ?? list.length) as int,
      totalElement: (json["totalElement"] ?? list.length) as int,
      nextPage: json["nextPage"]?.toString(),
      previousPage: json["previousPage"]?.toString(),
    );
  }

  bool get hasNext => nextPage != null && nextPage!.isNotEmpty;
  bool get hasPrevious => previousPage != null && previousPage!.isNotEmpty;
}