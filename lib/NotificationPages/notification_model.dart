// notification_model.dart
class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime timeStamp;
  final List<String> destinations;
  final Map<String, String> params;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.timeStamp,
    required this.destinations,
    required this.params,
  });

  // ✅ Convert Backend JSON to Flutter Model
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      isRead: json['read'] ?? false,
      // Handle Instant parsing (MongoDB returns as ISO String)
      timeStamp: json['timeStamp'] != null 
          ? DateTime.parse(json['timeStamp']).toLocal() 
          : DateTime.now(),
      // Safely handle Lists and Maps (default to empty if null)
      destinations: json['destinations'] != null 
          ? List<String>.from(json['destinations']) 
          : [],
      params: json['params'] != null 
          ? Map<String, String>.from(json['params']) 
          : {},
    );
  }

  // ✅ Convert Flutter Model back to JSON (For sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'read': isRead,
      'timeStamp': timeStamp.toUtc().toIso8601String(),
      'destinations': destinations,
      'params': params,
    };
  }
}