class AdvocateDocumentsJoinRequest {
  final String? id;
  final String advocateId;
  final List<String> attachments;

  AdvocateDocumentsJoinRequest({
    this.id,
    required this.advocateId,
    required this.attachments,
  });

  factory AdvocateDocumentsJoinRequest.fromJson(Map<String, dynamic> json) {
    return AdvocateDocumentsJoinRequest(
      id: json['id'],
      advocateId: json['advocateId'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'advocateId': advocateId,
      'attachments': attachments,
    };
  }

  AdvocateDocumentsJoinRequest copyWith({
    String? id,
    String? advocateId,
    List<String>? attachments,
  }) {
    return AdvocateDocumentsJoinRequest(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      attachments: attachments ?? this.attachments,
    );
  }
}