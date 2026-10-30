class AdvocateWorkingExperienceJoinRequest {
  final String? id;
  final String advocateId;
  final String? barAssociation;
  final String? barControllEnrolment;
  final String? enrollmentDate; // ISO-8601 String for Instant
  final String? practicingCoat;
  final String? primaryPractice;
  final int yearOfLegalPractice;
  final String currentChemberName;
  final int professionalExperience;

  AdvocateWorkingExperienceJoinRequest({
    this.id,
    required this.advocateId,
    this.barAssociation,
    this.barControllEnrolment,
    this.enrollmentDate,
    this.practicingCoat,
    this.primaryPractice,
    required this.yearOfLegalPractice,
    required this.currentChemberName,
    required this.professionalExperience,
  });

  factory AdvocateWorkingExperienceJoinRequest.fromJson(
      Map<String, dynamic> json) {
    return AdvocateWorkingExperienceJoinRequest(
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
      if (barControllEnrolment != null)
        'barControllEnrolment': barControllEnrolment,
      if (enrollmentDate != null) 'enrollmentDate': enrollmentDate,
      if (practicingCoat != null) 'practicingCoat': practicingCoat,
      if (primaryPractice != null) 'primaryPractice': primaryPractice,
      'yearOfLegalPractice': yearOfLegalPractice,
      'currentChemberName': currentChemberName,
      'professionalExperience': professionalExperience,
    };
  }

  AdvocateWorkingExperienceJoinRequest copyWith({
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
    return AdvocateWorkingExperienceJoinRequest(
      id: id ?? this.id,
      advocateId: advocateId ?? this.advocateId,
      barAssociation: barAssociation ?? this.barAssociation,
      barControllEnrolment:
          barControllEnrolment ?? this.barControllEnrolment,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      practicingCoat: practicingCoat ?? this.practicingCoat,
      primaryPractice: primaryPractice ?? this.primaryPractice,
      yearOfLegalPractice:
          yearOfLegalPractice ?? this.yearOfLegalPractice,
      currentChemberName: currentChemberName ?? this.currentChemberName,
      professionalExperience:
          professionalExperience ?? this.professionalExperience,
    );
  }
}