import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../core/pb_client.dart';
import '../models/achievement.dart';
import '../models/achievement_query.dart';
import '../models/page_result.dart';
import 'achievement_repository.dart';

class ApiAchievementRepository implements AchievementRepository {
  ApiAchievementRepository(Dio dio, this._cache) : _pb = PbClient(dio);

  final DictionaryCache _cache;
  final PbClient _pb;
  final CancelScope _findCancel = CancelScope();

  String _sort(AchievementQuery query) {
    final prefix = query.sortAscending ? '' : '-';
    final field = switch (query.sortField) {
      'year' => 'year',
      'description' => 'description',
      'id' => 'id',
      _ => 'name',
    };
    return '$prefix$field';
  }

  String _filter(AchievementQuery query) {
    return joinFilters([
      pbActiveFilter(includeDeleted: query.includeDeleted),
      if (query.search.trim().isNotEmpty)
        'name ~ ${pbQuote(query.search.trim())} || '
            'description ~ ${pbQuote(query.search.trim())}',
      if (query.yearFrom != null) 'year >= ${query.yearFrom}',
      if (query.yearTo != null) 'year <= ${query.yearTo}',
    ]);
  }

  Future<Achievement> _withHolders(Achievement achievement) async {
    final count = await holderCountForAchievement(achievement.id);
    return achievement.copyWith(holderCount: count);
  }

  @override
  Future<PageResult<Achievement>> find(AchievementQuery query) =>
      guard(() async {
        _findCancel.next();
        if (query.simulateError) {
          throw const ServerException('Учебная ошибка 500');
        }
        final data = await _pb.list(
          'achievements',
          page: query.page,
          perPage: query.size,
          filter: _filter(query),
          sort: _sort(query),
        );
        final page = parsePageResult(
          data,
          Achievement.fromJson,
          fallbackSize: query.size,
        );
        return PageResult(
          items: [for (final a in page.items) await _withHolders(a)],
          page: page.page,
          size: page.size,
          total: page.total,
        );
      });

  @override
  Future<Achievement?> findById(String id) => guard(() async {
        try {
          final data = await _pb.getOne('achievements', id);
          return _withHolders(Achievement.fromJson(data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Achievement> create(Achievement achievement) => guard(() async {
        final data =
            await _pb.create('achievements', achievement.toApiBody());
        _cache.invalidateAchievements();
        return Achievement.fromJson(data);
      });

  @override
  Future<Achievement> update(Achievement achievement) => guard(() async {
        final data = await _pb.update(
          'achievements',
          achievement.id,
          achievement.toApiBody(),
        );
        _cache.invalidateAchievements();
        return Achievement.fromJson(data);
      });

  @override
  Future<void> softDelete(String id) => guard(() async {
        await _pb.update('achievements', id, {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        });
        _cache.invalidateAchievements();
      });

  @override
  Future<void> hardDelete(String id) => guard(() async {
        await _pb.delete('achievements', id);
        _cache.invalidateAchievements();
      });

  @override
  Future<void> restore(String id) => guard(() async {
        await _pb.update('achievements', id, {'deletedAt': null});
        _cache.invalidateAchievements();
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
  Future<int> holderCountForAchievement(String achievementId) =>
      guard(() async {
        final data = await _pb.list(
          'player_achievements',
          perPage: 1,
          filter: 'achievement = ${pbQuote(achievementId)}',
        );
        return (data['totalItems'] as num?)?.toInt() ?? 0;
      });
}
