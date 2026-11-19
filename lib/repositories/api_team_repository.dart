import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../core/pb_client.dart';
import '../models/arena.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import '../models/team_query.dart';
import 'team_repository.dart';

class ApiTeamRepository implements TeamRepository {
  ApiTeamRepository(Dio dio, this._cache) : _pb = PbClient(dio);

  final DictionaryCache _cache;
  final PbClient _pb;
  final CancelScope _findCancel = CancelScope();

  String _sort(TeamQuery query) {
    final prefix = query.sortAscending ? '' : '-';
    final field = switch (query.sortField) {
      'city' => 'city',
      'foundedYear' => 'foundedYear',
      'id' => 'id',
      _ => 'name',
    };
    return '$prefix$field';
  }

  String _filter(TeamQuery query) {
    return joinFilters([
      pbActiveFilter(includeDeleted: query.includeDeleted),
      if (query.search.trim().isNotEmpty)
        'name ~ ${pbQuote(query.search.trim())} || '
            'city ~ ${pbQuote(query.search.trim())}',
      if (query.city != null) 'city = ${pbQuote(query.city!)}',
      if (query.arenaId != null && query.arenaId!.isNotEmpty)
        'arena = ${pbQuote(query.arenaId!)}',
    ]);
  }

  Future<Team> _withRoster(Team team) async {
    final data = await _pb.list(
      'players',
      perPage: 1,
      filter: joinFilters([
        'team = ${pbQuote(team.id)}',
        pbActiveFilter(),
      ]),
    );
    final total = (data['totalItems'] as num?)?.toInt() ?? 0;
    return team.copyWith(rosterSize: total);
  }

  @override
  Future<PageResult<Team>> find(TeamQuery query) => guard(() async {
        _findCancel.next();
        if (query.simulateError) {
          throw const ServerException('Учебная ошибка 500');
        }
        final data = await _pb.list(
          'teams',
          page: query.page,
          perPage: query.size,
          filter: _filter(query),
          sort: _sort(query),
          expand: 'arena,sponsor',
        );
        final page = parsePageResult(data, Team.fromJson, fallbackSize: query.size);
        final items = <Team>[];
        for (final team in page.items) {
          var decorated = await _withRoster(team);
          if (query.playersFrom != null &&
              decorated.rosterSize < query.playersFrom!) {
            continue;
          }
          if (query.playersTo != null &&
              decorated.rosterSize > query.playersTo!) {
            continue;
          }
          items.add(decorated);
        }
        // If roster filters applied client-side, total may be approximate.
        final filtered = query.playersFrom != null || query.playersTo != null;
        return PageResult(
          items: filtered ? items : [
            for (final t in page.items) await _withRoster(t),
          ],
          page: page.page,
          size: page.size,
          total: filtered ? items.length : page.total,
        );
      });

  @override
  Future<Team?> findById(String id) => guard(() async {
        try {
          final data = await _pb.getOne('teams', id, expand: 'arena,sponsor');
          return _withRoster(Team.fromJson(data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Team> create(Team team) => guard(() async {
        final data =
            await _pb.create('teams', team.toApiBody(), expand: 'arena');
        _cache.invalidateTeams();
        return _withRoster(Team.fromJson(data));
      });

  @override
  Future<Team> update(Team team) => guard(() async {
        final data = await _pb.update(
          'teams',
          team.id,
          team.toApiBody(),
          expand: 'arena',
        );
        _cache.invalidateTeams();
        return _withRoster(Team.fromJson(data));
      });

  @override
  Future<void> softDelete(String id) => guard(() async {
        await _pb.update('teams', id, {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        });
        _cache.invalidateTeams();
      });

  @override
  Future<void> hardDelete(String id) => guard(() async {
        await _pb.delete('teams', id);
        _cache.invalidateTeams();
      });

  @override
  Future<void> restore(String id) => guard(() async {
        await _pb.update('teams', id, {'deletedAt': null});
        _cache.invalidateTeams();
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
        final page = await find(const TeamQuery(size: 100));
        final cities = {
          for (final team in page.items)
            if (team.city.trim().isNotEmpty) team.city,
        }.toList()
          ..sort();
        return cities;
      });

  @override
  Future<List<Arena>> arenas() => _cache.arenas(
        () => guard(() async {
          final data = await _pb.list(
            'arenas',
            perPage: 100,
            filter: pbActiveFilter(),
            sort: 'name',
          );
          return parsePageResult(
            data,
            Arena.fromJson,
            fallbackSize: 100,
          ).items;
        }),
      );

  @override
  Future<int> playerCountForTeam(String teamId) => guard(() async {
        final team = await findById(teamId);
        return team?.rosterSize ?? 0;
      });
}
