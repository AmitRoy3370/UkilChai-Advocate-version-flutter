// lib/Tin/models/tin_registration_process_model.dart

import 'tin_model.dart';

class TinRegistrationProcessModel {
  String? id;
  String centerAdminId;
  String advocateId;
  String tinId;
  List<String> steps;

  TinRegistrationProcessModel({
    this.id,
    required this.centerAdminId,
    required this.advocateId,
    required this.tinId,
    List<String>? steps,
  }) : steps = steps ?? [];

  factory TinRegistrationProcessModel.fromJson(Map<String, dynamic> json) {
    return TinRegistrationProcessModel(
      id: json['id'],
      centerAdminId: json['centerAdminId'] ?? '',
      advocateId: json['advocateId'] ?? '',
      tinId: json['tinId'] ?? '',
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'centerAdminId': centerAdminId,
        'advocateId': advocateId,
        'tinId': tinId,
        'steps': steps,
      };
}

/// Response DTO (with names + nested TIN)
class TinRegistrationProcessDTO {
  String? id;
  TinModel? tin;
  String requestedUserId;
  String requestedUserName;
  String advocateId;
  String advocateName;
  String centerAdminId;
  String centerAdminName;
  String tinId;
  List<String> steps;

  TinRegistrationProcessDTO({
    this.id,
    this.tin,
    this.requestedUserId = '',
    this.requestedUserName = '',
    this.advocateId = '',
    this.advocateName = '',
    this.centerAdminId = '',
    this.centerAdminName = '',
    this.tinId = '',
    List<String>? steps,
  }) : steps = steps ?? [];

  factory TinRegistrationProcessDTO.fromJson(Map<String, dynamic> json) {
    return TinRegistrationProcessDTO(
      id: json['id'],
      tin: json['tin'] != null
          ? TinModel.fromJson(Map<String, dynamic>.from(json['tin']))
          : null,
      requestedUserId: json['requestedUserId'] ?? '',
      requestedUserName: json['requestedUserName'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      centerAdminId: json['centerAdminId'] ?? '',
      centerAdminName: json['centerAdminName'] ?? '',
      tinId: json['tinId'] ?? '',
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }
}