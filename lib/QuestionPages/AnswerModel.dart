class AnswerModel {
  final String? id;
  final String advocateId;
  final String message;
  final DateTime time;
  final String questionId;
  final String? attachmentId;

  AnswerModel({
    this.id,
    required this.advocateId,
    required this.message,
    required this.time,
    required this.questionId,
    this.attachmentId,
  });

  /// JSON → Dart (from backend)
  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'],
      advocateId: json['advocateId'],
      message: json['message'],
      time: DateTime.parse(json['time']), // Instant → ISO String
      questionId: json['questionId'],
      attachmentId: json['attachmentId'],
    );
  }

  /// Dart → JSON (to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advocateId': advocateId,
      'message': message,
      'time': time.toIso8601String(),
      'questionId': questionId,
      'attachmentId': attachmentId,
    };
  }
}
