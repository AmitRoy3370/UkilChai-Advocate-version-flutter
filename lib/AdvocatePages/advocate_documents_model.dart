class AdvocateDocuments {
  final String? id;
  final String advocateId;
  final List<String> attachments;

  AdvocateDocuments({
    this.id,
    required this.advocateId,
    this.attachments = const [],
  });

  factory AdvocateDocuments.fromJson(Map<String, dynamic> json) {
    return AdvocateDocuments(
      id: json['id'],
      advocateId: json['advocateId'] ?? '',
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'advocateId': advocateId,
      'attachments': attachments,
    };
  }

  AdvocateDocuments copyWith({
    String? id,
    String? advocateId,
    List<String>? attachments,
  }) {
    return AdvocateDocuments(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      attachments: attachments ?? this.attachments,
    );
  }
}