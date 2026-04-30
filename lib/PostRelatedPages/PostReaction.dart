class PostReaction {
  final String id;
  final String userId;
  final String advocatePostId;
  String? reaction;
  String? comment;

  PostReaction({
    required this.id,
    required this.userId,
    required this.advocatePostId,
    this.reaction,
    this.comment,
  });

  factory PostReaction.fromJson(Map<String, dynamic> json) {
    return PostReaction(
      id: json['id'],
      userId: json['userId'],
      advocatePostId: json['advocatePostId'],
      reaction: json['postReaction'],
      comment: json['comment'],
    );
  }
}
