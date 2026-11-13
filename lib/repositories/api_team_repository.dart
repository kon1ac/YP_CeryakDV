import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../models/arena.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import '../models/team_query.dart';
import 'team_repository.dart';

class ApiTeamRepository implements TeamRepository {
  ApiTeamRepository(this._dio, this._cache);

  final Dio _dio;
  final DictionaryCache _cache;
  final CancelScope _findCancel = CancelScope();

  @override
  Future<PageResult<Team>> find(TeamQuery query) => guard(() async {
        final token = _findCancel.next();
        final response = await _dio.get<dynamic>(
          '/teams',
          queryParameters: {
            if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
            if (query.city != null) 'city': query.city,
            if (query.arenaId != null) 'arenaId': query.arenaId,
            if (query.playersFrom != null) 'playersFrom': query.playersFrom,
            if (query.playersTo != null) 'playersTo': query.playersTo,
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
          Team.fromJson,
          fallbackSize: query.size,
        );
      });

  @override
  Future<Team?> findById(int id) => guard(() async {
        try {
          final response = await _dio.get<dynamic>('/teams/$id');
          return Team.fromJson(asJsonMap(response.data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Team> create(Team team) => guard(() async {
        final response =
            await _dio.post<dynamic>('/teams', data: team.toApiBody());
        _cache.invalidateTeams();
        return Team.fromJson(asJsonMap(response.data));
      });

  @override
  Future<Team> update(Team team) => guard(() async {
        final response = await _dio.put<dynamic>(
          '/teams/${team.id}',
          data: team.toApiBody(),
        );
        _cache.invalidateTeams();
        return Team.fromJson(asJsonMap(response.data));
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete<dynamic>('/teams/$id');
        _cache.invalidateTeams();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete<dynamic>(
          '/teams/$id',
          queryParameters: {'hard': true},
        );
        _cache.invalidateTeams();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post<dynamic>('/teams/$id/restore');
        _cache.invalidateTeams();
      });

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) =>
      guard(() async {
        final response = await _dio.post<dynamic>(
          '/teams/bulk-delete',
          data: {'ids': ids, 'physical': physical},
        );
        _cache.invalidateTeams();
        return asJsonMap(response.data)['deleted'] as int? ?? 0;
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
          final response = await _dio.get<dynamic>(
            '/arenas',
            queryParameters: {'size': 100, 'sort': 'name,asc'},
          );
          return parsePageResult(
            response.data,
            Arena.fromJson,
            fallbackSize: 100,
          ).items;
        }),
      );

  @override
  Future<int> playerCountForTeam(int teamId) => guard(() async {
        final team = await findById(teamId);
        return team?.rosterSize ?? 0;
      });
}
