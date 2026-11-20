// lib/RJSC/models/rjsc_registration_process_response_dto.dart
import 'rjsc_response_dto.dart'; // ← adjust if your RJSC model lives elsewhere

/// Mirrors backend: RJSCRegistrationProcessResponseDTO
class RjscRegistrationProcessResponseDTO {
  final String? id;
  final String userId;
  final String userName;
  final String advocateId;
  final String advocateName;
  final bool status;
  final List<String> steps;

  /// Embedded RJSC entity. Nullable — older records may not embed it.
  final RjscResponseDTO? rjsc;

  const RjscRegistrationProcessResponseDTO({
    this.id,
    required this.userId,
    required this.userName,
    required this.advocateId,
    required this.advocateName,
    required this.status,
    this.steps = const [],
    this.rjsc,
  });

  factory RjscRegistrationProcessResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return RjscRegistrationProcessResponseDTO(
      id: json['id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      advocateId: json['advocateId']?.toString() ?? '',
      advocateName: json['advocateName']?.toString() ?? '',
      status: json['status'] as bool? ?? false,
      steps: json['steps'] != null
          ? List<String>.from(json['steps'])
          : const [],
      rjsc: json['rjsc'] != null && json['rjsc'] is Map
          ? RjscResponseDTO.fromJson(
              Map<String, dynamic>.from(json['rjsc'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'userId': userId,
        'userName': userName,
        'advocateId': advocateId,
        'advocateName': advocateName,
        'status': status,
        'steps': steps,
        if (rjsc != null) 'rjsc': rjsc!.toJson(),
      };

  String get rjscId => rjsc?.id ?? '';
  String get rjscCompanyName => rjsc?.companyName ?? '';
}