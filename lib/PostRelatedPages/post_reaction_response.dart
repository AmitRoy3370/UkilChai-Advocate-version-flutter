import '../PostRelatedPages/post_reaction.dart';

class PostReactionResponse {
  final String id;
  final PostReactions postReaction;
  final String? comment;
  final String userId;
  final String userName;
  final String advocatePostId;

  PostReactionResponse({
    required this.id,
    required this.postReaction,
    this.comment,
    required this.userId,
    required this.userName,
    required this.advocatePostId,
  });

  // From JSON Factory Constructor
  factory PostReactionResponse.fromJson(Map<String, dynamic> json) {
    return PostReactionResponse(
      id: json['id'] ?? '',
      postReaction: PostReactions.fromString(json['postReaction'] ?? 'LIKE'),
      comment: json['comment'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      advocatePostId: json['advocatePostId'] ?? '',
    );
  }

  // To JSON Method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postReaction': postReaction.value,
      if (comment != null) 'comment': comment,
      'userId': userId,
      'userName': userName,
      'advocatePostId': advocatePostId,
    };
  }

  // Copy With Method (State Update এর জন্য)
  PostReactionResponse copyWith({
    String? id,
    PostReactions? postReaction,
    String? comment,
    String? userId,
    String? userName,
    String? advocatePostId,
  }) {
    return PostReactionResponse(
      id: id ?? this.id,
      postReaction: postReaction ?? this.postReaction,
      comment: comment ?? this.comment,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      advocatePostId: advocatePostId ?? this.advocatePostId,
    );
  }

  @override
  String toString() {
    return 'PostReactionResponse(id: $id, postReaction: ${postReaction.label}, userId: $userId, advocatePostId: $advocatePostId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostReactionResponse &&
        other.id == id &&
        other.postReaction == postReaction &&
        other.comment == comment &&
        other.userId == userId &&
        other.userName == userName &&
        other.advocatePostId == advocatePostId;
  }

  @override
  int get hashCode {
    return Object.hash(id, postReaction, comment, userId, userName, advocatePostId);
  }
}