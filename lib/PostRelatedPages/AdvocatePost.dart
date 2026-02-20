class AdvocatePost {
  final String id;
  final String advocateId;
  final String postContent;
  final String? attachmentId;
  final String postType;

  AdvocatePost({
    required this.id,
    required this.advocateId,
    required this.postContent,
    this.attachmentId,
    required this.postType,
  });

  factory AdvocatePost.fromJson(Map<String, dynamic> json) {
    return AdvocatePost(
      id: json['id'],
      advocateId: json['advocateId'],
      postContent: json['postContent'],
      attachmentId: json['attachmentId'],
      postType: json['postType'],
    );
  }
}
