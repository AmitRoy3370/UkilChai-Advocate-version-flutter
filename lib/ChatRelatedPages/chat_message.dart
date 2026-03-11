class ChatMessage {
   String id;
   String sender;
   String receiver;
   String content;
   DateTime timeStamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timeStamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      sender: json['sender'] ?? '',
      receiver: json['receiver'] ?? '',
      content: json['content'] ?? '',
      timeStamp: json['timeStamp'] != null
          ? DateTime.parse(json['timeStamp']).toLocal()
          : DateTime.now(),
    );
  }
}

class ChatConversation {
  final String userId;
  final String userName;
  final String? userImage;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isMessageRequest;

  ChatConversation({
    required this.userId,
    required this.userName,
    this.userImage,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMessageRequest = false,
  });

  ChatConversation copyWith({
    String? userId,
    String? userName,
    String? userImage,
    ChatMessage? lastMessage,
    int? unreadCount,
    bool? isMessageRequest,
  }) {
    return ChatConversation(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMessageRequest: isMessageRequest ?? this.isMessageRequest,
    );
  }
}

