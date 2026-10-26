// lib/CompanyPages/company_payment_response.dart
import 'package:intl/intl.dart';

class CompanyPaymentResponse {
  String? id;
  String companyId;
  String companyName;
  String senderUserId;
  String senderUserName;
  String senderPhoneNumber;
  String receiverPhoneNumber;
  String transactionId;
  double amount;
  DateTime sendingTime;

  CompanyPaymentResponse({
    this.id,
    required this.companyId,
    required this.companyName,
    required this.senderUserId,
    required this.senderUserName,
    required this.senderPhoneNumber,
    required this.receiverPhoneNumber,
    required this.transactionId,
    required this.amount,
    required this.sendingTime,
  });

  factory CompanyPaymentResponse.fromJson(Map<String, dynamic> json) {
    return CompanyPaymentResponse(
      id: json['id'],
      companyId: json['cmpanyId'] ?? '',
      companyName: json['companyName'] ?? '',
      senderUserId: json['senderUserId'] ?? '',
      senderUserName: json['senderUserName'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      sendingTime: json['sendingTime'] != null
          ? DateTime.parse(json['sendingTime']).toLocal()
          : DateTime.now(),
    );
  }

  // Formatted date getters
  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(sendingTime);
  }

  String get formattedAmount {
    return '৳${amount.toStringAsFixed(2)}';
  }

  String get formattedTransactionId {
    if (transactionId.length > 12) {
      return '${transactionId.substring(0, 8)}...${transactionId.substring(transactionId.length - 4)}';
    }
    return transactionId;
  }
}