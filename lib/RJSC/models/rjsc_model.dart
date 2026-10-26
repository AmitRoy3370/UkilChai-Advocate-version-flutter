// lib/RJSC/models/rjsc_model.dart

class RjscModel {
  String? id;
  String userId;
  String compilenceService;
  String registrationNo;
  String email;
  String companyName;
  DateTime year;
  List<String> documents;

  RjscModel({
    this.id,
    required this.userId,
    required this.compilenceService,
    required this.registrationNo,
    required this.email,
    required this.companyName,
    DateTime? year,
    List<String>? documents,
  })  : year = year ?? DateTime.now(),
        documents = documents ?? [];

  factory RjscModel.fromJson(Map<String, dynamic> json) {
    return RjscModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      compilenceService: json['compilenceService'] ?? '',
      registrationNo: json['registrationNo'] ?? '',
      email: json['email'] ?? '',
      companyName: json['companyName'] ?? '',
      year: json['year'] != null
          ? DateTime.parse(json['year'].toString())
          : DateTime.now(),
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'compilenceService': compilenceService,
        'registrationNo': registrationNo,
        'email': email,
        'companyName': companyName,
        'year': year.toUtc().toIso8601String(),
        'documents': documents,
      };
}