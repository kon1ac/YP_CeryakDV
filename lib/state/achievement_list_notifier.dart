import '../models/achievement.dart';
import '../models/achievement_query.dart';
import '../models/page_result.dart';
import '../repositories/achievement_repository.dart';
import 'entity_list_notifier.dart';

class AchievementListNotifier
    extends EntityListNotifier<Achievement, AchievementQuery> {
  AchievementListNotifier(this._repository, {AchievementQuery? initialQuery})
      : super(initialQuery ?? AchievementQuery.empty);

  final AchievementRepository _repository;

  List<Achievement> get achievementsSnapshot => _snapshot;

  final List<Achievement> _snapshot = [];

  @override
  Future<void> init() async {
    _snapshot
      ..clear()
      ..addAll((await _repository.find(
        const AchievementQuery(size: 50, includeDeleted: true),
      ))
          .items);
    notifyListeners();
    await load();
  }

  @override
  Future<PageResult<Achievement>> fetch(AchievementQuery query) =>
      _repository.find(query);

  @override
  Future<void> mutateOne(int id, MutationMode mode) => switch (mode) {
        MutationMode.softDelete => _repository.softDelete(id),
        MutationMode.hardDelete => _repository.hardDelete(id),
        MutationMode.restore => _repository.restore(id),
      };

  @override
  Future<int> mutateMany(List<int> ids, MutationMode mode) =>
      _repository.deleteMany(ids,
          physical: mode == MutationMode.hardDelete);

  @override
  AchievementQuery withoutFilters(AchievementQuery query) => query.copyWith(
        search: '',
        yearFrom: null,
        yearTo: null,
        includeDeleted: false,
      );
}
