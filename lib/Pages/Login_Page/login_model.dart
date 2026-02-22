class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String avatar;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      avatar: json['avatar'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }
}