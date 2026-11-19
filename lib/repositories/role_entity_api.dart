import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../core/pb_client.dart';
import '../widgets/entity_form.dart';

/// Клиент ролевых коллекций PocketBase.
class RoleEntityApi {
  RoleEntityApi(Dio dio) : _pb = PbClient(dio);

  final PbClient _pb;

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

  String _collection(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final head = path.split('/').first;
    return switch (head) {
      'offers' => 'transfer_offers',
      'scout-reports' => 'scout_reports',
      'shortlist' => 'shortlist_entries',
      _ => head,
    };
  }

  Future<List<Map<String, dynamic>>> list(
    String endpoint, {
    int page = 1,
    int size = 100,
    String? q,
    String? expand,
  }) {
    return guard(() async {
      final collection = _collection(endpoint);
      final searchFilter = switch (collection) {
        'transfer_offers' when q != null && q.isNotEmpty =>
          'message ~ ${pbQuote(q)} || status ~ ${pbQuote(q)}',
        'scout_reports' when q != null && q.isNotEmpty =>
          'summary ~ ${pbQuote(q)} || verdict ~ ${pbQuote(q)}',
        'shortlist_entries' when q != null && q.isNotEmpty =>
          'note ~ ${pbQuote(q)}',
        'users' when q != null && q.isNotEmpty =>
          'username ~ ${pbQuote(q)} || email ~ ${pbQuote(q)} || name ~ ${pbQuote(q)}',
        _ when q != null && q.isNotEmpty => 'name ~ ${pbQuote(q)}',
        _ => null,
      };
      final data = await _pb.list(
        collection,
        page: page,
        perPage: size,
        filter: joinFilters([
          if (collection != 'users') pbActiveFilter(),
          searchFilter,
        ]),
        expand: expand ??
            switch (collection) {
              'transfer_offers' => 'player,team,sponsor',
              'scout_reports' => 'player,scout',
              'shortlist_entries' => 'player,scout',
              _ => null,
            },
        sort: '-created',
      );
      final pageResult = parsePageResult<Map<String, dynamic>>(
        data,
        (json) => json,
        fallbackSize: size,
      );
      return pageResult.items;
    });
  }

  Future<Map<String, dynamic>> getById(
    String endpoint,
    String id, {
    String? expand,
  }) {
    return guard(() async {
      return _pb.getOne(_collection(endpoint), id, expand: expand);
    });
  }

  Future<Map<String, dynamic>> create(
    String endpoint,
    Map<String, dynamic> body, {
    String? expand,
  }) {
    return guard(() async {
      return _pb.create(_collection(endpoint), body, expand: expand);
    });
  }

  Future<Map<String, dynamic>> update(
    String endpoint,
    String id,
    Map<String, dynamic> body, {
    String? expand,
  }) {
    return guard(() async {
      return _pb.update(_collection(endpoint), id, body, expand: expand);
    });
  }

  Future<void> delete(String endpoint, String id, {bool hard = false}) {
    return guard(() async {
      final collection = _collection(endpoint);
      if (hard) {
        await _pb.delete(collection, id);
      } else {
        await _pb.update(collection, id, {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        });
      }
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
