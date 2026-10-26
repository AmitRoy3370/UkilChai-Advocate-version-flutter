// lib/TradeLicense/models/trade_license_payment_model.dart

class TradeLicensePaymentModel {
  String? id;
  String senderUserId;
  String senderPhoneNumber;
  final String receiverPhoneNumber;
  String transactionId;
  double amount;
  String tradeLicenseId;
  DateTime sendingTime;

  TradeLicensePaymentModel({
    this.id,
    required this.senderUserId,
    required this.senderPhoneNumber,
    this.receiverPhoneNumber = '+8801874648472',
    required this.transactionId,
    required this.amount,
    required this.tradeLicenseId,
    DateTime? sendingTime,
  }) : sendingTime = sendingTime ?? DateTime.now();

  factory TradeLicensePaymentModel.fromJson(Map<String, dynamic> json) {
    return TradeLicensePaymentModel(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '+8801874648472',
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tradeLicenseId: json['tradeLicenseId'] ?? '',
      sendingTime: json['sendingTime'] != null
          ? DateTime.parse(json['sendingTime'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'senderUserId': senderUserId,
        'senderPhoneNumber': senderPhoneNumber,
        'transactionId': transactionId,
        'amount': amount,
        'tradeLicenseId': tradeLicenseId,
        'sendingTime': sendingTime.toUtc().toIso8601String(),
      };
}

/// Payment Response DTO (with senderUserName)
class TradeLicensePaymentResponseDTO {
  String? id;
  String senderUserId;
  String senderUserName;
  String senderPhoneNumber;
  String receiverPhoneNumber;
  String transactionId;
  double amount;
  String tradeLicenseId;
  DateTime sendingTime;

  TradeLicensePaymentResponseDTO({
    this.id,
    this.senderUserId = '',
    this.senderUserName = '',
    this.senderPhoneNumber = '',
    this.receiverPhoneNumber = '',
    this.transactionId = '',
    this.amount = 0.0,
    this.tradeLicenseId = '',
    DateTime? sendingTime,
  }) : sendingTime = sendingTime ?? DateTime.now();

  factory TradeLicensePaymentResponseDTO.fromJson(Map<String, dynamic> json) {
    return TradeLicensePaymentResponseDTO(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderUserName: json['senderUserName'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tradeLicenseId: json['tradeLicenseId'] ?? '',
      sendingTime: json['sendingTime'] != null
          ? DateTime.parse(json['sendingTime'].toString())
          : DateTime.now(),
    );
  }
}