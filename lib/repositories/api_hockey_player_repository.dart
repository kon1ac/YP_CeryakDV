import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../core/pb_client.dart';
import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/contract.dart';
import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../models/team.dart';
import 'hockey_player_repository.dart';

class ApiHockeyPlayerRepository implements HockeyPlayerRepository {
  ApiHockeyPlayerRepository(Dio dio, this._cache)
      : _pb = PbClient(dio);

  final DictionaryCache _cache;
  final PbClient _pb;
  final CancelScope _findCancel = CancelScope();

  String _sort(PlayerQuery query) {
    final prefix = query.sortAscending ? '' : '-';
    final field = switch (query.sortField) {
      'price' => 'price',
      'category' => 'category',
      'status' => 'status',
      'jerseyNumber' => 'jerseyNumber',
      'id' => 'id',
      _ => 'name',
    };
    return '$prefix$field';
  }

  String _filter(PlayerQuery query) {
    final parts = <String?>[
      pbActiveFilter(includeDeleted: query.includeDeleted),
      if (query.search.trim().isNotEmpty)
        'name ~ ${pbQuote(query.search.trim())} || '
            'description ~ ${pbQuote(query.search.trim())}',
      if (query.category != null) 'category = ${pbQuote(query.category!)}',
      if (query.status != null) 'status = ${pbQuote(query.status!)}',
      if (query.teamId != null && query.teamId!.isNotEmpty)
        'team = ${pbQuote(query.teamId!)}',
      if (query.priceFrom != null) 'price >= ${query.priceFrom}',
      if (query.priceTo != null) 'price <= ${query.priceTo}',
    ];
    return joinFilters(parts);
  }

  Future<HockeyPlayer> _hydrate(Map<String, dynamic> json) async {
    final player = HockeyPlayer.fromJson(json);
    final achievements = await _loadAchievementLinks(player.id);
    Contract? contract = player.contract;
    if (contract == null) {
      contract = await _loadContract(player.id);
    }
    return player.copyWith(
      achievementIds: achievements.$1,
      achievementNames: achievements.$2,
      contract: contract,
    );
  }

  Future<(List<String>, List<String>)> _loadAchievementLinks(
    String playerId,
  ) async {
    if (playerId.isEmpty) return (const <String>[], const <String>[]);
    final data = await _pb.list(
      'player_achievements',
      perPage: 100,
      filter: 'player = ${pbQuote(playerId)}',
      expand: 'achievement',
    );
    final items = data['items'];
    if (items is! List) return (const <String>[], const <String>[]);
    final ids = <String>[];
    final names = <String>[];
    for (final item in items) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final expand = map['expand'];
      final expandMap =
          expand is Map ? Map<String, dynamic>.from(expand) : const {};
      final achievement = expandMap['achievement'];
      final achievementMap = achievement is Map
          ? Map<String, dynamic>.from(achievement)
          : const {};
      final id = '${map['achievement'] ?? achievementMap['id'] ?? ''}';
      if (id.isEmpty) continue;
      ids.add(id);
      final name = achievementMap['name'] as String? ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    return (ids, names);
  }

  Future<Contract?> _loadContract(String playerId) async {
    final data = await _pb.list(
      'contracts',
      perPage: 1,
      filter: 'player = ${pbQuote(playerId)}',
    );
    final items = data['items'];
    if (items is! List || items.isEmpty) return null;
    final first = items.first;
    if (first is! Map) return null;
    return Contract.fromJson(Map<String, dynamic>.from(first));
  }

  Future<void> _syncAchievements(
    String playerId,
    List<String> achievementIds,
  ) async {
    final existing = await _pb.list(
      'player_achievements',
      perPage: 200,
      filter: 'player = ${pbQuote(playerId)}',
    );
    final items = existing['items'];
    final current = <String, String>{};
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        final id = '${item['id'] ?? ''}';
        final achievementId = '${item['achievement'] ?? ''}';
        if (id.isNotEmpty && achievementId.isNotEmpty) {
          current[achievementId] = id;
        }
      }
    }
    final wanted = achievementIds.toSet();
    for (final entry in current.entries) {
      if (!wanted.contains(entry.key)) {
        await _pb.delete('player_achievements', entry.value);
      }
    }
    for (final achievementId in wanted) {
      if (current.containsKey(achievementId)) continue;
      await _pb.create('player_achievements', {
        'player': playerId,
        'achievement': achievementId,
      });
    }
  }

  Future<void> _syncContract(HockeyPlayer player) async {
    final contract = player.contract;
    final existing = await _loadContract(player.id);
    if (contract == null) {
      if (existing != null && existing.id.isNotEmpty) {
        await _pb.delete('contracts', existing.id);
      }
      return;
    }
    final body = contract.copyWith(playerId: player.id).toApiBody();
    if (existing == null || existing.id.isEmpty) {
      await _pb.create('contracts', body);
    } else {
      await _pb.update('contracts', existing.id, body);
    }
  }

  @override
  Future<PageResult<HockeyPlayer>> find(PlayerQuery query) => guard(() async {
        _findCancel.next();
        if (query.simulateError) {
          throw const ServerException('Учебная ошибка 500');
        }
        var filter = _filter(query);
        if (query.achievementId != null && query.achievementId!.isNotEmpty) {
          final links = await _pb.list(
            'player_achievements',
            perPage: 200,
            filter: 'achievement = ${pbQuote(query.achievementId!)}',
          );
          final playerIds = <String>{
            if (links['items'] is List)
              for (final item in links['items'] as List)
                if (item is Map && '${item['player'] ?? ''}'.isNotEmpty)
                  '${item['player']}',
          };
          if (playerIds.isEmpty) {
            return PageResult<HockeyPlayer>(
              items: const [],
              page: query.page,
              size: query.size,
              total: 0,
            );
          }
          final idFilter = playerIds.map(pbQuote).join(' || id = ');
          filter = joinFilters([filter, 'id = $idFilter']);
        }

        final data = await _pb.list(
          'players',
          page: query.page,
          perPage: query.size,
          filter: filter,
          sort: _sort(query),
          expand: 'team',
        );
        final page = parsePageResult(
          data,
          HockeyPlayer.fromJson,
          fallbackSize: query.size,
        );
        final hydrated = <HockeyPlayer>[];
        for (final item in page.items) {
          hydrated.add(await _hydrate(item.toJson()..['id'] = item.id
            ..['teamId'] = item.teamId
            ..['teamName'] = item.teamName
            ..['name'] = item.name
            ..['description'] = item.description
            ..['price'] = item.price
            ..['category'] = item.category
            ..['jerseyNumber'] = item.jerseyNumber
            ..['status'] = item.status
            ..['notes'] = item.notes
            ..['deletedAt'] = item.deletedAt?.toIso8601String()));
        }
        // Simpler: re-fetch details via id-based hydrate from raw items
        final rawItems = data['items'];
        if (rawItems is List) {
          hydrated.clear();
          for (final raw in rawItems) {
            if (raw is Map) {
              hydrated.add(await _hydrate(Map<String, dynamic>.from(raw)));
            }
          }
        }
        return PageResult(
          items: hydrated,
          page: page.page,
          size: page.size,
          total: page.total,
        );
      });

  @override
  Future<HockeyPlayer?> findById(String id) => guard(() async {
        try {
          final data = await _pb.getOne('players', id, expand: 'team');
          return _hydrate(data);
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<HockeyPlayer> create(HockeyPlayer player) => guard(() async {
        final created = await _pb.create(
          'players',
          player.toApiBody(),
          expand: 'team',
        );
        final id = '${created['id'] ?? ''}';
        await _syncAchievements(id, player.achievementIds);
        if (player.contract != null) {
          await _pb.create(
            'contracts',
            player.contract!.copyWith(playerId: id).toApiBody(),
          );
        }
        _cache.invalidateTeams();
        return (await findById(id))!;
      });

  @override
  Future<HockeyPlayer> update(HockeyPlayer player) => guard(() async {
        await _pb.update(
          'players',
          player.id,
          player.toApiBody(),
          expand: 'team',
        );
        await _syncAchievements(player.id, player.achievementIds);
        await _syncContract(player);
        _cache.invalidateTeams();
        return (await findById(player.id))!;
      });

  @override
  Future<void> softDelete(String id) => guard(() async {
        await _pb.update('players', id, {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        });
      });

  @override
  Future<void> hardDelete(String id) => guard(() async {
        await _pb.delete('players', id);
        _cache.invalidateTeams();
      });

  @override
  Future<void> restore(String id) => guard(() async {
        await _pb.update('players', id, {'deletedAt': null});
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
  Future<List<Team>> teams() => _cache.teams(
        () => guard(() async {
          final data = await _pb.list(
            'teams',
            perPage: 100,
            filter: pbActiveFilter(),
            sort: 'name',
            expand: 'arena',
          );
          return parsePageResult(
            data,
            Team.fromJson,
            fallbackSize: 100,
          ).items;
        }),
      );

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
  Future<List<Achievement>> achievements() => _cache.achievements(
        () => guard(() async {
          final data = await _pb.list(
            'achievements',
            perPage: 100,
            filter: pbActiveFilter(),
            sort: 'name',
          );
          return parsePageResult(
            data,
            Achievement.fromJson,
            fallbackSize: 100,
          ).items;
        }),
      );

  @override
  Future<bool> jerseyNumberTaken(int number, {String? exceptId}) =>
      guard(() async {
        final filter = joinFilters([
          'jerseyNumber = $number',
          pbActiveFilter(),
          if (exceptId != null && exceptId.isNotEmpty)
            'id != ${pbQuote(exceptId)}',
        ]);
        final data = await _pb.list('players', perPage: 1, filter: filter);
        final total = (data['totalItems'] as num?)?.toInt() ?? 0;
        return total > 0;
      });

  @override
  Future<bool> contractEmailTaken(String email, {String? exceptId}) =>
      guard(() async {
        final needle = email.trim().toLowerCase();
        final filter = 'email = ${pbQuote(needle)}';
        final data = await _pb.list('contracts', perPage: 5, filter: filter);
        final items = data['items'];
        if (items is! List) return false;
        for (final item in items) {
          if (item is! Map) continue;
          final playerId = '${item['player'] ?? ''}';
          if (exceptId != null && playerId == exceptId) continue;
          return true;
        }
        return false;
      });
}
