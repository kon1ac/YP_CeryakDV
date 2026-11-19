import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_exceptions.dart';
import 'pb_client.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ??
        json['accessToken'] as String? ??
        '';
    final userJson = json['record'] ?? json['user'];
    return AuthTokens(
      accessToken: token,
      refreshToken: json['refreshToken'] as String? ?? token,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 3600,
      user: AppUser.fromJson(
        userJson is Map
            ? Map<String, dynamic>.from(userJson)
            : const <String, dynamic>{},
      ),
    );
  }
}

class AuthApi {
  AuthApi(Dio dio) : _pb = PbClient(dio);

  final PbClient _pb;

  Future<AuthTokens> login({
    required String username,
    required String password,
  }) {
    return guard(() async {
      final identity = username.trim();
      // PocketBase passwordAuth identityFields = email (username без UNIQUE).
      final resolved = identity.contains('@')
          ? identity
          : '$identity@hockey.local';
      final data = await _pb.authWithPassword(
        identity: resolved,
        password: password,
      );
      return AuthTokens.fromJson(data);
    });
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) {
    return guard(() async {
      final data = await _pb.authRegister({
        'username': username,
        'email': email,
        'emailVisibility': true,
        'password': password,
        'passwordConfirm': password,
        'name': fullName,
        'fullName': fullName,
        'role': 'scout',
      });
      return AppUser.fromJson(data);
    });
  }

  Future<AuthTokens> refresh(String refreshToken) {
    return guard(() async {
      // PocketBase uses the same auth token for refresh.
      final data = await _pb.authRefresh();
      final tokens = AuthTokens.fromJson(data);
      if (tokens.accessToken.isEmpty && refreshToken.isNotEmpty) {
        return AuthTokens(
          accessToken: refreshToken,
          refreshToken: refreshToken,
          expiresIn: tokens.expiresIn,
          user: tokens.user,
        );
      }
      return tokens;
    });
  }

  Future<AppUser> me() {
    return guard(() async {
      final data = await _pb.authRefresh();
      final tokens = AuthTokens.fromJson(data);
      return tokens.user;
    });
  }

  Future<void> logout() async {
    // Client-side only for PocketBase.
  }
}
