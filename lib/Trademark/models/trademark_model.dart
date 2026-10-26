// lib/Trademark/models/trademark_model.dart

class TrademarkModel {
  String? id;
  String legalProtection;
  String nationWiseValidity;
  String applicationType;
  String applicationName;
  double governmentFee;
  String organaizationalName;
  String trademarkName;
  String trademarkType;
  String classOfGoods;
  String adress;
  String email;
  String mobileNumber;
  List<String> documents;
  String userId;

  TrademarkModel({
    this.id,
    this.legalProtection = '',
    this.nationWiseValidity = '',
    this.applicationType = '',
    this.applicationName = '',
    this.governmentFee = 0.0,
    this.organaizationalName = '',
    this.trademarkName = '',
    this.trademarkType = '',
    this.classOfGoods = '',
    this.adress = '',
    this.email = '',
    this.mobileNumber = '',
    List<String>? documents,
    this.userId = '',
  }) : documents = documents ?? [];

  factory TrademarkModel.fromJson(Map<String, dynamic> json) {
    return TrademarkModel(
      id: json['id'],
      legalProtection: json['legalProtection'] ?? '',
      nationWiseValidity: json['nationWiseValidity'] ?? '',
      applicationType: json['applicationType'] ?? '',
      applicationName: json['applicationName'] ?? '',
      governmentFee: (json['governmentFee'] as num?)?.toDouble() ?? 0.0,
      organaizationalName: json['organaizationalName'] ?? '',
      trademarkName: json['trademarkName'] ?? '',
      trademarkType: json['trademarkType'] ?? '',
      classOfGoods: json['classOfGoods'] ?? '',
      adress: json['adress'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'legalProtection': legalProtection,
        'nationWiseValidity': nationWiseValidity,
        'applicationType': applicationType,
        'applicationName': applicationName,
        'governmentFee': governmentFee,
        'organaizationalName': organaizationalName,
        'trademarkName': trademarkName,
        'trademarkType': trademarkType,
        'classOfGoods': classOfGoods,
        'adress': adress,
        'email': email,
        'mobileNumber': mobileNumber,
        'documents': documents,
        'userId': userId,
      };
}