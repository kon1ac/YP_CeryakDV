import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'page_parser.dart';

/// Helpers for PocketBase REST (`/collections/.../records`).
class PbClient {
  PbClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> authWithPassword({
    required String identity,
    required String password,
  }) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/collections/users/auth-with-password',
        data: {'identity': identity, 'password': password},
      );
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> authRefresh() {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/collections/users/auth-refresh',
      );
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> authRegister(Map<String, dynamic> body) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/collections/users/records',
        data: body,
      );
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> list(
    String collection, {
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
    String? expand,
    Map<String, dynamic>? query,
  }) {
    return guard(() async {
      final response = await _dio.get<dynamic>(
        '/collections/$collection/records',
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (filter != null && filter.isNotEmpty) 'filter': filter,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          if (expand != null && expand.isNotEmpty) 'expand': expand,
          ...?query,
        },
      );
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> getOne(
    String collection,
    String id, {
    String? expand,
  }) {
    return guard(() async {
      final response = await _dio.get<dynamic>(
        '/collections/$collection/records/$id',
        queryParameters: {
          if (expand != null && expand.isNotEmpty) 'expand': expand,
        },
      );
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> create(
    String collection,
    Map<String, dynamic> body, {
    String? expand,
  }) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/collections/$collection/records',
        data: body,
        queryParameters: {
          if (expand != null && expand.isNotEmpty) 'expand': expand,
        },
      );
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> update(
    String collection,
    String id,
    Map<String, dynamic> body, {
    String? expand,
  }) {
    return guard(() async {
      final response = await _dio.patch<dynamic>(
        '/collections/$collection/records/$id',
        data: body,
        queryParameters: {
          if (expand != null && expand.isNotEmpty) 'expand': expand,
        },
      );
      return asJsonMap(response.data);
    });
  }

  Future<void> delete(String collection, String id) {
    return guard(() async {
      await _dio.delete<dynamic>('/collections/$collection/records/$id');
    });
  }
}

String pbQuote(String value) => "'${value.replaceAll("'", "\\'")}'";

String? pbActiveFilter({bool includeDeleted = false}) {
  if (includeDeleted) return null;
  // PocketBase 0.34+: empty optional date → ?= (plain = "" throws 400).
  return 'deletedAt ?= null';
}

String joinFilters(Iterable<String?> parts) {
  final list = [for (final p in parts) if (p != null && p.isNotEmpty) '($p)'];
  if (list.isEmpty) return '';
  return list.join(' && ');
}

ApiException mapPbError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) return existing;
  final status = error.response?.statusCode ?? 0;
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message']?.toString();
    final raw = data['data'];
    if (status == 400 && raw is Map && raw.isNotEmpty) {
      final errors = <String, String>{};
      raw.forEach((key, value) {
        if (value is Map && value['message'] != null) {
          errors['$key'] = '${value['message']}';
        } else {
          errors['$key'] = '$value';
        }
      });
      return ValidationException(message ?? 'Ошибка валидации', errors);
    }
  }
  return mapDioError(error);
}
