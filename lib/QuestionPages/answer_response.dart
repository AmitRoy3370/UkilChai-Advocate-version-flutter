// models/answer_response.dart

import 'package:intl/intl.dart';

class AnswerResponse {
  final String id;
  final String advocateId;
  final String advocateName;
  final String? advocateFullName;
  final String message;
  final DateTime time;
  final String questionId;
  final String? attachmentId;

  AnswerResponse({
    required this.id,
    required this.advocateId,
    required this.advocateName,
    required this.advocateFullName,
    required this.message,
    required this.time,
    required this.questionId,
    this.attachmentId,
  });

  // From JSON Factory Constructor
  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      id: json['id'] ?? '',
      advocateId: json['advocateId'] ?? '',
      advocateName: json['advocateName'] ?? '',
      advocateFullName: json['advocateFullName'],
      message: json['message'] ?? '',
      time: json['time'] != null
          ? DateTime.parse(json['time']).toLocal()
          : DateTime.now(),
      questionId: json['questionId'] ?? '',
      attachmentId: json['attachmentId'],
    );
  }

  // To JSON Method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advocateId': advocateId,
      'advocateName': advocateName,
      'advocateFullName': advocateFullName,
      'message': message,
      'time': time.toUtc().toIso8601String(),
      'questionId': questionId,
      if (attachmentId != null) 'attachmentId': attachmentId,
    };
  }

  // Copy With Method (State Update এর জন্য)
  AnswerResponse copyWith({
    String? id,
    String? advocateId,
    String? advocateName,
    String? advocateFullName,
    String? message,
    DateTime? time,
    String? questionId,
    String? attachmentId,
  }) {
    return AnswerResponse(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      advocateName: advocateName ?? this.advocateName,
      advocateFullName: advocateFullName ?? this.advocateFullName,
      message: message ?? this.message,
      time: time ?? this.time,
      questionId: questionId ?? this.questionId,
      attachmentId: attachmentId ?? this.attachmentId,
    );
  }

  // Computed Properties
  bool get hasAttachment => attachmentId != null && attachmentId!.isNotEmpty;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM dd, yyyy - hh:mm a').format(time);
    }
  }

  String get fullFormattedTime {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(time);
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(time);
  }

  String get formattedTimeOnly {
    return DateFormat('hh:mm a').format(time);
  }

  @override
  String toString() {
    return 'AnswerResponse(id: $id, advocateName: $advocateName, message: $message, time: $formattedTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerResponse &&
        other.id == id &&
        other.advocateId == advocateId &&
        other.advocateName == advocateName &&
        other.advocateFullName == advocateFullName &&
        other.message == message &&
        other.time == time &&
        other.questionId == questionId &&
        other.attachmentId == attachmentId;
  }

  @override
  int get hashCode {
    return Object.hash(id, advocateId, advocateName, advocateFullName, message, time, questionId, attachmentId);
  }
}