// lib/ShareholderPages/shareholder_response.dart
import '../CompanyPages/company_information.dart';

class ShareholderResponse {
  String? id;
  String userId;
  String userName;
  String? fullName;
  String? profileImageId;
  String? contactInfoId;
  String? email;
  String? phone;
  String? locationId;
  String? locationName;
  double? latitude;
  double? longitude;
  String? nid;
  String? tin;
  List<CompanyInformation> companies;
  Map<String, List<double>> sharePercentage;
  Map<String, List<double>> sharePercentageWithCompanyName;

  ShareholderResponse({
    this.id,
    required this.userId,
    required this.userName,
    this.profileImageId,
    this.contactInfoId,
    this.email,
    this.phone,
    this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
    this.nid,
    this.tin,
    this.companies = const [],
    this.sharePercentage = const {},
    this.sharePercentageWithCompanyName = const {},
    this.fullName,
  });

  factory ShareholderResponse.fromJson(Map<String, dynamic> json) {
    return ShareholderResponse(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      profileImageId: json['profileImageId'],
      contactInfoId: json['contactInfoId'],
      email: json['email'],
      phone: json['phone'],
      locationId: json['locationId'],
      locationName: json['locationName'],
      latitude: json['lattitude']?.toDouble(),
      longitude: json['longititude']?.toDouble(),
      nid: json['nid'],
      tin: json['tin'],
      companies: json['companies'] != null
          ? (json['companies'] as List)
              .map((e) => CompanyInformation.fromJson(e))
              .toList()
          : [],
      sharePercentage: json['sharePercentage'] != null
          ? Map<String, List<double>>.from(
              json['sharePercentage'].map((key, value) =>
                  MapEntry(key, List<double>.from(value))))
          : {},
      sharePercentageWithCompanyName: json['sharePercentageWithCompanyName'] != null
          ? Map<String, List<double>>.from(
              json['sharePercentageWithCompanyName'].map((key, value) =>
                  MapEntry(key, List<double>.from(value))))
          : {},
      fullName: json['fullName'],
    );
  }
}