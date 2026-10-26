// lib/ShareholderPages/shareholder.dart
class Shareholder {
  String? id;
  String userId;
  String? fullName;
  String? nid;
  String? tin;
  Map<String, List<double>> sharePercentage;

  Shareholder({
    this.id,
    required this.userId,
    this.nid,
    this.tin,
    this.sharePercentage = const {},
    this.fullName
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'userId': userId,
      if (nid != null && nid!.isNotEmpty) 'nid': nid,
      if (tin != null && tin!.isNotEmpty) 'tin': tin,
      'sharePercentage': sharePercentage,
      if(fullName != null) 'fullName': fullName
    };
  }

  factory Shareholder.fromJson(Map<String, dynamic> json) {
    return Shareholder(
      id: json['id'],
      userId: json['userId'] ?? '',
      nid: json['nid'],
      tin: json['tin'],
      sharePercentage: json['sharePercentage'] != null
          ? Map<String, List<double>>.from(
              json['sharePercentage'].map((key, value) =>
                  MapEntry(key, List<double>.from(value))))
          : {},
       fullName: json['fullName']
    );
  }
}
