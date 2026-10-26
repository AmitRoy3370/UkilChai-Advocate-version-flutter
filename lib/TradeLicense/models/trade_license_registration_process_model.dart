// lib/TradeLicense/models/trade_license_registration_process_model.dart

import 'trade_license_model.dart';

class TradeLicenseRegistrationProcessModel {
  String? id;
  String userId;
  String advocateId;
  bool status;
  String tradeLicenseId;
  List<String> steps;

  TradeLicenseRegistrationProcessModel({
    this.id,
    required this.userId,
    required this.advocateId,
    this.status = false,
    required this.tradeLicenseId,
    List<String>? steps,
  }) : steps = steps ?? [];

  factory TradeLicenseRegistrationProcessModel.fromJson(
      Map<String, dynamic> json) {
    return TradeLicenseRegistrationProcessModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      advocateId: json['advocateId'] ?? '',
      status: json['status'] ?? false,
      tradeLicenseId: json['tradeLicenseId'] ?? '',
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'advocateId': advocateId,
        'status': status,
        'tradeLicenseId': tradeLicenseId,
        'steps': steps,
      };
}

/// Response DTO (with names + nested TradeLicense)
class TradeLicenseRegistrationProcessResponseDTO {
  String? id;
  String userId;
  String userName;
  String advocateId;
  String advocateName;
  String tradeLicenseId;
  TradeLicenseModel? tradeLicense;
  bool status;
  List<String> steps;

  TradeLicenseRegistrationProcessResponseDTO({
    this.id,
    this.userId = '',
    this.userName = '',
    this.advocateId = '',
    this.advocateName = '',
    this.tradeLicenseId = '',
    this.tradeLicense,
    this.status = false,
    List<String>? steps,
  }) : steps = steps ?? [];

  factory TradeLicenseRegistrationProcessResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return TradeLicenseRegistrationProcessResponseDTO(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      tradeLicenseId: json['tradeLicenseId'] ?? '',
      tradeLicense: json['tradeLicense'] != null
          ? TradeLicenseModel.fromJson(
              Map<String, dynamic>.from(json['tradeLicense']))
          : null,
      status: json['status'] ?? false,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }
}