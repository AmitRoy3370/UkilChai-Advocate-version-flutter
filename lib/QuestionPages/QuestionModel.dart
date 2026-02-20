class QuestionModel {
  final String id;
  final String userId;
  final String message;
  final String questionType;
  final String postTime;
  final String? attachmentId;

  QuestionModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.questionType,
    required this.postTime,
    this.attachmentId,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      userId: json['userId'],
      message: json['message'],
      questionType: json['questionType'],
      postTime: json['postTime'],
      attachmentId: json['attachmentId'],
    );
  }
}
