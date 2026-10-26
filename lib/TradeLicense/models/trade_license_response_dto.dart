// lib/TradeLicense/models/trade_license_response_dto.dart

import 'trade_license_model.dart';
import 'trade_license_registration_process_model.dart';

class TradeLicenseResponseDTO {
  String? id;
  String userId;
  String userName;
  String buisnessName;
  String mobileNumber;
  String emailAdress;
  String buisnessType;
  String buisnessCategory;
  List<String> documents;
  TradeLicenseRegistrationProcessResponseDTO? tradeLicenseRegistrationProcess;

  TradeLicenseResponseDTO({
    this.id,
    this.userId = '',
    this.userName = '',
    this.buisnessName = '',
    this.mobileNumber = '',
    this.emailAdress = '',
    this.buisnessType = '',
    this.buisnessCategory = '',
    List<String>? documents,
    this.tradeLicenseRegistrationProcess,
  }) : documents = documents ?? [];

  factory TradeLicenseResponseDTO.fromJson(Map<String, dynamic> json) {
    return TradeLicenseResponseDTO(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      buisnessName: json['buisnessName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      emailAdress: json['emailAdress'] ?? '',
      buisnessType: json['buisnessType'] ?? '',
      buisnessCategory: json['buisnessCategory'] ?? '',
      documents:
          json['documents'] != null ? List<String>.from(json['documents']) : [],
      tradeLicenseRegistrationProcess: json['tradeLicenseRegistrationProcess'] !=
              null
          ? TradeLicenseRegistrationProcessResponseDTO.fromJson(
              Map<String, dynamic>.from(
                  json['tradeLicenseRegistrationProcess']))
          : null,
    );
  }
}