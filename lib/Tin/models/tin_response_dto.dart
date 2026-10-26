// lib/Tin/models/tin_response_dto.dart

import 'tin_model.dart';
import 'tin_registration_process_model.dart';

class TinResponseDTO {
  String? id;
  String userId;
  String userName;
  String fullName;
  String fatherName;
  String motherName;
  String phone;
  DateTime dateOfBirth;
  String presentAdress;
  String permanentAdress;
  List<String> documents;
  TinRegistrationProcessDTO? registrationProcess;

  TinResponseDTO({
    this.id,
    this.userId = '',
    this.userName = '',
    this.fullName = '',
    this.fatherName = '',
    this.motherName = '',
    this.phone = '',
    DateTime? dateOfBirth,
    this.presentAdress = '',
    this.permanentAdress = '',
    List<String>? documents,
    this.registrationProcess,
  })  : dateOfBirth = dateOfBirth ?? DateTime.now(),
        documents = documents ?? [];

  factory TinResponseDTO.fromJson(Map<String, dynamic> json) {
    return TinResponseDTO(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      fullName: json['fullName'] ?? '',
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'].toString())
          : DateTime.now(),
      presentAdress: json['presentAdress'] ?? '',
      permanentAdress: json['permanentAdress'] ?? '',
      documents:
          json['documents'] != null ? List<String>.from(json['documents']) : [],
      registrationProcess: json['registrationProcess'] != null
          ? TinRegistrationProcessDTO.fromJson(
              Map<String, dynamic>.from(json['registrationProcess']))
          : null,
    );
  }
}