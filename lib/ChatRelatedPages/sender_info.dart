class SenderInfo {
  String? receiverName;
  String? receiverId;
  String? message;

  SenderInfo({
    this.receiverName,
    this.receiverId,
    this.message,
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      receiverName: json['receiverName'],
      receiverId: json['receiverId'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'receiverId': receiverId,
      'message': message,
    };
  }
}