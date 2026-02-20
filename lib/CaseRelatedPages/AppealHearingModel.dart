class AppealHearing {
  final String id;
  final String hearingId;
  final String reason;
  final DateTime? appealHearingTime;

  AppealHearing({
    required this.id,
    required this.hearingId,
    required this.reason,
    this.appealHearingTime,
  });

  factory AppealHearing.fromJson(Map<String, dynamic> json) {
    return AppealHearing(
      id: json['id'],
      hearingId: json['hearingId'],
      reason: json['reason'],
      appealHearingTime: json['appealHearingTime'] != null
          ? DateTime.parse(json['appealHearingTime'])
          : null,
    );
  }
}
