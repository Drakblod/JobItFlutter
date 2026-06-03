class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String role; // "Foreman" or "Worker"
  final String? fcmToken;
  final String? phone;
  final String? profilePicUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.fcmToken,
    this.phone,
    this.profilePicUrl,
  });

  factory AppUser.fromJson(Map<dynamic, dynamic> json, String id) {
    return AppUser(
      id: id,
      email: json['Email'] ?? json['email'] ?? '',
      displayName: json['DisplayName'] ?? json['displayName'] ?? '',
      role: json['Role'] ?? json['role'] ?? 'Worker',
      fcmToken: json['FcmToken'] ?? json['fcmToken'],
      phone: json['Phone'] ?? json['phone'],
      profilePicUrl: json['ProfilePicUrl'] ?? json['profilePicUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Email': email,
      'DisplayName': displayName,
      'Role': role,
      'FcmToken': fcmToken,
      'Phone': phone,
      'ProfilePicUrl': profilePicUrl,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? phone,
    String? profilePicUrl,
    String? fcmToken,
  }) {
    return AppUser(
      id: id,
      email: email,
      role: role,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
