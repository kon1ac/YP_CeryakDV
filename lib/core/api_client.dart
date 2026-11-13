import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

typedef TokenProvider = String? Function();

Dio buildDio({TokenProvider? tokenProvider}) {
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
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ← ${response.statusCode} ${response.requestOptions.uri}',
          );
        }
        final status = response.statusCode ?? 0;
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
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] сбой ${error.requestOptions.uri}: ${error.type}',
          );
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

    final attempt = (request.extra['retryAttempt'] as int?) ?? 0;
    final status = err.response?.statusCode ?? 0;
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
