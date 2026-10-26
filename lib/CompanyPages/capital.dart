// lib/CompanyPages/capital.dart
class Capital {
  String? id;
  String companyId;
  double authorizedCapital;
  int totalShare;
  int numberOfShare;
  double shareValue;

  Capital({
    this.id,
    required this.companyId,
    required this.authorizedCapital,
    required this.totalShare,
    required this.numberOfShare,
    required this.shareValue,
  });

  factory Capital.fromJson(Map<String, dynamic> json) {
    return Capital(
      id: json['id'],
      companyId: json['companyId'] ?? '',
      authorizedCapital: (json['authorizedCapital'] ?? 0).toDouble(),
      totalShare: json['totalShare'] ?? 0,
      numberOfShare: json['numberOfShare'] ?? 0,
      shareValue: (json['shareValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'authorizedCapital': authorizedCapital,
      'totalShare': totalShare,
      'numberOfShare': numberOfShare,
      'shareValue': shareValue,
    };
  }

  // ✅ Add copyWith method
  Capital copyWith({
    String? id,
    String? companyId,
    double? authorizedCapital,
    int? totalShare,
    int? numberOfShare,
    double? shareValue,
  }) {
    return Capital(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      authorizedCapital: authorizedCapital ?? this.authorizedCapital,
      totalShare: totalShare ?? this.totalShare,
      numberOfShare: numberOfShare ?? this.numberOfShare,
      shareValue: shareValue ?? this.shareValue,
    );
  }
}