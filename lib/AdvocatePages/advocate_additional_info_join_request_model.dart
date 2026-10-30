class AdvocateAdditionalInfoJoinRequest {
  final String? id;
  final String advocateId;
  final String? parmanentAdress;
  final String? cityOfUpozila;
  final String? nidNumber;
  final String? dateOfBirth; // ISO-8601 String for Instant
  final String? whatsAppNumber;

  AdvocateAdditionalInfoJoinRequest({
    this.id,
    required this.advocateId,
    this.parmanentAdress,
    this.cityOfUpozila,
    this.nidNumber,
    this.dateOfBirth,
    this.whatsAppNumber,
  });

  factory AdvocateAdditionalInfoJoinRequest.fromJson(Map<String, dynamic> json) {
    return AdvocateAdditionalInfoJoinRequest(
      id: json['id'],
      advocateId: json['advocateId'] ?? '',
      parmanentAdress: json['parmanentAdress'],
      cityOfUpozila: json['cityOfUpozila'],
      nidNumber: json['nidNumber'],
      dateOfBirth: json['dateOfBirth'],
      whatsAppNumber: json['whatsAppNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'advocateId': advocateId,
      if (parmanentAdress != null) 'parmanentAdress': parmanentAdress,
      if (cityOfUpozila != null) 'cityOfUpozila': cityOfUpozila,
      if (nidNumber != null) 'nidNumber': nidNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (whatsAppNumber != null) 'whatsAppNumber': whatsAppNumber,
    };
  }

  AdvocateAdditionalInfoJoinRequest copyWith({
    String? id,
    String? advocateId,
    String? parmanentAdress,
    String? cityOfUpozila,
    String? nidNumber,
    String? dateOfBirth,
    String? whatsAppNumber,
  }) {
    return AdvocateAdditionalInfoJoinRequest(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      parmanentAdress: parmanentAdress ?? this.parmanentAdress,
      cityOfUpozila: cityOfUpozila ?? this.cityOfUpozila,
      nidNumber: nidNumber ?? this.nidNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
    );
  }
}