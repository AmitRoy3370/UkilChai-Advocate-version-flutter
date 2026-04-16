class ReceiverInfo {
  String? senderId;
  String? senderName;
  String? message;

  ReceiverInfo({
    this.senderId,
    this.senderName,
    this.message,
  });

  factory ReceiverInfo.fromJson(Map<String, dynamic> json) {
    return ReceiverInfo(
      senderId: json['senderId'],
      senderName: json['senderName'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
    };
  }
}