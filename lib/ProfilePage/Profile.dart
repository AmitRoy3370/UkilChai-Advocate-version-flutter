import 'dart:io';
import 'dart:ui';

class Profile {
  String? id, name, password, locationName, email, phone, profileImageId;
  double? lattitude, longitude;
  File? profileImage;

  Profile(
    this.id,
    this.name,
    this.password,
    this.locationName,
    this.email,
    this.phone,
    this.profileImageId,
  );
  Profile.defaultConstructor();

  @override
  String toString() {
    return "Profile(id: $id, name: $name, password: $password, locationName: $locationName, email: $email, phone: $phone, profileImageId: $profileImageId)";
  }
}
