import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

typedef TokenProvider = String? Function();
typedef TokenRefresher = Future<bool> Function();
typedef LogoutCallback = Future<void> Function();

const _authRetryExtra = 'authRetried';

bool _isAuthPath(String path) {
  final normalized = path.toLowerCase();
  return normalized.contains('/auth/') ||
      normalized.contains('auth-with-password') ||
      normalized.contains('auth-refresh');
}

Dio buildDio({
  TokenProvider? tokenProvider,
  TokenRefresher? onUnauthorized,
  LogoutCallback? onRefreshFailed,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        if (kDebugMode) {
          debugPrint(
            '[API] ← ${response.statusCode} ${response.requestOptions.uri}',
          );
        }

        final status = response.statusCode ?? 0;
        final request = response.requestOptions;

        if (status == 401 &&
            !_isAuthPath(request.path) &&
            request.extra[_authRetryExtra] != true &&
            onUnauthorized != null) {
          final refreshed = await onUnauthorized();
          if (refreshed) {
            try {
              final retryResponse = await dio.fetch<dynamic>(
                request.copyWith(
                  headers: Map<String, dynamic>.from(request.headers)
                    ..['Authorization'] = 'Bearer ${tokenProvider?.call()}',
                  extra: <String, dynamic>{
                    ...request.extra,
                    _authRetryExtra: true,
                  },
                ),
              );
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              return handler.reject(retryError);
            }
          }
          await onRefreshFailed?.call();
        }

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint(
            '[API] сбой ${error.requestOptions.uri}: ${error.type}',
          );
        }

        final status = error.response?.statusCode ?? 0;
        final request = error.requestOptions;
        if (status == 401 &&
            !_isAuthPath(request.path) &&
            request.extra[_authRetryExtra] != true &&
            onUnauthorized != null) {
          final refreshed = await onUnauthorized();
          if (refreshed) {
            try {
              final retryResponse = await dio.fetch<dynamic>(
                request.copyWith(
                  headers: Map<String, dynamic>.from(request.headers)
                    ..['Authorization'] = 'Bearer ${tokenProvider?.call()}',
                  extra: <String, dynamic>{
                    ...request.extra,
                    _authRetryExtra: true,
                  },
                ),
              );
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
          await onRefreshFailed?.call();
        }

        return handler.next(error);
      },
    ),
  );

  dio.interceptors.add(_ReadRetryInterceptor(dio));
  return dio;
}

/// Повтор только для GET: до 3 попыток с нарастающей паузой.
class _ReadRetryInterceptor extends Interceptor {
  _ReadRetryInterceptor(this._dio);

  final Dio _dio;
  static const _maxAttempts = 3;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (request.method.toUpperCase() != 'GET') {
      return handler.next(err);
    }

    final status = err.response?.statusCode ?? 0;
    if (status == 401 || status == 403) {
      return handler.next(err);
    }

    final attempt = (request.extra['retryAttempt'] as int?) ?? 0;
    final retriable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        status >= 500;

    if (!retriable || attempt >= _maxAttempts - 1) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    final delayMs = 300 * (1 << (nextAttempt - 1));
    if (kDebugMode) {
      debugPrint(
        '[API] повтор GET #$nextAttempt через ${delayMs}ms: ${request.uri}',
      );
    }
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    try {
      final response = await _dio.fetch<dynamic>(
        request.copyWith(
          extra: <String, dynamic>{
            ...request.extra,
            'retryAttempt': nextAttempt,
          },
        ),
      );
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
