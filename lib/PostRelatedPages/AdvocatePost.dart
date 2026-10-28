class AdvocatePost {
  final String? id;
  final String advocateId;
  final String postContent;
  final String? attachmentId;
  final String postType;
  final String? postTitle;

  AdvocatePost({
    this.id,
    required this.advocateId,
    required this.postContent,
    this.attachmentId,
    required this.postType,
    this.postTitle,
  });

  factory AdvocatePost.fromJson(Map<String, dynamic> json) {
    return AdvocatePost(
      id: json['id'],
      advocateId: json['advocateId'] ?? '',
      postContent: json['postContent'] ?? '',
      attachmentId: json['attachmentId'],
      postType: json['postType'] ?? '',
      postTitle: json['postTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'advocateId': advocateId,
      'postContent': postContent,
      if (attachmentId != null) 'attachmentId': attachmentId,
      'postType': postType,
      if (postTitle != null) 'postTitle': postTitle,
    };
  }

  @override
  String toString() {
    return 'AdvocatePost(id: $id, advocateId: $advocateId, postType: $postType, postTitle: $postTitle, postContent: $postContent, attachmentId: $attachmentId)';
  }
}