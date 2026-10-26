// GroupChatModels.dart

class GroupModel {
  final String id;
  final String groupName;
  final String createdBy;
  final String creatorName;
  final List<String> members;
  final List<String> membersName;
  final DateTime createdAt;
  final String? groupIcon;

  GroupModel({
    required this.id,
    required this.groupName,
    required this.createdBy,
    required this.creatorName,
    required this.members,
    required this.membersName,
    required this.createdAt,
    this.groupIcon,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      groupName: json['groupName'] ?? '',
      createdBy: json['createdBy'] ?? '',
      creatorName: json['creatorName'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      membersName: List<String>.from(json['membersName'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      groupIcon: json['groupIcon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'members': members,
      'membersName': membersName,
      'createdAt': createdAt.toIso8601String(),
      'groupIcon': groupIcon,
    };
  }

  // কপি মেথড
  GroupModel copyWith({
    String? id,
    String? groupName,
    String? createdBy,
    String? creatorName,
    List<String>? members,
    List<String>? membersName,
    DateTime? createdAt,
    String? groupIcon,
  }) {
    return GroupModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      members: members ?? this.members,
      membersName: membersName ?? this.membersName,
      createdAt: createdAt ?? this.createdAt,
      groupIcon: groupIcon ?? this.groupIcon,
    );
  }
}

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final List<String> readBy;
  final int readCount;
  final int totalMembers;
  final bool edited;

  GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.readBy,
    required this.readCount,
    required this.totalMembers,
    required this.edited,
  });

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      readBy: List<String>.from(json['readBy'] ?? []),
      readCount: json['readCount'] ?? 0,
      totalMembers: json['totalMembers'] ?? 0,
      edited: json['edited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'readBy': readBy,
      'readCount': readCount,
      'totalMembers': totalMembers,
      'edited': edited,
    };
  }

  // 📌 কপি মেথড - এডিট করার জন্য প্রয়োজন
  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    List<String>? readBy,
    int? readCount,
    int? totalMembers,
    bool? edited,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      readCount: readCount ?? this.readCount,
      totalMembers: totalMembers ?? this.totalMembers,
      edited: edited ?? this.edited,
    );
  }
}

class CreateGroupRequest {
  final String groupName;
  final List<String> members;
  final String? groupIcon;

  CreateGroupRequest({
    required this.groupName,
    required this.members,
    this.groupIcon,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName,
      'members': members,
      'groupIcon': groupIcon,
    };
  }
}