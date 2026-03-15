class PaymentDetails {
  final String? id;
  final String paymentFor;   // string representation of enum
  final double price;
  final String userId;
  final String caseId;

  PaymentDetails({
    this.id,
    required this.paymentFor,
    required this.price,
    required this.userId,
    required this.caseId,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      id: json['id'],
      paymentFor: json['paymentFor'],
      price: (json['price'] as num).toDouble(),
      userId: json['userId'],
      caseId: json['caseId'],
    );
  }
}