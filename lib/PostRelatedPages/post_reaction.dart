import 'package:flutter/material.dart';

enum PostReactions {
  like,
  disLike,
  haha,
  love,
  care,
  angry,
  wow,
  surprise,
  sad;

  // Enum থেকে String এ কনভার্ট
  String get value {
    switch (this) {
      case PostReactions.like:
        return 'LIKE';
      case PostReactions.disLike:
        return 'DIS_LIKE';
      case PostReactions.haha:
        return 'HAHA';
      case PostReactions.love:
        return 'LOVE';
      case PostReactions.care:
        return 'CARE';
      case PostReactions.angry:
        return 'ANGRY';
      case PostReactions.wow:
        return 'WOW';
      case PostReactions.surprise:
        return 'SURPRISE';
      case PostReactions.sad:
        return 'SAD';
    }
  }

  // String থেকে Enum এ কনভার্ট
  static PostReactions fromString(String value) {
    switch (value.toUpperCase()) {
      case 'LIKE':
        return PostReactions.like;
      case 'DIS_LIKE':
        return PostReactions.disLike;
      case 'HAHA':
        return PostReactions.haha;
      case 'LOVE':
        return PostReactions.love;
      case 'CARE':
        return PostReactions.care;
      case 'ANGRY':
        return PostReactions.angry;
      case 'WOW':
        return PostReactions.wow;
      case 'SURPRISE':
        return PostReactions.surprise;
      case 'SAD':
        return PostReactions.sad;
      default:
        return PostReactions.like;
    }
  }

  // UI দেখানোর জন্য আইকন
  IconData get icon {
    switch (this) {
      case PostReactions.like:
        return Icons.thumb_up;
      case PostReactions.disLike:
        return Icons.thumb_down;
      case PostReactions.haha:
        return Icons.emoji_emotions;
      case PostReactions.love:
        return Icons.favorite;
      case PostReactions.care:
        return Icons.health_and_safety;
      case PostReactions.angry:
        return Icons.emoji_emotions;
      case PostReactions.wow:
        return Icons.emoji_emotions;
      case PostReactions.surprise:
        return Icons.emoji_emotions;
      case PostReactions.sad:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  // UI দেখানোর জন্য রঙ
  Color get color {
    switch (this) {
      case PostReactions.like:
        return Colors.blue;
      case PostReactions.disLike:
        return Colors.grey;
      case PostReactions.haha:
        return Colors.orange;
      case PostReactions.love:
        return Colors.red;
      case PostReactions.care:
        return Colors.green;
      case PostReactions.angry:
        return Colors.deepOrange;
      case PostReactions.wow:
        return Colors.purple;
      case PostReactions.surprise:
        return Colors.yellow;
      case PostReactions.sad:
        return Colors.blueGrey;
    }
  }

  // UI দেখানোর জন্য লেবেল
  String get label {
    switch (this) {
      case PostReactions.like:
        return 'Like';
      case PostReactions.disLike:
        return 'Dislike';
      case PostReactions.haha:
        return 'Haha';
      case PostReactions.love:
        return 'Love';
      case PostReactions.care:
        return 'Care';
      case PostReactions.angry:
        return 'Angry';
      case PostReactions.wow:
        return 'Wow';
      case PostReactions.surprise:
        return 'Surprise';
      case PostReactions.sad:
        return 'Sad';
    }
  }
}