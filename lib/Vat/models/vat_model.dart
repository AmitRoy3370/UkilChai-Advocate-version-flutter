// lib/vat/models/vat_model.dart

class VatModel {
  final String? id;
  final String userId;
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

  VatModel({
    this.id,
    required this.userId,
    required this.adress,
    required this.tinNo,
    required this.buisnessName,
    required this.tradeLicenseNo,
    required this.annualTurnOver,
    required this.mainProduct,
    required this.natureOfBuisness,
    required this.numberOfBuisness,
    required this.numberOfEmployee,
    this.documents = const [],
  });

  // ============ FROM JSON ============
  factory VatModel.fromJson(Map<String, dynamic> json) {
    return VatModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
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
    );
  }

  // ============ TO JSON ============
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
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
    };
  }

  // ============ COPY WITH ============
  VatModel copyWith({
    String? id,
    String? userId,
    String? adress,
    String? tinNo,
    String? buisnessName,
    String? tradeLicenseNo,
    String? annualTurnOver,
    String? mainProduct,
    String? natureOfBuisness,
    int? numberOfBuisness,
    int? numberOfEmployee,
    List<String>? documents,
  }) {
    return VatModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adress: adress ?? this.adress,
      tinNo: tinNo ?? this.tinNo,
      buisnessName: buisnessName ?? this.buisnessName,
      tradeLicenseNo: tradeLicenseNo ?? this.tradeLicenseNo,
      annualTurnOver: annualTurnOver ?? this.annualTurnOver,
      mainProduct: mainProduct ?? this.mainProduct,
      natureOfBuisness: natureOfBuisness ?? this.natureOfBuisness,
      numberOfBuisness: numberOfBuisness ?? this.numberOfBuisness,
      numberOfEmployee: numberOfEmployee ?? this.numberOfEmployee,
      documents: documents ?? this.documents,
    );
  }

  @override
  String toString() {
    return 'VatModel(id: $id, userId: $userId, adress: $adress, tinNo: $tinNo, '
        'buisnessName: $buisnessName, tradeLicenseNo: $tradeLicenseNo, '
        'annualTurnOver: $annualTurnOver, mainProduct: $mainProduct, '
        'natureOfBuisness: $natureOfBuisness, numberOfBuisness: $numberOfBuisness, '
        'numberOfEmployee: $numberOfEmployee, documents: $documents)';
  }
}