// chat_list_item.dart
class ChatListItem {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  ChatListItem({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory ChatListItem.fromJson(Map<String, dynamic> json) {
    return ChatListItem(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userAvatar: json['userAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime']).toLocal()
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
    );
  }
}