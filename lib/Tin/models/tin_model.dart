// lib/Tin/models/tin_model.dart

class TinModel {
  String? id;
  String userId;
  String fullName;
  String fatherName;
  String motherName;
  String phone;
  DateTime dateOfBirth;
  String presentAdress;
  String permanentAdress;
  List<String> documents;

  TinModel({
    this.id,
    required this.userId,
    required this.fullName,
    this.fatherName = '',
    this.motherName = '',
    required this.phone,
    DateTime? dateOfBirth,
    this.presentAdress = '',
    this.permanentAdress = '',
    List<String>? documents,
  })  : dateOfBirth = dateOfBirth ?? DateTime.now(),
        documents = documents ?? [];

  factory TinModel.fromJson(Map<String, dynamic> json) {
    return TinModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'].toString())
          : DateTime.now(),
      presentAdress: json['presentAdress'] ?? '',
      permanentAdress: json['permanentAdress'] ?? '',
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'fullName': fullName,
        'fatherName': fatherName,
        'motherName': motherName,
        'phone': phone,
        'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
        'presentAdress': presentAdress,
        'permanentAdress': permanentAdress,
        'documents': documents,
      };
}