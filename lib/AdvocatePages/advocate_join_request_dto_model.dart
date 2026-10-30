import 'advocate_working_experience_join_request_model.dart';
import 'advocate_documents_join_request_model.dart';
import 'advocate_additional_info_join_request_model.dart';

class AdvocateJoinRequestDTO {
  final String? id;
  final String? profileImageId;
  final String? userId;
  final String? userName;
  final String? fullName;
  final String? userContactInfoId;
  final String? phone;
  final String? email;
  final String? userLocationId;
  final String? locationName;
  final double lattitude;
  final double logitude;
  final List<String> advocateSpeciality;
  final int experience;
  final String? licenseKey;
  final String? district;
  final String? cvHexKey;
  final List<String> degrees;
  final List<String> workingExperiences;
  
  // Nested Objects
  final AdvocateWorkingExperienceJoinRequest? workingExperience;
  final AdvocateDocumentsJoinRequest? documents;
  final AdvocateAdditionalInfoJoinRequest? additionalInfo;

  AdvocateJoinRequestDTO({
    this.id,
    this.profileImageId,
    this.userId,
    this.userName,
    this.fullName,
    this.userContactInfoId,
    this.phone,
    this.email,
    this.userLocationId,
    this.locationName,
    this.lattitude = 0.0,
    this.logitude = 0.0,
    this.advocateSpeciality = const [],
    this.experience = 0,
    this.licenseKey,
    this.district,
    this.cvHexKey,
    this.degrees = const [],
    this.workingExperiences = const [],
    this.workingExperience,
    this.documents,
    this.additionalInfo,
  });

  factory AdvocateJoinRequestDTO.fromJson(Map<String, dynamic> json) {
    return AdvocateJoinRequestDTO(
      id: json['id'],
      profileImageId: json['profileImageId'],
      userId: json['userId'],
      userName: json['userName'],
      fullName: json['fullName'],
      userContactInfoId: json['userContactInfoId'],
      phone: json['phone'],
      email: json['email'],
      userLocationId: json['userLocationId'],
      locationName: json['locationName'],
      lattitude: (json['lattitude'] ?? 0.0).toDouble(),
      logitude: (json['logitude'] ?? 0.0).toDouble(), // Note: Backend spells it 'logitude'
      advocateSpeciality: json['advocateSpeciality'] != null 
          ? List<String>.from(json['advocateSpeciality']) 
          : [],
      experience: json['experience'] ?? 0,
      licenseKey: json['licenseKey'],
      district: json['district'],
      cvHexKey: json['cvHexKey'],
      degrees: json['degrees'] != null ? List<String>.from(json['degrees']) : [],
      workingExperiences: json['workingExperiences'] != null 
          ? List<String>.from(json['workingExperiences']) 
          : [],
      workingExperience: json['workingExperience'] != null
          ? AdvocateWorkingExperienceJoinRequest.fromJson(json['workingExperience'])
          : null,
      documents: json['documents'] != null
          ? AdvocateDocumentsJoinRequest.fromJson(json['documents'])
          : null,
      additionalInfo: json['additionalInfo'] != null
          ? AdvocateAdditionalInfoJoinRequest.fromJson(json['additionalInfo'])
          : null,
    );
  }
}