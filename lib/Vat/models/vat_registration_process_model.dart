// lib/vat/models/vat_registration_process_model.dart

class VatRegistrationProcessModel {
  final String? id;
  final String vatId;
  final String userId;
  final String advocateId;
  final bool status;
  final List<String> steps;

  VatRegistrationProcessModel({
    this.id,
    required this.vatId,
    required this.userId,
    required this.advocateId,
    this.status = false,
    this.steps = const [],
  });

  // ============ FROM JSON ============
  factory VatRegistrationProcessModel.fromJson(Map<String, dynamic> json) {
    return VatRegistrationProcessModel(
      id: json['id'] as String?,
      vatId: json['vatId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      advocateId: json['advocateId'] as String? ?? '',
      status: json['status'] as bool? ?? false,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // ============ TO JSON ============
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vatId': vatId,
      'userId': userId,
      'advocateId': advocateId,
      'status': status,
      'steps': steps,
    };
  }

  // ============ COPY WITH ============
  VatRegistrationProcessModel copyWith({
    String? id,
    String? vatId,
    String? userId,
    String? advocateId,
    bool? status,
    List<String>? steps,
  }) {
    return VatRegistrationProcessModel(
      id: id ?? this.id,
      vatId: vatId ?? this.vatId,
      userId: userId ?? this.userId,
      advocateId: advocateId ?? this.advocateId,
      status: status ?? this.status,
      steps: steps ?? this.steps,
    );
  }

  @override
  String toString() {
    return 'VatRegistrationProcessModel(id: $id, vatId: $vatId, userId: $userId, '
        'advocateId: $advocateId, status: $status, steps: $steps)';
  }
}