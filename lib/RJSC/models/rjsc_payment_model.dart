// lib/RJSC/models/rjsc_payment_model.dart

class RjscPaymentModel {
  String? id;
  String senderUserId;
  String senderUserName;
  String senderPhoneNumber;
  final String receiverPhoneNumber; // backend এ fixed
  String transactionId;
  String rjscId;
  double amount;
  DateTime sendingTime;

  RjscPaymentModel({
    this.id,
    required this.senderUserId,
    required this.senderUserName,
    required this.senderPhoneNumber,
    this.receiverPhoneNumber = '+8801874648472',
    required this.transactionId,
    required this.rjscId,
    required this.amount,
    DateTime? sendingTime,
  }) : sendingTime = sendingTime ?? DateTime.now();

  factory RjscPaymentModel.fromJson(Map<String, dynamic> json) {
    return RjscPaymentModel(
      id: json['id'],
      senderUserId: json['senderUserId'] ?? '',
      senderUserName: json['senderUserName'] ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] ?? '',
      receiverPhoneNumber: json['receiverPhoneNumber'] ?? '+8801874648472',
      transactionId: json['transactionId'] ?? '',
      rjscId: json['rjscId'] ?? '',
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
        'rjscId': rjscId,
        'amount': amount,
        'sendingTime': sendingTime.toUtc().toIso8601String(),
      };
}