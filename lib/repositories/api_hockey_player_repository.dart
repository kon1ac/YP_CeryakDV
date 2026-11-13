import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../models/team.dart';
import 'hockey_player_repository.dart';

class ApiHockeyPlayerRepository implements HockeyPlayerRepository {
  ApiHockeyPlayerRepository(this._dio, this._cache);

  final Dio _dio;
  final DictionaryCache _cache;
  final CancelScope _findCancel = CancelScope();

  @override
  Future<PageResult<HockeyPlayer>> find(PlayerQuery query) => guard(() async {
        final token = _findCancel.next();
        final response = await _dio.get<dynamic>(
          '/players',
          queryParameters: {
            if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
            if (query.category != null) 'category': query.category,
            if (query.teamId != null) 'teamId': query.teamId,
            if (query.achievementId != null)
              'achievementId': query.achievementId,
            if (query.priceFrom != null) 'priceFrom': query.priceFrom,
            if (query.priceTo != null) 'priceTo': query.priceTo,
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
          HockeyPlayer.fromJson,
          fallbackSize: query.size,
        );
      });

  @override
  Future<HockeyPlayer?> findById(int id) => guard(() async {
        try {
          final response = await _dio.get<dynamic>('/players/$id');
          return HockeyPlayer.fromJson(asJsonMap(response.data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<HockeyPlayer> create(HockeyPlayer player) => guard(() async {
        final response = await _dio.post<dynamic>(
          '/players',
          data: player.toApiBody(),
        );
        _cache.invalidateTeams();
        return HockeyPlayer.fromJson(asJsonMap(response.data));
      });

  @override
  Future<HockeyPlayer> update(HockeyPlayer player) => guard(() async {
        final response = await _dio.put<dynamic>(
          '/players/${player.id}',
          data: player.toApiBody(),
        );
        _cache.invalidateTeams();
        return HockeyPlayer.fromJson(asJsonMap(response.data));
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete<dynamic>('/players/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete<dynamic>(
          '/players/$id',
          queryParameters: {'hard': true},
        ),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post<dynamic>('/players/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) =>
      guard(() async {
        final response = await _dio.post<dynamic>(
          '/players/bulk-delete',
          data: {'ids': ids, 'physical': physical},
        );
        return asJsonMap(response.data)['deleted'] as int? ?? 0;
      });

  @override
  Future<List<Team>> teams() => _cache.teams(
        () => guard(() async {
          final response = await _dio.get<dynamic>(
            '/teams',
            queryParameters: {'size': 100, 'sort': 'name,asc'},
          );
          return parsePageResult(
            response.data,
            Team.fromJson,
            fallbackSize: 100,
          ).items;
        }),
      );

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
  Future<List<Achievement>> achievements() => _cache.achievements(
        () => guard(() async {
          final response = await _dio.get<dynamic>(
            '/achievements',
            queryParameters: {'size': 100, 'sort': 'name,asc'},
          );
          return parsePageResult(
            response.data,
            Achievement.fromJson,
            fallbackSize: 100,
          ).items;
        }),
      );

  @override
  Future<bool> jerseyNumberTaken(int number, {int? exceptId}) =>
      guard(() async {
        final response = await _dio.get<dynamic>(
          '/players',
          queryParameters: {
            'search': '$number',
            'size': 50,
            'includeDeleted': true,
          },
        );
        final page = parsePageResult(
          response.data,
          HockeyPlayer.fromJson,
          fallbackSize: 50,
        );
        return page.items.any(
          (player) =>
              player.jerseyNumber == number &&
              (exceptId == null || player.id != exceptId),
        );
      });

  @override
  Future<bool> contractEmailTaken(String email, {int? exceptId}) =>
      guard(() async {
        final needle = email.trim().toLowerCase();
        final response = await _dio.get<dynamic>(
          '/players',
          queryParameters: {
            'search': needle,
            'size': 50,
            'includeDeleted': true,
          },
        );
        final page = parsePageResult(
          response.data,
          HockeyPlayer.fromJson,
          fallbackSize: 50,
        );
        return page.items.any(
          (player) =>
              (player.contract?.email.toLowerCase() ?? '') == needle &&
              (exceptId == null || player.id != exceptId),
        );
      });
}
