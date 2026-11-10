import '../models/arena.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import '../models/team_query.dart';
import '../repositories/team_repository.dart';
import 'entity_list_notifier.dart';

class TeamListNotifier extends EntityListNotifier<Team, TeamQuery> {
  TeamListNotifier(this._repository, {TeamQuery? initialQuery})
      : super(initialQuery ?? TeamQuery.empty);

  final TeamRepository _repository;

  List<String> _cityOptions = const [];
  List<Arena> _arenas = const [];

  List<String> get cityOptions => _cityOptions;

  List<Arena> get arenas => _arenas;

  List<Team> get teamsSnapshot => _snapshot;

  final List<Team> _snapshot = [];

  @override
  Future<void> init() async {
    _cityOptions = await _repository.cityNames();
    _arenas = await _repository.arenas();
    _snapshot
      ..clear()
      ..addAll((await _repository.find(
        const TeamQuery(size: 50, includeDeleted: true),
      ))
          .items);
    notifyListeners();
    await load();
  }

  @override
  Future<PageResult<Team>> fetch(TeamQuery query) => _repository.find(query);

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
  TeamQuery withoutFilters(TeamQuery query) => query.copyWith(
        search: '',
        city: null,
        arenaId: null,
        playersFrom: null,
        playersTo: null,
        includeDeleted: false,
      );
}
