// lib/Copyright/models/copyright_registration_process_model.dart

import 'copyright_model.dart';

class CopyrightRegistrationProcessModel {
  String? id;
  String copyrightId;
  String userId;
  String advocateId;
  List<String> stpes; // ⚠️ backend-এ typo আছে, তাই "stpes" রাখলাম
  bool status;

  CopyrightRegistrationProcessModel({
    this.id,
    required this.copyrightId,
    required this.userId,
    required this.advocateId,
    List<String>? stpes,
    this.status = false,
  }) : stpes = stpes ?? [];

  factory CopyrightRegistrationProcessModel.fromJson(Map<String, dynamic> json) {
    return CopyrightRegistrationProcessModel(
      id: json['id'],
      copyrightId: json['copyrightId'] ?? '',
      userId: json['userId'] ?? '',
      advocateId: json['advocateId'] ?? '',
      stpes: json['stpes'] != null ? List<String>.from(json['stpes']) : [],
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'copyrightId': copyrightId,
        'userId': userId,
        'advocateId': advocateId,
        'stpes': stpes,
        'status': status,
      };
}

// DTO from backend (has names)
class CopyrightRegistrationProcessResponseDTO {
  String? id;
  String copyrightId;
  String userId;
  String userName;
  String advocateId;
  String advocateName;
  List<String> stpes;
  bool status;
  CopyrightModel? copyright;

  CopyrightRegistrationProcessResponseDTO({
    this.id,
    this.copyrightId = '',
    this.userId = '',
    this.userName = '',
    this.advocateId = '',
    this.advocateName = '',
    List<String>? stpes,
    this.status = false,
    this.copyright,
  }) : stpes = stpes ?? [];

  factory CopyrightRegistrationProcessResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return CopyrightRegistrationProcessResponseDTO(
      id: json['id'],
      copyrightId: json['copyrightId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      stpes: json['stpes'] != null ? List<String>.from(json['stpes']) : [],
      status: json['status'] ?? false,
      copyright: json['copyright'] != null
          ? CopyrightModel.fromJson(Map<String, dynamic>.from(json['copyright']))
          : null,
    );
  }
}