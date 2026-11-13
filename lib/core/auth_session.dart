import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'page_parser.dart';

/// Учебный сеанс: при старте входит как admin, чтобы были доступны
/// физическое удаление и восстановление.
class AuthSession {
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> ensureSignedIn(Dio dio) async {
    if (_accessToken != null) return;
    try {
      final response = await dio.post<dynamic>(
        '/auth/login',
        data: {'username': 'admin', 'password': 'admin123'},
      );
      final data = asJsonMap(response.data);
      _accessToken = data['accessToken'] as String?;
      if (kDebugMode) {
        debugPrint('[API] вход выполнен как admin');
      }
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('[API] авто-вход не удался: ${mapDioError(error)}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[API] авто-вход не удался: $error');
      }
    }
  }
}
