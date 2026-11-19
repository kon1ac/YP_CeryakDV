import '../models/achievement.dart';
import '../models/achievement_query.dart';
import '../models/page_result.dart';

abstract interface class AchievementRepository {
  Future<PageResult<Achievement>> find(AchievementQuery query);

  Future<Achievement?> findById(String id);

  Future<Achievement> create(Achievement achievement);

  Future<Achievement> update(Achievement achievement);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids, {bool physical = false});

  Future<int> holderCountForAchievement(String achievementId);
}
