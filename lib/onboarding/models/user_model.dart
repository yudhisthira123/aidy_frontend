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