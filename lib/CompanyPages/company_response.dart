// lib/CompanyPages/company_response.dart
import 'package:flutter/material.dart';
import 'capital.dart';
import 'subscription.dart';
import 'registration_process.dart';

class CompanyResponse {
  final String? id;
  final String companyName;
  final String type;
  final String natureOfBusiness;
  final String category;
  final String? officeRegistryId;
  final List<String> shareHolders;
  final List<String> documents;
  final List<String> directorsId;
  final List<String?> shareHoldersName;
  final List<String?> directorsName;
  final String? authorized;
  final List<String> capital;
  final String? creatorId;
  final String? creatorName;
  final List<Capital> capitals;
  final List<Subscription> subscriptions;
  final RegistrationProcess? registrationProcess;

  CompanyResponse({
    this.id,
    required this.companyName,
    required this.type,
    required this.natureOfBusiness,
    required this.category,
    this.officeRegistryId,
    List<String>? shareHolders,
    List<String>? documents,
    List<String>? directorsId,
    List<String?>? shareHoldersName,
    List<String?>? directorsName,
    this.authorized,
    List<String>? capital,
    this.creatorId,
    this.creatorName,
    List<Capital>? capitals,
    List<Subscription>? subscriptions,
    this.registrationProcess,
  })  : shareHolders = shareHolders ?? [],
        documents = documents ?? [],
        directorsId = directorsId ?? [],
        shareHoldersName = shareHoldersName ?? [],
        directorsName = directorsName ?? [],
        capital = capital ?? [],
        capitals = capitals ?? [],
        subscriptions = subscriptions ?? [];

  factory CompanyResponse.fromJson(Map<String, dynamic> json) {
    // Safely handle registrationProcess
    RegistrationProcess? registrationProcess;
    if (json['registrationProcess'] != null) {
      if (json['registrationProcess'] is Map<String, dynamic>) {
        registrationProcess = RegistrationProcess.fromJson(
          json['registrationProcess'] as Map<String, dynamic>
        );
      } else if (json['registrationProcess'] is bool) {
        // Handle case where it might be a boolean
        registrationProcess = RegistrationProcess(
          companyId: json['companyId']?.toString() ?? '',
          advocateId: json['advocateId']?.toString() ?? '',
          userId: json['userId']?.toString() ?? '',
          status: json['registrationProcess'] as bool,
          shareValuePerShare: (json['shareValuePerShare'] as num?)?.toDouble() ?? 0.0,
          steps: json['steps'] != null
              ? List<String>.from(json['steps'])
              : [],
        );
        // Set id if available
        if (json['id'] != null) {
          registrationProcess.id = json['id'].toString();
        }
      }
    }

    // Handle shareHoldersName - properly handle null values
    List<String?> shareHoldersName = [];
    if (json['shareHoldersName'] != null) {
      final list = json['shareHoldersName'] as List;
      shareHoldersName = list.map((e) => e?.toString()).toList();
    }

    // Handle directorsName - properly handle null values
    List<String?> directorsName = [];
    if (json['directorsName'] != null) {
      final list = json['directorsName'] as List;
      directorsName = list.map((e) => e?.toString()).toList();
    }

    return CompanyResponse(
      id: json['id']?.toString(),
      companyName: json['companyName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      natureOfBusiness: json['natureOfBuisness']?.toString() ?? 
                       json['natureOfBusiness']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      officeRegistryId: json['officeRegistryId'] != null && 
                        json['officeRegistryId'].toString().isNotEmpty
          ? json['officeRegistryId'].toString()
          : null,
      shareHolders: json['shareHolders'] != null
          ? List<String>.from(json['shareHolders'])
          : [],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
      directorsId: json['directorsId'] != null
          ? List<String>.from(json['directorsId'])
          : [],
      shareHoldersName: shareHoldersName,
      directorsName: directorsName,
      authorized: json['authorized']?.toString(),
      capital: json['capital'] != null
          ? List<String>.from(json['capital'])
          : [],
      creatorId: json['creatorId']?.toString(),
      creatorName: json['creatorName']?.toString(),
      capitals: json['capitals'] != null
          ? (json['capitals'] as List)
              .map((e) => Capital.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      subscriptions: json['subscriptions'] != null
          ? (json['subscriptions'] as List)
              .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      registrationProcess: registrationProcess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'companyName': companyName,
      'type': type,
      'natureOfBuisness': natureOfBusiness,
      'category': category,
      if (officeRegistryId != null && officeRegistryId!.isNotEmpty)
        'officeRegistryId': officeRegistryId,
      if (shareHolders.isNotEmpty) 'shareHolders': shareHolders,
      if (documents.isNotEmpty) 'documents': documents,
      if (directorsId.isNotEmpty) 'directorsId': directorsId,
      if (shareHoldersName.isNotEmpty) 
        'shareHoldersName': shareHoldersName.map((e) => e?.toString()).toList(),
      if (directorsName.isNotEmpty) 
        'directorsName': directorsName.map((e) => e?.toString()).toList(),
      if (authorized != null && authorized!.isNotEmpty) 'authorized': authorized,
      if (capital.isNotEmpty) 'capital': capital,
      if (creatorId != null && creatorId!.isNotEmpty) 'creatorId': creatorId,
      if (creatorName != null && creatorName!.isNotEmpty) 'creatorName': creatorName,
      if (capitals.isNotEmpty) 
        'capitals': capitals.map((e) => e.toJson()).toList(),
      if (subscriptions.isNotEmpty) 
        'subscriptions': subscriptions.map((e) => e.toJson()).toList(),
      if (registrationProcess != null)
        'registrationProcess': registrationProcess!.toJson(),
    };
  }

  // ✅ Helper method to get formatted officeRegistryId
  String? get formattedOfficeRegistryId {
    if (officeRegistryId == null || officeRegistryId!.isEmpty) {
      return null;
    }
    // If the ID is long, show first 8 and last 4 characters
    if (officeRegistryId!.length > 12) {
      return '${officeRegistryId!.substring(0, 8)}...${officeRegistryId!.substring(officeRegistryId!.length - 4)}';
    }
    return officeRegistryId;
  }

  // ✅ Helper to check if company is fully registered
  bool get isFullyRegistered {
    return officeRegistryId != null && 
           officeRegistryId!.isNotEmpty && 
           registrationProcess?.status == true;
  }

  // ✅ Helper to get registration status text
  String get registrationStatusText {
    if (registrationProcess == null) {
      return 'Not Started';
    }
    return registrationProcess!.status ? 'Completed' : 'In Progress';
  }

  // ✅ Helper to get registration status color
  Color get registrationStatusColor {
    if (registrationProcess == null) {
      return Colors.grey;
    }
    return registrationProcess!.status ? Colors.green : Colors.orange;
  }

  // ✅ Helper to get registration steps
  List<String> get registrationSteps {
    return registrationProcess?.steps ?? [];
  }

  // ✅ Helper to check if a specific step is completed
  bool isStepCompleted(String step) {
    return registrationProcess?.steps.contains(step) ?? false;
  }

  @override
  String toString() {
    return 'CompanyResponse{'
        'id: $id, '
        'companyName: $companyName, '
        'type: $type, '
        'natureOfBusiness: $natureOfBusiness, '
        'category: $category, '
        'officeRegistryId: $officeRegistryId, '
        'shareHolders: $shareHolders, '
        'documents: $documents, '
        'directorsId: $directorsId, '
        'shareHoldersName: $shareHoldersName, '
        'directorsName: $directorsName, '
        'authorized: $authorized, '
        'capital: $capital, '
        'creatorId: $creatorId, '
        'creatorName: $creatorName, '
        'capitals: $capitals, '
        'subscriptions: $subscriptions, '
        'registrationProcess: $registrationProcess'
        '}';
  }
}