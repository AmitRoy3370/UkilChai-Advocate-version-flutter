// lib/Copyright/models/copyright_payment_model.dart

class CopyrightPaymentModel {
  String? id;
  String senderUserId;
  String senderUserName;
  String senderPhoneNumber;
  final String receiverPhoneNumber; // backend-এ fixed
  String transactionId;
  String copyrightId;
  double amount;
  DateTime sendingTime;

  CopyrightPaymentModel({
    this.id,
    required this.senderUserId,
    required this.senderUserName,
    required this.senderPhoneNumber,
    this.receiverPhoneNumber = '+8801874648472',
    required this.transactionId,
    required this.copyrightId,
    required this.amount,
    DateTime? sendingTime,
  }) : sendingTime = sendingTime ?? DateTime.now();

  factory CopyrightPaymentModel.fromJson(Map<String, dynamic> json) {
    return CopyrightPaymentModel(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderUserName: json['senderUserName'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '+8801874648472',
      transactionId: json['transactionId'] ?? '',
      copyrightId: json['copyrightId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      sendingTime: json['sendingTime'] != null
          ? DateTime.parse(json['sendingTime'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'senderUserId': senderUserId,
        'senderUserName': senderUserName,
        'senderPhoneNumber': senderPhoneNumber,
        'transactionId': transactionId,
        'copyrightId': copyrightId,
        'amount': amount,
        'sendingTime': sendingTime.toUtc().toIso8601String(),
      };
}