class SenderInfo {
  String? receiverName;
  String? receiverId;
  String? message;
  bool? readChat;

  SenderInfo({
    this.receiverName,
    this.receiverId,
    this.message,
    this.readChat
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      receiverName: json['receiverName'],
      receiverId: json['receiverId'],
      message: json['message'],
      readChat: json['readChat']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'receiverId': receiverId,
      'message': message,
      'readChat':readChat
    };
  }
}