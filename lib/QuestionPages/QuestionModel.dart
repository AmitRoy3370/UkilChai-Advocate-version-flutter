// lib/QuestionPages/QuestionModel.dart

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
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      questionType: json['questionType'] ?? '',
      postTime: json['postTime'] ?? '',
      attachmentId: json['attachmentId'],
    );
  }
}

// ✅ ADD THIS NEW CLASS AT THE BOTTOM
class QuestionPageModel {
  final List<dynamic> responses; // Will hold List<QuestionResponse>
  final int page;
  final int size;
  final int totalElement;
  final String? nextPage;
  final String? previousPage;

  QuestionPageModel({
    required this.responses,
    required this.page,
    required this.size,
    required this.totalElement,
    this.nextPage,
    this.previousPage,
  });

  bool get hasNext => nextPage != null && nextPage!.isNotEmpty;
  bool get hasPrevious => previousPage != null && previousPage!.isNotEmpty;
}