// lib/Trademark/models/trademark_registration_process_model.dart

import 'trademark_model.dart';

class TrademarkRegistrationProcessModel {
  String? id;
  String userId;
  String advocateId;
  String tradeMarkId;
  bool status;
  List<String> steps;

  TrademarkRegistrationProcessModel({
    this.id,
    required this.userId,
    required this.advocateId,
    required this.tradeMarkId,
    this.status = false,
    List<String>? steps,
  }) : steps = steps ?? [];

  factory TrademarkRegistrationProcessModel.fromJson(
      Map<String, dynamic> json) {
    return TrademarkRegistrationProcessModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      advocateId: json['advocateId'] ?? '',
      tradeMarkId: json['tradeMarkId'] ?? '',
      status: json['status'] ?? false,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'advocateId': advocateId,
        'tradeMarkId': tradeMarkId,
        'status': status,
        'steps': steps,
      };
}

/// Response DTO (with names + nested Trademark)
class TrademarkRegistrationProcessResponse {
  String? id;
  String centerAdminUserId;
  String centerAdminUserName;
  String advocateId;
  String advocateName;
  String tradeMarkId;
  TrademarkModel? tradeMark;
  bool status;
  List<String> steps;

  TrademarkRegistrationProcessResponse({
    this.id,
    this.centerAdminUserId = '',
    this.centerAdminUserName = '',
    this.advocateId = '',
    this.advocateName = '',
    this.tradeMarkId = '',
    this.tradeMark,
    this.status = false,
    List<String>? steps,
  }) : steps = steps ?? [];

  factory TrademarkRegistrationProcessResponse.fromJson(
      Map<String, dynamic> json) {
    return TrademarkRegistrationProcessResponse(
      id: json['id'],
      centerAdminUserId: json['centerAdminUserId'] ?? '',
      centerAdminUserName: json['centerAdminUserName'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      tradeMarkId: json['tradeMarkId'] ?? '',
      tradeMark: json['tradeMark'] != null
          ? TrademarkModel.fromJson(
              Map<String, dynamic>.from(json['tradeMark']))
          : null,
      status: json['status'] ?? false,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
    );
  }
}