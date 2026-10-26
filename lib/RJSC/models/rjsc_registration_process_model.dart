// lib/RJSC/models/rjsc_registration_process_model.dart

import 'rjsc_model.dart';

class RjscRegistrationProcessModel {
  String? id;
  String userId;
  String advocateId;
  bool status;
  String rjscId;
  List<String> steps;

  RjscRegistrationProcessModel({
    this.id,
    required this.userId,
    required this.advocateId,
    this.status = false,
    required this.rjscId,
    List<String>? steps,
  }) : steps = steps ?? [];

  factory RjscRegistrationProcessModel.fromJson(Map<String, dynamic> json) {
    return RjscRegistrationProcessModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      advocateId: json['advocateId'] ?? '',
      status: json['status'] ?? false,
      rjscId: json['rjscId'] ?? '',
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'advocateId': advocateId,
        'status': status,
        'rjscId': rjscId,
        'steps': steps,
      };
}

// DTO returned from backend (includes names)
class RjscRegistrationProcessResponseDTO {
  String? id;
  String userId;
  String userName;
  String advocateId;
  String advocateName;
  bool status;
  List<String> steps;
  RjscModel? rjsc;

  RjscRegistrationProcessResponseDTO({
    this.id,
    this.userId = '',
    this.userName = '',
    this.advocateId = '',
    this.advocateName = '',
    this.status = false,
    List<String>? steps,
    this.rjsc,
  }) : steps = steps ?? [];

  factory RjscRegistrationProcessResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return RjscRegistrationProcessResponseDTO(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      status: json['status'] ?? false,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
      rjsc: json['rjsc'] != null
          ? RjscModel.fromJson(Map<String, dynamic>.from(json['rjsc']))
          : null,
    );
  }
}