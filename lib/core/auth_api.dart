import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_exceptions.dart';
import 'page_parser.dart';

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
    final userJson = json['user'];
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AppUser.fromJson(
        userJson is Map
            ? Map<String, dynamic>.from(userJson)
            : const <String, dynamic>{},
      ),
    );
  }
}

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String username,
    required String password,
  }) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthTokens.fromJson(asJsonMap(response.data));
    });
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
        },
      );
      return AppUser.fromJson(asJsonMap(response.data));
    });
  }

  Future<AuthTokens> refresh(String refreshToken) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthTokens.fromJson(asJsonMap(response.data));
    });
  }

  Future<AppUser> me() {
    return guard(() async {
      final response = await _dio.get<dynamic>('/auth/me');
      return AppUser.fromJson(asJsonMap(response.data));
    });
  }

  Future<void> logout() {
    return guard(() async {
      await _dio.post<dynamic>('/auth/logout');
    });
  }
}
