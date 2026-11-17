import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../widgets/entity_form.dart';

/// Тонкий клиент для ролевых коллекций (отчёты / шортлист / users / офферы).
class RoleEntityApi {
  RoleEntityApi(this._dio);

  final Dio _dio;

  /// Кэш справочников для селектов форм.
  static List<FormOption>? _playerOptions;
  static Future<List<FormOption>>? _playerOptionsFuture;
  static List<FormOption>? _teamOptions;
  static Future<List<FormOption>>? _teamOptionsFuture;

  static void invalidatePlayerOptions() {
    _playerOptions = null;
    _playerOptionsFuture = null;
  }

  static void invalidateTeamOptions() {
    _teamOptions = null;
    _teamOptionsFuture = null;
  }

  Future<List<Map<String, dynamic>>> list(
    String endpoint, {
    int page = 1,
    int size = 100,
    String? q,
  }) {
    return guard(() async {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: {
          'page': page,
          'size': size,
          if (q != null && q.isNotEmpty) 'q': q,
        },
      );
      final pageResult = parsePageResult<Map<String, dynamic>>(
        response.data,
        (json) => json,
        fallbackSize: size,
      );
      return pageResult.items;
    });
  }

  Future<Map<String, dynamic>> getById(String endpoint, int id) {
    return guard(() async {
      final response = await _dio.get<dynamic>('$endpoint/$id');
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> create(
    String endpoint,
    Map<String, dynamic> body,
  ) {
    return guard(() async {
      final response = await _dio.post<dynamic>(endpoint, data: body);
      return asJsonMap(response.data);
    });
  }

  Future<Map<String, dynamic>> update(
    String endpoint,
    int id,
    Map<String, dynamic> body,
  ) {
    return guard(() async {
      final response = await _dio.put<dynamic>('$endpoint/$id', data: body);
      return asJsonMap(response.data);
    });
  }

  Future<void> delete(String endpoint, int id, {bool hard = false}) {
    return guard(() async {
      await _dio.delete<dynamic>(
        '$endpoint/$id',
        queryParameters: hard ? const {'hard': 'true'} : null,
      );
    });
  }

  Future<List<FormOption>> playerOptions() async {
    final cached = _playerOptions;
    if (cached != null) return cached;
    return _playerOptionsFuture ??= _loadNamedOptions(
      endpoint: '/players',
      setter: (options) => _playerOptions = options,
      onFail: () => _playerOptionsFuture = null,
      fallbackLabel: (id) => 'Игрок #$id',
    );
  }

  Future<List<FormOption>> teamOptions() async {
    final cached = _teamOptions;
    if (cached != null) return cached;
    return _teamOptionsFuture ??= _loadNamedOptions(
      endpoint: '/teams',
      setter: (options) => _teamOptions = options,
      onFail: () => _teamOptionsFuture = null,
      fallbackLabel: (id) => 'Команда #$id',
    );
  }

  Future<List<FormOption>> _loadNamedOptions({
    required String endpoint,
    required void Function(List<FormOption> options) setter,
    required void Function() onFail,
    required String Function(Object id) fallbackLabel,
  }) async {
    try {
      final items = await list(endpoint, size: 200);
      final options = [
        for (final item in items)
          FormOption(
            '${item['id']}',
            (item['name'] as String?)?.trim().isNotEmpty == true
                ? item['name'] as String
                : fallbackLabel(item['id'] ?? '?'),
          ),
      ]..sort((a, b) => a.label.compareTo(b.label));
      setter(options);
      return options;
    } catch (_) {
      onFail();
      rethrow;
    }
  }
}
