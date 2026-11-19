import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message, {this.count});

  final int? count;
}

class ValidationException extends ApiException {
  const ValidationException(super.message, this.errors);

  final Map<String, String> errors;
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

class RequestCancelledException implements Exception {
  const RequestCancelledException();
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  final count = body is Map && body['count'] is num
      ? (body['count'] as num).toInt()
      : null;

  if (status == 400 && body is Map) {
    final raw = body['data'];
    if (raw is Map && raw.isNotEmpty) {
      final errors = <String, String>{};
      var looksUnique = false;
      raw.forEach((key, value) {
        if (value is Map) {
          final code = '${value['code'] ?? ''}';
          final msg = '${value['message'] ?? value}';
          errors['$key'] = msg;
          if (code.contains('unique') ||
              msg.toLowerCase().contains('unique') ||
              msg.toLowerCase().contains('уже')) {
            looksUnique = true;
          }
        } else {
          errors['$key'] = '$value';
        }
      });
      if (looksUnique) {
        return ConflictException(
          message ?? 'Конфликт уникальности.',
          count: count,
        );
      }
      return ValidationException(
        message ?? 'Ошибка валидации',
        errors,
      );
    }
  }

  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
        message ?? 'Недостаточно прав для этого действия.',
      ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(
        message ?? 'Операция невозможна.',
        count: count,
      ),
    400 || 422 => ValidationException(
        message ?? 'Ошибка валидации',
        (body is Map && body['errors'] is Map)
            ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
            : const {},
      ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

ApiException mapDioError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) return existing;

  if (error.type == DioExceptionType.cancel) {
    throw const RequestCancelledException();
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Сервер не ответил вовремя.'),
    DioExceptionType.connectionError => const NetworkException(
        'Не удалось соединиться с сервером. '
        'Если сервер запущен, откройте консоль браузера и проверьте наличие ошибки CORS.',
      ),
    DioExceptionType.badResponse => mapHttpError(
        error.response?.statusCode ?? 500,
        error.response?.data,
      ),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
}
