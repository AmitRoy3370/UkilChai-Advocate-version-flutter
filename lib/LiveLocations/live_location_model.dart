// lib/LiveLocations/live_location_model.dart

// ✅ Model (for POST/PUT requests) — defined FIRST so that
//    UserLiveLocationDataResponse can reference it without ordering issues.
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
      fullName: null,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      active: active,
      lastHeartbeat: lastHeartbeat ?? DateTime.now(),
    );
  }
}

// ✅ DTO response (for GET requests) — defined AFTER LiveLocationData
class UserLiveLocationDataResponse {
  final String? id;
  final String? advocateId;
  final String userId;
  final String userName;
  final String? fullName;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool active;
  final DateTime? lastHeartbeat;

  // ✅ Allows overriding the derived `isAdvocate` value (used by
  //    center-admin / advocate panels to show other advocates as "User")
  final bool? _isAdvocateOverride;

  UserLiveLocationDataResponse({
    this.id,
    this.advocateId,
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.active = true,
    this.lastHeartbeat,
    bool? isAdvocateOverride,
  }) : _isAdvocateOverride = isAdvocateOverride;

  factory UserLiveLocationDataResponse.fromJson(Map<String, dynamic> json) {
    return UserLiveLocationDataResponse(
      id: json['id'],
      advocateId: json['advocateId'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      fullName: json['fullName'],
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
      'fullName': fullName,
      'locationName': locationName,
      'lattitude': latitude,
      'longitude': longitude,
    };
  }

  // ✅ Returns override if set, otherwise derives from advocateId
  bool get isAdvocate =>
      _isAdvocateOverride ?? (advocateId != null && advocateId!.isNotEmpty);

  // ✅ copyWith that supports overriding isAdvocate
  UserLiveLocationDataResponse copyWith({
    String? id,
    String? advocateId,
    String? userId,
    String? userName,
    String? fullName,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? active,
    DateTime? lastHeartbeat,
    bool? isAdvocate,
  }) {
    return UserLiveLocationDataResponse(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      active: active ?? this.active,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      // Preserve existing override unless a new one is passed
      isAdvocateOverride: isAdvocate ?? _isAdvocateOverride,
    );
  }

  // ✅ Convert to LiveLocationData for internal use
  LiveLocationData toLiveLocationData({
    bool active = true,
    DateTime? lastHeartbeat,
  }) {
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