import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../core/pb_client.dart';
import '../models/arena.dart';
import '../models/arena_query.dart';
import '../models/page_result.dart';
import 'arena_repository.dart';

class ApiArenaRepository implements ArenaRepository {
  ApiArenaRepository(Dio dio, this._cache) : _pb = PbClient(dio);

  final DictionaryCache _cache;
  final PbClient _pb;
  final CancelScope _findCancel = CancelScope();

  String _sort(ArenaQuery query) {
    final prefix = query.sortAscending ? '' : '-';
    final field = switch (query.sortField) {
      'city' => 'city',
      'capacity' => 'capacity',
      'id' => 'id',
      _ => 'name',
    };
    return '$prefix$field';
  }

  String _filter(ArenaQuery query) {
    return joinFilters([
      pbActiveFilter(includeDeleted: query.includeDeleted),
      if (query.search.trim().isNotEmpty)
        'name ~ ${pbQuote(query.search.trim())} || '
            'city ~ ${pbQuote(query.search.trim())}',
      if (query.city != null) 'city = ${pbQuote(query.city!)}',
      if (query.capacityFrom != null) 'capacity >= ${query.capacityFrom}',
      if (query.capacityTo != null) 'capacity <= ${query.capacityTo}',
    ]);
  }

  Future<Arena> _withTeamCount(Arena arena) async {
    final count = await teamCountForArena(arena.id);
    return arena.copyWith(teamCount: count);
  }

  @override
  Future<PageResult<Arena>> find(ArenaQuery query) => guard(() async {
        _findCancel.next();
        if (query.simulateError) {
          throw const ServerException('Учебная ошибка 500');
        }
        final data = await _pb.list(
          'arenas',
          page: query.page,
          perPage: query.size,
          filter: _filter(query),
          sort: _sort(query),
        );
        final page =
            parsePageResult(data, Arena.fromJson, fallbackSize: query.size);
        return PageResult(
          items: [for (final a in page.items) await _withTeamCount(a)],
          page: page.page,
          size: page.size,
          total: page.total,
        );
      });

  @override
  Future<Arena?> findById(String id) => guard(() async {
        try {
          final data = await _pb.getOne('arenas', id);
          return _withTeamCount(Arena.fromJson(data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Arena> create(Arena arena) => guard(() async {
        final data = await _pb.create('arenas', arena.toApiBody());
        _cache.invalidateArenas();
        return Arena.fromJson(data);
      });

  @override
  Future<Arena> update(Arena arena) => guard(() async {
        final data = await _pb.update('arenas', arena.id, arena.toApiBody());
        _cache.invalidateArenas();
        return Arena.fromJson(data);
      });

  @override
  Future<void> softDelete(String id) => guard(() async {
        await _pb.update('arenas', id, {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        });
        _cache.invalidateArenas();
      });

  @override
  Future<void> hardDelete(String id) => guard(() async {
        final linked = await teamsLinkedTo(id);
        if (linked > 0) {
          throw ConflictException(
            'На арену ссылаются команды: $linked.',
            count: linked,
          );
        }
        await _pb.delete('arenas', id);
        _cache.invalidateArenas();
      });

  @override
  Future<void> restore(String id) => guard(() async {
        await _pb.update('arenas', id, {'deletedAt': null});
        _cache.invalidateArenas();
      });

  @override
  Future<int> deleteMany(List<String> ids, {bool physical = false}) =>
      guard(() async {
        var count = 0;
        for (final id in ids) {
          if (physical) {
            await hardDelete(id);
          } else {
            await softDelete(id);
          }
          count++;
        }
        return count;
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
  Future<int> teamCountForArena(String arenaId) => guard(() async {
        final data = await _pb.list(
          'teams',
          perPage: 1,
          filter: joinFilters([
            'arena = ${pbQuote(arenaId)}',
            pbActiveFilter(),
          ]),
        );
        return (data['totalItems'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> teamsLinkedTo(String arenaId) => teamCountForArena(arenaId);
}
