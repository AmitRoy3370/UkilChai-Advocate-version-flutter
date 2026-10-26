// lib/DirectorsPages/director.dart
class Director {
  String? id;
  String userId;
  String position;
  String? fullName;
  String? fatherName;
  String? motherName;
  String? nidNumber;
  String? mobileNumber;
  String? email;
  String? nid;

  Director({
    this.id,
    required this.userId,
    required this.position,
    this.fullName,
    this.fatherName,
    this.motherName,
    this.nidNumber,
    this.mobileNumber,
    this.email,
    this.nid,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'position': position,
    };
    
    // ✅ Only add fields if they exist and are not empty
    if (id != null && id!.isNotEmpty) {
      data['id'] = id;
    }
    if (fullName != null && fullName!.isNotEmpty) {
      data['fullName'] = fullName;
    }
    if (fatherName != null && fatherName!.isNotEmpty) {
      data['fatherName'] = fatherName;
    }
    if (motherName != null && motherName!.isNotEmpty) {
      data['motherName'] = motherName;
    }
    if (nidNumber != null && nidNumber!.isNotEmpty) {
      data['nidNumber'] = nidNumber;
    }
    if (mobileNumber != null && mobileNumber!.isNotEmpty) {
      data['mobileNumber'] = mobileNumber;
    }
    if (email != null && email!.isNotEmpty) {
      data['email'] = email;
    }
    if (nid != null && nid!.isNotEmpty) {
      data['nid'] = nid;
    }
    
    print('📤 Director.toJson: $data');
    return data;
  }

  factory Director.fromJson(Map<String, dynamic> json) {
    print('📥 Director.fromJson - Raw data: $json');
    
    // ✅ Safely extract values with fallbacks
    final String? idValue = json['id']?.toString() ?? json['_id']?.toString();
    final String? userIdValue = json['userId']?.toString() ?? json['userID']?.toString() ?? json['user_Id']?.toString();
    final String? positionValue = json['position']?.toString() ?? json['Position']?.toString();
    final String? fullNameValue = json['fullName']?.toString() ?? json['FullName']?.toString();
    final String? fatherNameValue = json['fatherName']?.toString() ?? json['FatherName']?.toString();
    final String? motherNameValue = json['motherName']?.toString() ?? json['MotherName']?.toString();
    final String? nidNumberValue = json['nidNumber']?.toString() ?? json['NidNumber']?.toString();
    final String? mobileNumberValue = json['mobileNumber']?.toString() ?? json['MobileNumber']?.toString() ?? json['phone']?.toString();
    final String? emailValue = json['email']?.toString() ?? json['Email']?.toString();
    final String? nidValue = json['nid']?.toString() ?? json['NID']?.toString() ?? json['nidId']?.toString();
    
    print('📥 Director.fromJson - Parsed:');
    print('   id: $idValue');
    print('   userId: $userIdValue');
    print('   position: $positionValue');
    print('   fullName: $fullNameValue');
    print('   fatherName: $fatherNameValue');
    print('   motherName: $motherNameValue');
    print('   nidNumber: $nidNumberValue');
    print('   mobileNumber: $mobileNumberValue');
    print('   email: $emailValue');
    print('   nid: $nidValue');
    
    return Director(
      id: idValue,
      userId: userIdValue ?? '',
      position: positionValue ?? '',
      fullName: fullNameValue,
      fatherName: fatherNameValue,
      motherName: motherNameValue,
      nidNumber: nidNumberValue,
      mobileNumber: mobileNumberValue,
      email: emailValue,
      nid: nidValue,
    );
  }

  // ✅ Helper method to check if director has all required fields
  bool get isComplete {
    return userId.isNotEmpty &&
           position.isNotEmpty &&
           fullName != null &&
           fullName!.isNotEmpty &&
           mobileNumber != null &&
           mobileNumber!.isNotEmpty &&
           email != null &&
           email!.isNotEmpty;
  }

  // ✅ Helper method to get display name
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return 'Director';
  }

  // ✅ Helper method to get formatted mobile number
  String get formattedMobile {
    if (mobileNumber == null || mobileNumber!.isEmpty) {
      return 'N/A';
    }
    return mobileNumber!;
  }

  @override
  String toString() {
    return 'Director(id: $id, userId: $userId, position: $position, '
        'fullName: $fullName, fatherName: $fatherName, motherName: $motherName, '
        'nidNumber: $nidNumber, mobileNumber: $mobileNumber, email: $email, nid: $nid)';
  }

  // ✅ Copy with method for updating
  Director copyWith({
    String? id,
    String? userId,
    String? position,
    String? fullName,
    String? fatherName,
    String? motherName,
    String? nidNumber,
    String? mobileNumber,
    String? email,
    String? nid,
  }) {
    return Director(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      position: position ?? this.position,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      nidNumber: nidNumber ?? this.nidNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      nid: nid ?? this.nid,
    );
  }
}