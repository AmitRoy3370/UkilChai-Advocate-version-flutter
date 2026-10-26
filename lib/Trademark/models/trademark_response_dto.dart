// lib/Trademark/models/trademark_response_dto.dart

import 'trademark_model.dart';
import 'trademark_registration_process_model.dart';

class TrademarkResponse {
  String? id;
  String legalProtection;
  String nationWiseValidity;
  String applicationType;
  String applicationName;
  double governmentFee;
  String organaizationalName;
  String email;
  String mobileNumber;
  List<String> documents;
  String userId;
  String userName;
  String trademarkName;
  String trademarkType;
  String classOfGoods;
  String adress;
  TrademarkRegistrationProcessResponse? registrationProcess;

  TrademarkResponse({
    this.id,
    this.legalProtection = '',
    this.nationWiseValidity = '',
    this.applicationType = '',
    this.applicationName = '',
    this.governmentFee = 0.0,
    this.organaizationalName = '',
    this.email = '',
    this.mobileNumber = '',
    List<String>? documents,
    this.userId = '',
    this.userName = '',
    this.trademarkName = '',
    this.trademarkType = '',
    this.classOfGoods = '',
    this.adress = '',
    this.registrationProcess,
  }) : documents = documents ?? [];

  factory TrademarkResponse.fromJson(Map<String, dynamic> json) {
    return TrademarkResponse(
      id: json['id'],
      legalProtection: json['legalProtection'] ?? '',
      nationWiseValidity: json['nationWiseValidity'] ?? '',
      applicationType: json['applicationType'] ?? '',
      applicationName: json['applicationName'] ?? '',
      governmentFee: (json['governmentFee'] as num?)?.toDouble() ?? 0.0,
      organaizationalName: json['organaizationalName'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      documents:
          json['documents'] != null ? List<String>.from(json['documents']) : [],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      trademarkName: json['trademarkName'] ?? '',
      trademarkType: json['trademarkType'] ?? '',
      classOfGoods: json['classOfGoods'] ?? '',
      adress: json['adress'] ?? '',
      registrationProcess: json['registrationProcess'] != null
          ? TrademarkRegistrationProcessResponse.fromJson(
              Map<String, dynamic>.from(json['registrationProcess']))
          : null,
    );
  }
}