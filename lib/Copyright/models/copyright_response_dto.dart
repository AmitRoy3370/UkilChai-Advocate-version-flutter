// lib/Copyright/models/copyright_response_dto.dart

import 'copyright_model.dart';
import 'copyright_registration_process_model.dart';

class CopyrightResponseDTO {
  String? id;
  String userId;
  String userName;
  String author;
  String typeOfWork;
  DateTime yearOfCreation;
  String titleOfWork;
  String description;
  String applicationName;
  String mobileNumber;
  String email;
  String adress;
  List<String> documents;
  CopyrightRegistrationProcessResponseDTO? registrationProcess;

  CopyrightResponseDTO({
    this.id,
    this.userId = '',
    this.userName = '',
    this.author = '',
    this.typeOfWork = '',
    DateTime? yearOfCreation,
    this.titleOfWork = '',
    this.description = '',
    this.applicationName = '',
    this.mobileNumber = '',
    this.email = '',
    this.adress = '',
    List<String>? documents,
    this.registrationProcess,
  })  : yearOfCreation = yearOfCreation ?? DateTime.now(),
        documents = documents ?? [];

  factory CopyrightResponseDTO.fromJson(Map<String, dynamic> json) {
    return CopyrightResponseDTO(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      author: json['author'] ?? '',
      typeOfWork: json['typeOfWork'] ?? '',
      yearOfCreation: json['yearOfCreation'] != null
          ? DateTime.parse(json['yearOfCreation'].toString())
          : DateTime.now(),
      titleOfWork: json['titleOfWork'] ?? '',
      description: json['description'] ?? '',
      applicationName: json['applicationName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      adress: json['adress'] ?? '',
      documents:
          json['documents'] != null ? List<String>.from(json['documents']) : [],
      registrationProcess: json['registrationProcess'] != null
          ? CopyrightRegistrationProcessResponseDTO.fromJson(
              Map<String, dynamic>.from(json['registrationProcess']))
          : null,
    );
  }
}