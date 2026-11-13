import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../models/arena.dart';
import '../models/arena_query.dart';
import '../models/page_result.dart';
import 'arena_repository.dart';

class ApiArenaRepository implements ArenaRepository {
  ApiArenaRepository(this._dio, this._cache);

  final Dio _dio;
  final DictionaryCache _cache;
  final CancelScope _findCancel = CancelScope();

  @override
  Future<PageResult<Arena>> find(ArenaQuery query) => guard(() async {
        final token = _findCancel.next();
        final response = await _dio.get<dynamic>(
          '/arenas',
          queryParameters: {
            if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
            if (query.city != null) 'city': query.city,
            if (query.capacityFrom != null) 'capacityFrom': query.capacityFrom,
            if (query.capacityTo != null) 'capacityTo': query.capacityTo,
            'sort':
                '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
            'page': query.page,
            'size': query.size,
            if (query.includeDeleted) 'includeDeleted': true,
            if (query.simulateError) '__fail': 500,
          },
          cancelToken: token,
        );
        return parsePageResult(
          response.data,
          Arena.fromJson,
          fallbackSize: query.size,
        );
      });

  @override
  Future<Arena?> findById(int id) => guard(() async {
        try {
          final response = await _dio.get<dynamic>('/arenas/$id');
          return Arena.fromJson(asJsonMap(response.data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Arena> create(Arena arena) => guard(() async {
        final response =
            await _dio.post<dynamic>('/arenas', data: arena.toApiBody());
        _cache.invalidateArenas();
        return Arena.fromJson(asJsonMap(response.data));
      });

  @override
  Future<Arena> update(Arena arena) => guard(() async {
        final response = await _dio.put<dynamic>(
          '/arenas/${arena.id}',
          data: arena.toApiBody(),
        );
        _cache.invalidateArenas();
        return Arena.fromJson(asJsonMap(response.data));
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete<dynamic>('/arenas/$id');
        _cache.invalidateArenas();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        try {
          await _dio.delete<dynamic>(
            '/arenas/$id',
            queryParameters: {'hard': true},
          );
          _cache.invalidateArenas();
        } on ConflictException catch (error) {
          throw RelatedRecordsException(
            error.message,
            error.count ?? 0,
          );
        }
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post<dynamic>('/arenas/$id/restore');
        _cache.invalidateArenas();
      });

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) =>
      guard(() async {
        final response = await _dio.post<dynamic>(
          '/arenas/bulk-delete',
          data: {'ids': ids, 'physical': physical},
        );
        _cache.invalidateArenas();
        return asJsonMap(response.data)['deleted'] as int? ?? 0;
      });

  @override
  Future<List<String>> cityNames() => guard(() async {
        final page = await find(const ArenaQuery(size: 100));
        final cities = {
          for (final arena in page.items)
            if (arena.city.trim().isNotEmpty) arena.city,
        }.toList()
          ..sort();
        return cities;
      });

  @override
  Future<int> teamCountForArena(int arenaId) => guard(() async {
        final arena = await findById(arenaId);
        return arena?.teamCount ?? 0;
      });

  @override
  Future<int> teamsLinkedTo(int arenaId) => teamCountForArena(arenaId);
}
