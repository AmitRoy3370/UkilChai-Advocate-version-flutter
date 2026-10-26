// lib/Copyright/models/copyright_model.dart

class CopyrightModel {
  String? id;
  String userId;
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

  CopyrightModel({
    this.id,
    required this.userId,
    required this.author,
    required this.typeOfWork,
    DateTime? yearOfCreation,
    required this.titleOfWork,
    required this.description,
    required this.applicationName,
    required this.mobileNumber,
    required this.email,
    required this.adress,
    List<String>? documents,
  })  : yearOfCreation = yearOfCreation ?? DateTime.now(),
        documents = documents ?? [];

  factory CopyrightModel.fromJson(Map<String, dynamic> json) {
    return CopyrightModel(
      id: json['id'],
      userId: json['userId'] ?? '',
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
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'author': author,
        'typeOfWork': typeOfWork,
        'yearOfCreation': yearOfCreation.toUtc().toIso8601String(),
        'titleOfWork': titleOfWork,
        'description': description,
        'applicationName': applicationName,
        'mobileNumber': mobileNumber,
        'email': email,
        'adress': adress,
        'documents': documents,
      };
}