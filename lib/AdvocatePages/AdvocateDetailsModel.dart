import '../RegistrationPage/gender.dart';

// Assuming you create these models based on our previous discussions
import 'advocate_working_experience_model.dart';
import 'advocate_documents_model.dart';
import 'advocate_additional_info_model.dart';

class AdvocateDetailsModel {
  String? id;
  String? contactInfoId;
  String? locationId;

  String? userId;
  String? userGenderId;
  Gender? gender;
  String? name;
  String? fullName;
  String? profileImageId;

  List<String> advocateSpeciality;

  int? experience;
  double rating; 

  String? licenseKey;
  String? cvHexKey;
  String? district;

  List<String> degrees;
  List<String> workingExperiences;

  String? email;
  String? phone;

  String? locationName;

  double? lattitude;
  double? longitude;

  // ✅ ADDED: Nested models from AdvocateResponse DTO
  dynamic workingExperience; 
  dynamic advocateDocuments;
  dynamic additionalInfo;

  AdvocateDetailsModel(
      this.id,
      this.contactInfoId,
      this.locationId,
      this.userId,
      this.name,
      this.fullName,
      this.profileImageId,
      this.advocateSpeciality,
      this.experience,
      this.licenseKey,
      this.cvHexKey,
      this.degrees,
      this.workingExperiences,
      this.email,
      this.phone,
      this.locationName,
      this.lattitude,
      this.longitude,
      this.district,
      this.rating,
      this.userGenderId,
      this.gender,
      this.workingExperience,
      this.advocateDocuments,
      this.additionalInfo,
      );

  AdvocateDetailsModel.defaultConstructor()
      : advocateSpeciality = [],
        degrees = [],
        workingExperiences = [],
        rating = 0.0;

  // 🔥 FROM JSON (Mapped exactly to AdvocateResponse)
  factory AdvocateDetailsModel.fromJson(Map<String, dynamic> json) {
    return AdvocateDetailsModel(
      json['id']?.toString() ?? json['_id']?.toString(),
      json['contactInfoId']?.toString(),
      json['locationId']?.toString(),
      json['userId']?.toString(),
      json['name']?.toString(),
      json['fullName']?.toString(),
      json['profileImageId']?.toString(),

      // ✅ Enum Set → List<String>
      json['advocateSpeciality'] != null
          ? List<String>.from(json['advocateSpeciality'].map((e) => e.toString()))
          : [],

      (json['experience'] ?? 0).toInt(),

      json['licenseKey']?.toString(),
      json['cvHexKey']?.toString(),

      // ✅ Arrays
      json['degrees'] != null
          ? List<String>.from(json['degrees'].map((e) => e.toString()))
          : [],

      json['workingExperiences'] != null
          ? List<String>.from(json['workingExperiences'].map((e) => e.toString()))
          : [],

      json['email']?.toString(),
      json['phone']?.toString(),

      json['locationName']?.toString(),
      
      json['lattitude'] != null
          ? double.tryParse(json['lattitude'].toString())
          : null,

      json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
          
      json['district'] != null ? json['district'].toString() : '',
      
      json['rating'] != null 
          ? double.tryParse(json['rating'].toString()) ?? 0.0 
          : 0.0,
          
      json['userGenderId']?.toString(),
      json['gender'] != null ? Gender.values.firstWhere((e) => e.toString().split('.').last == json['gender']) : null,

      // ✅ Nested Objects Mapping
      json['workingExperience'] != null 
          ? json['workingExperience'] 
          : null, // Replace with AdvocateWorkingExperience.fromJson(json['workingExperience']) if you import it
          
      json['advocateDocuments'] != null 
          ? json['advocateDocuments'] 
          : null, // Replace with AdvocateDocuments.fromJson(json['advocateDocuments'])
          
      json['additionalInfo'] != null 
          ? json['additionalInfo'] 
          : null, // Replace with AdvocateAdditionalInfo.fromJson(json['additionalInfo'])
    );
  }
}