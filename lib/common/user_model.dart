class UserModel {
  String fullName;
  String email;
  String? id;
  String? token;
  String? tokenType;
  bool? isVerified;

  UserModel({
    required this.fullName,
    required this.email,
    this.id,
    this.token,
    this.tokenType
  });
}

class Categories {

}

class AuthResponse {
  final User? user;
  final String? token;
  final String? tokenType;
  final int? expiresIn;

  const AuthResponse({
    required this.user,
    required this.token,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),

      token: json['token'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user?.toJson(),
    'token': token,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
  };
}

class User {
  final String id;
  final String name;
  final String email;
  final bool verified;
  // final OnBoarding onBoarding;
  // final List<String> places;
  final List<String> competencies;
  final List<String> equipment;
  final Availability availability;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.verified,
    required this.competencies,
    required this.equipment,
    required this.availability,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      verified: json['verified'] as bool,
      competencies: List<String>.from(json['competencies'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      availability:
      Availability.fromJson(json['availability'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'verified': verified,
    'competencies': competencies,
    'equipment': equipment,
    'availability': availability.toJson(),
  };
}

class Equipment {
  final String name;
  final String place;
  final List<num> coordinates;

  const Equipment({
    required this.name,
    required this.place,
    required this.coordinates,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      name: json['name'] as String,
      place: json['place'] as String,
      coordinates: List<num>.from(json['coordinates'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'place': place,
    'coordinates': coordinates,
  };
}

class OnBoarding{
  final String status;
  final int step;

  const OnBoarding({
  required this.status,
  required this.step
  });

  factory OnBoarding.fromJson(Map<String, dynamic> json) {
    return OnBoarding(
        status: json['status'] as String,
        step: json['step']
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'step' : step
  };
}

class Availability {
  final String state;
  final DateTime until;
  final List<String> helpTypes;

  const Availability({
    required this.state,
    required this.until,
    required this.helpTypes,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      state: json['state'] as String,
      until: DateTime(2027),
      helpTypes: List<String>.from(json['helpTypes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state,
    'until': until.toUtc().toIso8601String(),
    'helpTypes': helpTypes,
  };
}