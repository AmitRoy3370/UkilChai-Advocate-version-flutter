class CaseClose {
  String? id;
  String? caseId;
  String? userId;
  bool? open;
  DateTime? closedDate;

  CaseClose(this.id, this.caseId, this.userId, this.open, this.closedDate);

  CaseClose.callingConstructor(
    this.caseId,
    this.userId,
    this.open,
    this.closedDate,
  );

  // ================= FROM JSON =================
  factory CaseClose.fromJson(Map<String, dynamic> json) {
    return CaseClose(
      json['id'],
      json['caseId'],
      json['userId'],
      json['open'],
      json['closedDate'] != null ? DateTime.parse(json['closedDate']) : null,
    );
  }

  // ================= TO JSON =================
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "caseId": caseId,
      "userId": userId,
      "open": open,
      "closedDate": closedDate?.toUtc().toIso8601String().replaceAll("+00:00", "Z"),
    };
  }
}
