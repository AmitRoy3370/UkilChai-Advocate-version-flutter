import 'Gender.dart';

class UserGender {
  String id;
  String? userId;
  Gender gender;

  // Constructor
  UserGender({
    this.id = '',
    this.userId,
    required this.gender,
  });

  // Factory method to create UserGender from JSON
  factory UserGender.fromJson(Map<String, dynamic> json) {
    return UserGender(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      gender: GenderExtension.fromString(json['gender']),
    );
  }

  // Method to convert UserGender to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'gender': gender.toString().split('.').last, // Converts Gender.MALE to "MALE"
    };
  }

  // Copy with method for updating specific fields
  UserGender copyWith({
    String? id,
    String? userId,
    Gender? gender,
  }) {
    return UserGender(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
    );
  }

  @override
  String toString() {
    return 'UserGender{id: $id, userId: $userId, gender: $gender}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGender &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          gender == other.gender;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ gender.hashCode;
}