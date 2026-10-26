// lib/TradeLicense/models/trade_license_model.dart

class TradeLicenseModel {
  String? id;
  String userId;
  String buisnessName;
  String mobileNumber;
  String emailAdress;
  String buisnessType;
  String buisnessCategory;
  List<String> documents;

  TradeLicenseModel({
    this.id,
    required this.userId,
    required this.buisnessName,
    required this.mobileNumber,
    required this.emailAdress,
    required this.buisnessType,
    required this.buisnessCategory,
    List<String>? documents,
  }) : documents = documents ?? [];

  factory TradeLicenseModel.fromJson(Map<String, dynamic> json) {
    return TradeLicenseModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      buisnessName: json['buisnessName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      emailAdress: json['emailAdress'] ?? '',
      buisnessType: json['buisnessType'] ?? '',
      buisnessCategory: json['buisnessCategory'] ?? '',
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'buisnessName': buisnessName,
        'mobileNumber': mobileNumber,
        'emailAdress': emailAdress,
        'buisnessType': buisnessType,
        'buisnessCategory': buisnessCategory,
        'documents': documents,
      };
}