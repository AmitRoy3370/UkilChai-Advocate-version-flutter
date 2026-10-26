
import '../RegistrationPage/gender.dart';

class AdvocateFilter {
  String? speciality;
  String? location;
  Gender? gender;
  
  AdvocateFilter({
    this.speciality,
    this.location,
    this.gender,
  });
  
  // Check if any filter is active
  bool get isActive {
    return speciality != null || location != null || gender != null;
  }
  
  // Get active filter count
  int get activeCount {
    int count = 0;
    if (speciality != null && speciality!.isNotEmpty) count++;
    if (location != null && location!.isNotEmpty) count++;
    if (gender != null) count++;
    return count;
  }
  
  // Copy with method
  AdvocateFilter copyWith({
    String? speciality,
    String? location,
    Gender? gender,
  }) {
    return AdvocateFilter(
      speciality: speciality ?? this.speciality,
      location: location ?? this.location,
      gender: gender ?? this.gender,
    );
  }
  
  @override
  String toString() {
    return 'AdvocateFilter{speciality: $speciality, location: $location, gender: $gender}';
  }
}