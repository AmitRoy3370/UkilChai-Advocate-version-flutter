class UserBasic {
  final String userId;
  final String name;

  UserBasic({required this.userId, required this.name});

  factory UserBasic.fromJson(Map<String, dynamic> json) {
    return UserBasic(
      userId: json['id'] ?? json['userId'],
      name: json['name'],
    );
  }
}
