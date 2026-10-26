// lib/Trademark/models/trademark_payment_model.dart
import 'trademark_model.dart';

class TrademarkPaymentModel {
  String? id;
  String senderUserId;
  String senderPhoneNumber;
  final String receiverPhoneNumber;
  String tradeMarkId;
  String transactionId;
  double amount;
  DateTime sendingTime;

  TrademarkPaymentModel({
    this.id,
    required this.senderUserId,
    required this.senderPhoneNumber,
    this.receiverPhoneNumber = '+8801874648472',
    required this.tradeMarkId,
    required this.transactionId,
    required this.amount,
    DateTime? sendingTime,
  }) : sendingTime = sendingTime ?? DateTime.now();

  factory TrademarkPaymentModel.fromJson(Map<String, dynamic> json) {
    return TrademarkPaymentModel(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '+8801874648472',
      tradeMarkId: json['tradeMarkId'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      sendingTime: json['sendingTime'] != null
          ? DateTime.parse(json['sendingTime'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'senderUserId': senderUserId,
        'senderPhoneNumber': senderPhoneNumber,
        'tradeMarkId': tradeMarkId,
        'transactionId': transactionId,
        'amount': amount,
        'sendingTime': sendingTime.toUtc().toIso8601String(),
      };
}

/// Payment Response DTO
class TrademarkPaymentResponse {
  String? id;
  String senderUserId;
  String senderUserName;
  String senderName;
  String senderPhoneNumber;
  String receiverPhoneNumber;
  String transactionId;
  String trademarkId;
  double amount;
  DateTime sendingTime;
  TrademarkModel? trademark;

  TrademarkPaymentResponse({
    this.id,
    this.senderUserId = '',
    this.senderUserName = '',
    this.senderName = '',
    this.senderPhoneNumber = '',
    this.receiverPhoneNumber = '',
    this.transactionId = '',
    this.trademarkId = '',
    this.amount = 0.0,
    DateTime? sendingTime,
    this.trademark,
  }) : sendingTime = sendingTime ?? DateTime.now();

  factory TrademarkPaymentResponse.fromJson(Map<String, dynamic> json) {
    return TrademarkPaymentResponse(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderUserName: json['senderUserName'] ?? '',
      senderName: json['senderName'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '',
      transactionId: json['transactionId'] ?? '',
      trademarkId: json['trademarkId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      sendingTime: json['sendingTime'] != null
          ? DateTime.parse(json['sendingTime'].toString())
          : DateTime.now(),
      trademark: json['trademark'] != null
          ? TrademarkModel.fromJson(Map<String, dynamic>.from(json['trademark']))
          : null,
    );
  }
}