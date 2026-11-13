import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/dictionary_cache.dart';
import '../core/page_parser.dart';
import '../models/achievement.dart';
import '../models/achievement_query.dart';
import '../models/page_result.dart';
import 'achievement_repository.dart';

class ApiAchievementRepository implements AchievementRepository {
  ApiAchievementRepository(this._dio, this._cache);

  final Dio _dio;
  final DictionaryCache _cache;
  final CancelScope _findCancel = CancelScope();

  @override
  Future<PageResult<Achievement>> find(AchievementQuery query) =>
      guard(() async {
        final token = _findCancel.next();
        final response = await _dio.get<dynamic>(
          '/achievements',
          queryParameters: {
            if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
            if (query.yearFrom != null) 'yearFrom': query.yearFrom,
            if (query.yearTo != null) 'yearTo': query.yearTo,
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
          Achievement.fromJson,
          fallbackSize: query.size,
        );
      });

  @override
  Future<Achievement?> findById(int id) => guard(() async {
        try {
          final response = await _dio.get<dynamic>('/achievements/$id');
          return Achievement.fromJson(asJsonMap(response.data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Achievement> create(Achievement achievement) => guard(() async {
        final response = await _dio.post<dynamic>(
          '/achievements',
          data: achievement.toApiBody(),
        );
        _cache.invalidateAchievements();
        return Achievement.fromJson(asJsonMap(response.data));
      });

  @override
  Future<Achievement> update(Achievement achievement) => guard(() async {
        final response = await _dio.put<dynamic>(
          '/achievements/${achievement.id}',
          data: achievement.toApiBody(),
        );
        _cache.invalidateAchievements();
        return Achievement.fromJson(asJsonMap(response.data));
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete<dynamic>('/achievements/$id');
        _cache.invalidateAchievements();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete<dynamic>(
          '/achievements/$id',
          queryParameters: {'hard': true},
        );
        _cache.invalidateAchievements();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post<dynamic>('/achievements/$id/restore');
        _cache.invalidateAchievements();
      });

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) =>
      guard(() async {
        final response = await _dio.post<dynamic>(
          '/achievements/bulk-delete',
          data: {'ids': ids, 'physical': physical},
        );
        _cache.invalidateAchievements();
        return asJsonMap(response.data)['deleted'] as int? ?? 0;
      });

  @override
  Future<int> holderCountForAchievement(int achievementId) => guard(() async {
        final item = await findById(achievementId);
        return item?.holderCount ?? 0;
      });
}
