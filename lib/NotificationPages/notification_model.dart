class NotificationModel {
  final String id;
  final String message;
  final bool read;
  final String timeStamp;

  NotificationModel({
    required this.id,
    required this.message,
    required this.read,
    required this.timeStamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["id"],
      message: json["message"],
      read: json["read"],
      timeStamp: json["timeStamp"],
    );
  }
}
