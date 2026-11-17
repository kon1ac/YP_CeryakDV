import 'app_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final int id;
  final String username;
  final String fullName;
  final String email;
  final AppRole role;

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    return username;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: AppRole.fromJson(json['role']),
    );
  }
}
