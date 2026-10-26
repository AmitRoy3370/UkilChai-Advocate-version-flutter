// lib/CompanyPages/company_contact.dart
class CompanyContact {
  String? id;
  String contactPersonName;
  String contactPersonMobile;
  String contactPersonEmail;
  String howDidHear;
  String? anyOtherMessage;
  String companyId;

  CompanyContact({
    this.id,
    required this.contactPersonName,
    required this.contactPersonMobile,
    required this.contactPersonEmail,
    required this.howDidHear,
    this.anyOtherMessage,
    required this.companyId,
  });

  factory CompanyContact.fromJson(Map<String, dynamic> json) {
    return CompanyContact(
      id: json['id'],
      contactPersonName: json['contactPersonName'] ?? '',
      contactPersonMobile: json['contactPersonMobile'] ?? '',
      contactPersonEmail: json['contactPersonEmail'] ?? '',
      howDidHear: json['howDidHear'] ?? '',
      anyOtherMessage: json['anyOtherMessage'],
      companyId: json['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactPersonName': contactPersonName,
      'contactPersonMobile': contactPersonMobile,
      'contactPersonEmail': contactPersonEmail,
      'howDidHear': howDidHear,
      if (anyOtherMessage != null && anyOtherMessage!.isNotEmpty) 
        'anyOtherMessage': anyOtherMessage,
      'companyId': companyId,
    };
  }

  // Copy with method for updating
  CompanyContact copyWith({
    String? id,
    String? contactPersonName,
    String? contactPersonMobile,
    String? contactPersonEmail,
    String? howDidHear,
    String? anyOtherMessage,
    String? companyId,
  }) {
    return CompanyContact(
      id: id ?? this.id,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonMobile: contactPersonMobile ?? this.contactPersonMobile,
      contactPersonEmail: contactPersonEmail ?? this.contactPersonEmail,
      howDidHear: howDidHear ?? this.howDidHear,
      anyOtherMessage: anyOtherMessage ?? this.anyOtherMessage,
      companyId: companyId ?? this.companyId,
    );
  }

  @override
  String toString() {
    return 'CompanyContact(id: $id, contactPersonName: $contactPersonName, '
        'contactPersonMobile: $contactPersonMobile, contactPersonEmail: $contactPersonEmail, '
        'howDidHear: $howDidHear, anyOtherMessage: $anyOtherMessage, companyId: $companyId)';
  }
}