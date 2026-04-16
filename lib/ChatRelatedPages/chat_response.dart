import '../ChatRelatedPages/sender_info.dart';
import '../ChatRelatedPages/receiver_info.dart';

class ChatResponse {
  String? id;
  String? senderId;
  String? senderName;
  SenderInfo? senderInfo;
  ReceiverInfo? receiverInfo;
  DateTime? timeStamp;

  ChatResponse({
    this.id,
    this.senderId,
    this.senderName,
    this.senderInfo,
    this.receiverInfo,
    this.timeStamp,
  });

  // FROM JSON
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      id: json['id'] != null ? json['id'].toString() : null,
      senderId: json['senderId'] != null ? json['senderId'].toString() : null,
      senderName: json['senderName'] != null ? json['senderName'].toString() : null,
      senderInfo: json['senderInfo'] != null
          ? SenderInfo.fromJson(json['senderInfo'])
          : null,
      receiverInfo: json['receiverInfo'] != null
          ? ReceiverInfo.fromJson(json['receiverInfo'])
          : null,
      timeStamp: json['timeStamp'] != null
          ? DateTime.parse(json['timeStamp'])
          : null,
    );
  }

  // TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderInfo': senderInfo?.toJson(),
      'receiverInfo': receiverInfo?.toJson(),
      'timeStamp': timeStamp?.toIso8601String(),
    };
  }
}