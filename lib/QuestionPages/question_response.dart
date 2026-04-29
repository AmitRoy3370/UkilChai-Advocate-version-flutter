import 'dart:ui';

import 'package:intl/intl.dart';

import '../Utils/AdvocateSpeciality.dart';
import 'answer_response.dart';

class QuestionResponse {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final AdvocateSpeciality questionType;
  final DateTime postTime;
  final String? attachmentId;
  final List<AnswerResponse> answers;

  QuestionResponse({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.questionType,
    required this.postTime,
    this.attachmentId,
    required this.answers,
  });

  // From JSON Factory Constructor
  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      message: json['message'] ?? '',
      questionType: AdvocateSpecialityExt.fromApi(json['questionType']),
      postTime: json['postTime'] != null
          ? DateTime.parse(json['postTime']).toLocal()
          : DateTime.now(),
      attachmentId: json['attachmentId'],
      answers: (json['answers'] as List?)
          ?.map((answer) => AnswerResponse.fromJson(answer))
          .toList() ??
          [],
    );
  }

  // To JSON Method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'questionType': questionType.apiValue,
      'postTime': postTime.toUtc().toIso8601String(),
      if (attachmentId != null) 'attachmentId': attachmentId,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }

  // Copy With Method (State Update এর জন্য)
  QuestionResponse copyWith({
    String? id,
    String? userId,
    String? userName,
    String? message,
    AdvocateSpeciality? questionType,
    DateTime? postTime,
    String? attachmentId,
    List<AnswerResponse>? answers,
  }) {
    return QuestionResponse(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      questionType: questionType ?? this.questionType,
      postTime: postTime ?? this.postTime,
      attachmentId: attachmentId ?? this.attachmentId,
      answers: answers ?? this.answers,
    );
  }

  // Computed Properties
  bool get hasAttachment => attachmentId != null && attachmentId!.isNotEmpty;

  int get totalAnswers => answers.length;

  String get formattedPostTime {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM dd, yyyy - hh:mm a').format(postTime);
    }
  }

  String get fullFormattedTime {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(postTime);
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(postTime);
  }

  String get formattedQuestionType => questionType.label;


  @override
  String toString() {
    return 'QuestionResponse(id: $id, userName: $userName, message: $message, questionType: ${questionType.label}, answers: ${answers.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionResponse &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.message == message &&
        other.questionType == questionType &&
        other.postTime == postTime &&
        other.attachmentId == attachmentId &&
        other.answers.length == answers.length;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, userName, message, questionType, postTime, attachmentId, answers.length);
  }
}