class AdvocateWorkingExperience {
  final String? id;
  final String advocateId;
  final String? barAssociation;
  final String? barControllEnrolment;
  final String? enrollmentDate; // ISO 8601 format (e.g., "2026-10-23T10:00:00Z")
  final String? practicingCoat;
  final String? primaryPractice;
  final int yearOfLegalPractice;
  final String currentChemberName;
  final int professionalExperience;

  AdvocateWorkingExperience({
    this.id,
    required this.advocateId,
    this.barAssociation,
    this.barControllEnrolment,
    this.enrollmentDate,
    this.practicingCoat,
    this.primaryPractice,
    this.yearOfLegalPractice = 0,
    required this.currentChemberName,
    this.professionalExperience = 0,
  });

  factory AdvocateWorkingExperience.fromJson(Map<String, dynamic> json) {
    return AdvocateWorkingExperience(
      id: json['id'],
      advocateId: json['advocateId'] ?? '',
      barAssociation: json['barAssociation'],
      barControllEnrolment: json['barControllEnrolment'],
      enrollmentDate: json['enrollmentDate'],
      practicingCoat: json['practicingCoat'],
      primaryPractice: json['primaryPractice'],
      yearOfLegalPractice: json['yearOfLegalPractice'] ?? 0,
      currentChemberName: json['currentChemberName'] ?? '',
      professionalExperience: json['professionalExperience'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'advocateId': advocateId,
      if (barAssociation != null) 'barAssociation': barAssociation,
      if (barControllEnrolment != null) 'barControllEnrolment': barControllEnrolment,
      if (enrollmentDate != null) 'enrollmentDate': enrollmentDate,
      if (practicingCoat != null) 'practicingCoat': practicingCoat,
      if (primaryPractice != null) 'primaryPractice': primaryPractice,
      'yearOfLegalPractice': yearOfLegalPractice,
      'currentChemberName': currentChemberName,
      'professionalExperience': professionalExperience,
    };
  }

  AdvocateWorkingExperience copyWith({
    String? id,
    String? advocateId,
    String? barAssociation,
    String? barControllEnrolment,
    String? enrollmentDate,
    String? practicingCoat,
    String? primaryPractice,
    int? yearOfLegalPractice,
    String? currentChemberName,
    int? professionalExperience,
  }) {
    return AdvocateWorkingExperience(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      barAssociation: barAssociation ?? this.barAssociation,
      barControllEnrolment: barControllEnrolment ?? this.barControllEnrolment,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      practicingCoat: practicingCoat ?? this.practicingCoat,
      primaryPractice: primaryPractice ?? this.primaryPractice,
      yearOfLegalPractice: yearOfLegalPractice ?? this.yearOfLegalPractice,
      currentChemberName: currentChemberName ?? this.currentChemberName,
      professionalExperience: professionalExperience ?? this.professionalExperience,
    );
  }
}