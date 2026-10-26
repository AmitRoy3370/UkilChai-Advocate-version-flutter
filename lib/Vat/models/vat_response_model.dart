// lib/vat/models/vat_response_model.dart

import 'vat_model.dart';
import 'vat_registration_process_model.dart';


/// Mirrors: com.example.demo700.DTOFiles.VatRegistrationProcessResponseDTO
class VatRegistrationProcessResponseModel {
  final String? id;
  final String vatId;
  final String userId;
  final String userName;
  final String advocateId;
  final String advocateName;
  final bool status;
  final List<String> steps;

  /// Nested raw `Vat` entity (mirrors `Vat vat` in the Java DTO)
  final VatModel? vat;

  VatRegistrationProcessResponseModel({
    this.id,
    required this.vatId,
    required this.userId,
    required this.userName,
    required this.advocateId,
    required this.advocateName,
    required this.status,
    required this.steps,
    this.vat,
  });

  factory VatRegistrationProcessResponseModel.fromJson(
      Map<String, dynamic> json) {
    return VatRegistrationProcessResponseModel(
      id: json['id'] as String?,
      vatId: json['vatId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      advocateId: json['advocateId'] as String? ?? '',
      advocateName: json['advocateName'] as String? ?? '',
      status: json['status'] as bool? ?? false,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vat: json['vat'] != null
          ? VatModel.fromJson(json['vat'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vatId': vatId,
      'userId': userId,
      'userName': userName,
      'advocateId': advocateId,
      'advocateName': advocateName,
      'status': status,
      'steps': steps,
      if (vat != null) 'vat': vat!.toJson(),
    };
  }

  @override
  String toString() {
    return 'VatRegistrationProcessResponseModel(id: $id, vatId: $vatId, '
        'userId: $userId, userName: $userName, advocateId: $advocateId, '
        'advocateName: $advocateName, status: $status, steps: $steps, vat: $vat)';
  }
}

/// Mirrors: com.example.demo700.DTOFiles.VatResponseDTO
class VatResponseModel {
  final String? id;
  final String userId;
  final String userName;
  final String adress;
  final String tinNo;
  final String buisnessName;
  final String tradeLicenseNo;
  final String annualTurnOver;
  final String mainProduct;
  final String natureOfBuisness;
  final int numberOfBuisness;
  final int numberOfEmployee;
  final List<String> documents;
  final VatRegistrationProcessResponseModel? vatRegistrationProcessResponseDTO;

  VatResponseModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.adress,
    required this.tinNo,
    required this.buisnessName,
    required this.tradeLicenseNo,
    required this.annualTurnOver,
    required this.mainProduct,
    required this.natureOfBuisness,
    required this.numberOfBuisness,
    required this.numberOfEmployee,
    required this.documents,
    this.vatRegistrationProcessResponseDTO,
  });

  factory VatResponseModel.fromJson(Map<String, dynamic> json) {
    return VatResponseModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      adress: json['adress'] as String? ?? '',
      tinNo: json['tinNo'] as String? ?? '',
      buisnessName: json['buisnessName'] as String? ?? '',
      tradeLicenseNo: json['tradeLicenseNo'] as String? ?? '',
      annualTurnOver: json['annualTurnOver'] as String? ?? '',
      mainProduct: json['mainProduct'] as String? ?? '',
      natureOfBuisness: json['natureOfBuisness'] as String? ?? '',
      numberOfBuisness: (json['numberOfBuisness'] as num?)?.toInt() ?? 0,
      numberOfEmployee: (json['numberOfEmployee'] as num?)?.toInt() ?? 0,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vatRegistrationProcessResponseDTO:
          json['vatRegistrationProcessResponseDTO'] != null
              ? VatRegistrationProcessResponseModel.fromJson(
                  json['vatRegistrationProcessResponseDTO']
                      as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userName': userName,
      'adress': adress,
      'tinNo': tinNo,
      'buisnessName': buisnessName,
      'tradeLicenseNo': tradeLicenseNo,
      'annualTurnOver': annualTurnOver,
      'mainProduct': mainProduct,
      'natureOfBuisness': natureOfBuisness,
      'numberOfBuisness': numberOfBuisness,
      'numberOfEmployee': numberOfEmployee,
      'documents': documents,
      if (vatRegistrationProcessResponseDTO != null)
        'vatRegistrationProcessResponseDTO':
            vatRegistrationProcessResponseDTO!.toJson(),
    };
  }

// Inside class VatResponseModel

VatModel toVatModel() {
  return VatModel(
    id: id,
    userId: userId,
    adress: adress,
    tinNo: tinNo,
    buisnessName: buisnessName,
    tradeLicenseNo: tradeLicenseNo,
    annualTurnOver: annualTurnOver,
    mainProduct: mainProduct,
    natureOfBuisness: natureOfBuisness,
    numberOfBuisness: numberOfBuisness,
    numberOfEmployee: numberOfEmployee,
    documents: List<String>.from(documents),
  );
}

  @override
  String toString() {
    return 'VatResponseModel(id: $id, userId: $userId, userName: $userName, '
        'adress: $adress, tinNo: $tinNo, buisnessName: $buisnessName, '
        'tradeLicenseNo: $tradeLicenseNo, annualTurnOver: $annualTurnOver, '
        'mainProduct: $mainProduct, natureOfBuisness: $natureOfBuisness, '
        'numberOfBuisness: $numberOfBuisness, numberOfEmployee: $numberOfEmployee, '
        'documents: $documents, '
        'vatRegistrationProcessResponseDTO: $vatRegistrationProcessResponseDTO)';
  }
}