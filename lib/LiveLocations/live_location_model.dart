// lib/LiveLocations/live_location_model.dart

// ✅ This matches your DTO response (for GET requests)
class UserLiveLocationDataResponse {
  final String? id;
  final String? advocateId;
  final String userId;
  final String userName;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool active;
  final DateTime? lastHeartbeat;

  UserLiveLocationDataResponse({
    this.id,
    this.advocateId,
    required this.userId,
    required this.userName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.active = true,
    this.lastHeartbeat,
  });

  factory UserLiveLocationDataResponse.fromJson(Map<String, dynamic> json) {
    return UserLiveLocationDataResponse(
      id: json['id'],
      advocateId: json['advocateId'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      locationName: json['locationName'] ?? '',
      latitude: json['lattitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
      lastHeartbeat: json['lastHeartbeat'] != null
          ? DateTime.parse(json['lastHeartbeat'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advocateId': advocateId,
      'userId': userId,
      'userName': userName,
      'locationName': locationName,
      'lattitude': latitude,
      'longitude': longitude,
    };
  }

  bool get isAdvocate => advocateId != null && advocateId!.isNotEmpty;

  // ✅ Convert to LiveLocationData for internal use
  LiveLocationData toLiveLocationData({bool active = true, DateTime? lastHeartbeat}) {
    return LiveLocationData(
      id: id,
      advocateId: advocateId,
      userId: userId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      active: active,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat ?? DateTime.now(),
    );
  }
}

// ✅ This matches your Model (for POST/PUT requests)
class LiveLocationData {
  final String? id;
  final String? advocateId;
  final String userId;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime? lastHeartbeat;
  final bool active;

  LiveLocationData({
    this.id,
    this.advocateId,
    required this.userId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.lastHeartbeat,
    this.active = true,
  });

  factory LiveLocationData.fromJson(Map<String, dynamic> json) {
    return LiveLocationData(
      id: json['id'],
      advocateId: json['advocateId'],
      userId: json['userId'] ?? '',
      locationName: json['locationName'] ?? '',
      latitude: json['lattitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      lastHeartbeat: json['lastHeartbeat'] != null
          ? DateTime.parse(json['lastHeartbeat'])
          : null,
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advocateId': advocateId,
      'userId': userId,
      'locationName': locationName,
      'lattitude': latitude,
      'longitude': longitude,
    };
  }

  bool get isAdvocate => advocateId != null && advocateId!.isNotEmpty;

  // ✅ Convert to Response DTO
  UserLiveLocationDataResponse toResponse({required String userName}) {
    return UserLiveLocationDataResponse(
      id: id,
      advocateId: advocateId,
      userId: userId,
      userName: userName,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      active: active,
      lastHeartbeat: lastHeartbeat ?? DateTime.now(),
    );
  }
}