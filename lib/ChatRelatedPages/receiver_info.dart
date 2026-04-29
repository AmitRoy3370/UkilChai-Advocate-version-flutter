class ReceiverInfo {
  String? senderId;
  String? senderName;
  String? message;
  bool? readChat;

  ReceiverInfo({
    this.senderId,
    this.senderName,
    this.message,
    this.readChat
  });

  factory ReceiverInfo.fromJson(Map<String, dynamic> json) {
    return ReceiverInfo(
      senderId: json['senderId'],
      senderName: json['senderName'],
      message: json['message'],
      readChat: json['readChat']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'readChat':readChat
    };
  }
}