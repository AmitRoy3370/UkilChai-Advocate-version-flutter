class AdvocateDetailsModel {
  String? id;
  String? contactInfoId;
  String? locationId;

  String? userId;
  String? name;
  String? profileImageId;

  List<String> advocateSpeciality;

  int? experience;

  String? licenseKey;
  String? cvHexKey;

  List<String> degrees;
  List<String> workingExperiences;

  String? email;
  String? phone;

  String? locationName;

  double? lattitude;
  double? longitude;

  AdvocateDetailsModel(
      this.id,
      this.contactInfoId,
      this.locationId,
      this.userId,
      this.name,
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
      );

  AdvocateDetailsModel.defaultConstructor()
      : advocateSpeciality = [],
        degrees = [],
        workingExperiences = [];

  // 🔥 FROM JSON
  factory AdvocateDetailsModel.fromJson(Map<String, dynamic> json) {
    return AdvocateDetailsModel(
      json['id']?.toString() ?? json['_id']?.toString(),
      json['contactInfoId']?.toString(),
      json['locationId']?.toString(),
      json['userId']?.toString(),
      json['name']?.toString(),
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
          ? List<String>.from(
          json['workingExperiences'].map((e) => e.toString()))
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
    );
  }
}