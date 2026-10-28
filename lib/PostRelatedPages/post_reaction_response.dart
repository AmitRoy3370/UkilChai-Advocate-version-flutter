import 'post_reaction.dart';

class PostReactionResponse {
  final String id;
  final PostReactions? postReaction;
  final String? comment;
  final String userId;
  final String? userName;
  final String? fullName;
  final String advocatePostId;

  PostReactionResponse({
    required this.id,
    this.postReaction,
    this.comment,
    required this.userId,
    this.userName,
    this.fullName,
    required this.advocatePostId,
  });

  factory PostReactionResponse.fromJson(Map<String, dynamic> json) {
    return PostReactionResponse(
      id: json['id'] ?? '',
      postReaction: json['postReaction'] != null
          ? PostReactions.fromString(json['postReaction'])
          : null,
      comment: json['comment'],
      userId: json['userId'] ?? '',
      userName: json['userName'],
      fullName: json['fullName'],
      advocatePostId: json['advocatePostId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (postReaction != null) 'postReaction': postReaction!.value,
      if (comment != null) 'comment': comment,
      'userId': userId,
      if (userName != null) 'userName': userName,
      if (fullName != null) 'fullName': fullName,
      'advocatePostId': advocatePostId,
    };
  }

  // ---------------- copyWith ----------------
  // NOTE: To explicitly clear `comment` or `postReaction`, use
  // `copyWith(clearComment: true)` / `copyWith(clearPostReaction: true)`,
  // because a plain `?? this.comment` would preserve the old value
  // when you pass `null`.
  PostReactionResponse copyWith({
    String? id,
    PostReactions? postReaction,
    bool clearPostReaction = false,
    String? comment,
    bool clearComment = false,
    String? userId,
    String? userName,
    String? fullName,
    String? advocatePostId,
  }) {
    return PostReactionResponse(
      id: id ?? this.id,
      postReaction:
          clearPostReaction ? null : (postReaction ?? this.postReaction),
      comment: clearComment ? null : (comment ?? this.comment),
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      advocatePostId: advocatePostId ?? this.advocatePostId,
    );
  }

  @override
  String toString() {
    return 'PostReactionResponse(id: $id, postReaction: $postReaction, comment: $comment, userId: $userId, userName: $userName, advocatePostId: $advocatePostId)';
  }
}