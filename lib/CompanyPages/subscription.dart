// lib/CompanyPages/subscription.dart
class Subscription {
  String? id;
  String companyId;
  String subscriberName;
  int numberOfShare;
  String? signatureId;

  Subscription({
    this.id,
    required this.companyId,
    required this.subscriberName,
    required this.numberOfShare,
    this.signatureId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      companyId: json['companyId'] ?? '',
      subscriberName: json['subscriberName'] ?? '',
      numberOfShare: json['numberOfShare'] ?? 0,
      signatureId: json['signatureId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'subscriberName': subscriberName,
      'numberOfShare': numberOfShare,
      if (signatureId != null) 'signatureId': signatureId,
    };
  }

  // ✅ Copy with method for updating
  Subscription copyWith({
    String? id,
    String? companyId,
    String? subscriberName,
    int? numberOfShare,
    String? signatureId,
  }) {
    return Subscription(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      subscriberName: subscriberName ?? this.subscriberName,
      numberOfShare: numberOfShare ?? this.numberOfShare,
      signatureId: signatureId ?? this.signatureId,
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, companyId: $companyId, '
        'subscriberName: $subscriberName, numberOfShare: $numberOfShare, '
        'signatureId: $signatureId)';
  }
}