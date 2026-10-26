// lib/DirectorsPages/director_response.dart
import '../CompanyPages/company_information.dart';

class DirectorResponse {
  String? id;
  String userId;
  String userName;
  String? profileImageId;
  String? userContactInfoId;
  String? email;
  String? phone;
  String? locationId;
  String? locationName;
  double? latitude;
  double? longitude;
  String position;
  String? fullName;
  String? fatherName;
  String? motherName;
  String? nidNumber;
  String? mobileNumber;
  String? directorEmail;
  String? nid;
  List<CompanyInformation> companies;

  DirectorResponse({
    this.id,
    required this.userId,
    required this.userName,
    this.profileImageId,
    this.userContactInfoId,
    this.email,
    this.phone,
    this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.position,
    this.fullName,
    this.fatherName,
    this.motherName,
    this.nidNumber,
    this.mobileNumber,
    this.directorEmail,
    this.nid,
    this.companies = const [],
  });

  factory DirectorResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Parse all fields matching Java DTO
    return DirectorResponse(
      id: json['id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      profileImageId: json['profileImageId']?.toString(),
      userContactInfoId: json['userContactInfnfoId']?.toString() ?? 
                         json['userContactInfoId']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      locationId: json['locationId']?.toString(),
      locationName: json['locationName']?.toString(),
      latitude: json['lattitude']?.toDouble() ?? json['latitude']?.toDouble(),
      longitude: json['longititude']?.toDouble() ?? json['longitude']?.toDouble(),
      position: json['position']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      fatherName: json['fatherName']?.toString(),
      motherName: json['motherName']?.toString(),
      nidNumber: json['nidNumber']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      directorEmail: json['directorEmail']?.toString(),
      nid: json['nid']?.toString(),
      companies: json['companies'] != null
          ? (json['companies'] as List)
              .map((e) => CompanyInformation.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'userId': userId,
      'userName': userName,
      if (profileImageId != null && profileImageId!.isNotEmpty) 
        'profileImageId': profileImageId,
      if (userContactInfoId != null && userContactInfoId!.isNotEmpty) 
        'userContactInfnfoId': userContactInfoId,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (locationId != null && locationId!.isNotEmpty) 'locationId': locationId,
      if (locationName != null && locationName!.isNotEmpty) 
        'locationName': locationName,
      if (latitude != null) 'lattitude': latitude,
      if (longitude != null) 'longititude': longitude,
      'position': position,
      if (fullName != null && fullName!.isNotEmpty) 'fullName': fullName,
      if (fatherName != null && fatherName!.isNotEmpty) 'fatherName': fatherName,
      if (motherName != null && motherName!.isNotEmpty) 'motherName': motherName,
      if (nidNumber != null && nidNumber!.isNotEmpty) 'nidNumber': nidNumber,
      if (mobileNumber != null && mobileNumber!.isNotEmpty) 
        'mobileNumber': mobileNumber,
      if (directorEmail != null && directorEmail!.isNotEmpty) 
        'directorEmail': directorEmail,
      if (nid != null && nid!.isNotEmpty) 'nid': nid,
      if (companies.isNotEmpty) 
        'companies': companies.map((e) => e.toJson()).toList(),
    };
  }

  // ✅ Helper method to check if director has all required fields
  bool get isComplete {
    return userId.isNotEmpty &&
           userName.isNotEmpty &&
           position.isNotEmpty &&
           fullName != null &&
           fullName!.isNotEmpty &&
           mobileNumber != null &&
           mobileNumber!.isNotEmpty &&
           email != null &&
           email!.isNotEmpty;
  }

  // ✅ Helper method to get display name
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    if (userName.isNotEmpty) {
      return userName;
    }
    return 'Director';
  }

  // ✅ Helper method to get formatted mobile number
  String get formattedMobile {
    if (mobileNumber == null || mobileNumber!.isEmpty) {
      return phone ?? 'N/A';
    }
    return mobileNumber!;
  }

  // ✅ Helper method to get formatted email
  String get formattedEmail {
    if (directorEmail != null && directorEmail!.isNotEmpty) {
      return directorEmail!;
    }
    return email ?? 'N/A';
  }

  // ✅ Helper method to get full name with fallback
  String get fullNameOrUserName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return userName;
  }

  // ✅ Copy with method for updating
  DirectorResponse copyWith({
    String? id,
    String? userId,
    String? userName,
    String? profileImageId,
    String? userContactInfoId,
    String? email,
    String? phone,
    String? locationId,
    String? locationName,
    double? latitude,
    double? longitude,
    String? position,
    String? fullName,
    String? fatherName,
    String? motherName,
    String? nidNumber,
    String? mobileNumber,
    String? directorEmail,
    String? nid,
    List<CompanyInformation>? companies,
  }) {
    return DirectorResponse(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profileImageId: profileImageId ?? this.profileImageId,
      userContactInfoId: userContactInfoId ?? this.userContactInfoId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      position: position ?? this.position,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      nidNumber: nidNumber ?? this.nidNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      directorEmail: directorEmail ?? this.directorEmail,
      nid: nid ?? this.nid,
      companies: companies ?? this.companies,
    );
  }

  @override
  String toString() {
    return 'DirectorResponse{'
        'id: $id, '
        'userId: $userId, '
        'userName: $userName, '
        'profileImageId: $profileImageId, '
        'userContactInfoId: $userContactInfoId, '
        'email: $email, '
        'phone: $phone, '
        'locationId: $locationId, '
        'locationName: $locationName, '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'position: $position, '
        'fullName: $fullName, '
        'fatherName: $fatherName, '
        'motherName: $motherName, '
        'nidNumber: $nidNumber, '
        'mobileNumber: $mobileNumber, '
        'directorEmail: $directorEmail, '
        'nid: $nid, '
        'companies: $companies'
        '}';
  }
}