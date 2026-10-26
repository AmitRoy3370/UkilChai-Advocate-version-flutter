// lib/CompanyPages/company_request_payment.dart
class CompanyRequestPayment {
  String? id;
  String companyId;
  String senderUserId;
  String senderPhoneNumber;
  String transactionId;
  double amount;

  CompanyRequestPayment({
    this.id,
    required this.companyId,
    required this.senderUserId,
    required this.senderPhoneNumber,
    required this.transactionId,
    required this.amount,
  });

  factory CompanyRequestPayment.fromJson(Map<String, dynamic> json) {
    return CompanyRequestPayment(
      id: json['id'],
      companyId: json['companyId'] ?? '',
      senderUserId: json['senderUserId'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'senderUserId': senderUserId,
      'senderPhoneNumber': senderPhoneNumber,
      'transactionId': transactionId,
      'amount': amount,
    };
  }
}