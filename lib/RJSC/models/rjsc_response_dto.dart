// lib/RJSC/models/rjsc_response_dto.dart

import 'rjsc_model.dart';
import 'rjsc_registration_process_model.dart';

class RjscResponseDTO {
  String? id;
  String userId;
  String userName;
  String compilenceService;
  String registrationNo;
  String email;
  String companyName;
  DateTime year;
  List<String> documents;
  RjscRegistrationProcessResponseDTO? registrationProcess;

  RjscResponseDTO({
    this.id,
    this.userId = '',
    this.userName = '',
    this.compilenceService = '',
    this.registrationNo = '',
    this.email = '',
    this.companyName = '',
    DateTime? year,
    List<String>? documents,
    this.registrationProcess,
  })  : year = year ?? DateTime.now(),
        documents = documents ?? [];

  factory RjscResponseDTO.fromJson(Map<String, dynamic> json) {
    return RjscResponseDTO(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      compilenceService: json['compilenceService'] ?? '',
      registrationNo: json['registrationNo'] ?? '',
      email: json['email'] ?? '',
      companyName: json['companyName'] ?? '',
      year: json['year'] != null
          ? DateTime.parse(json['year'].toString())
          : DateTime.now(),
      documents:
          json['documents'] != null ? List<String>.from(json['documents']) : [],
      registrationProcess: json['registrationProcess'] != null
          ? RjscRegistrationProcessResponseDTO.fromJson(
              Map<String, dynamic>.from(json['registrationProcess']))
          : null,
    );
  }
}