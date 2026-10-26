enum Gender {
  MALE,
  FEMALE,
  OTHER,
}

// Extension to handle conversion between String and Enum
extension GenderExtension on Gender {
  // Convert Gender enum to String
  String get value => toString().split('.').last;

  // Convert String to Gender enum
  static Gender fromString(String gender) {
    switch (gender.toUpperCase()) {
      case 'MALE':
        return Gender.MALE;
      case 'FEMALE':
        return Gender.FEMALE;
      case 'OTHER':
        return Gender.OTHER;
      default:
        throw ArgumentError('Invalid gender: $gender');
    }
  }

  // Get display name for UI
  String get displayName {
    switch (this) {
      case Gender.MALE:
        return 'Male';
      case Gender.FEMALE:
        return 'Female';
      case Gender.OTHER:
        return 'Other';
    }
  }
}