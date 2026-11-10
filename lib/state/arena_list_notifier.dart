import '../models/arena.dart';
import '../models/arena_query.dart';
import '../models/page_result.dart';
import '../repositories/arena_repository.dart';
import 'entity_list_notifier.dart';

class ArenaListNotifier extends EntityListNotifier<Arena, ArenaQuery> {
  ArenaListNotifier(this._repository, {ArenaQuery? initialQuery})
      : super(initialQuery ?? ArenaQuery.empty);

  final ArenaRepository _repository;

  List<String> _cityOptions = const [];

  List<String> get cityOptions => _cityOptions;

  List<Arena> get arenasSnapshot => _snapshot;

  final List<Arena> _snapshot = [];

  @override
  Future<void> init() async {
    _cityOptions = await _repository.cityNames();
    _snapshot
      ..clear()
      ..addAll((await _repository.find(
        const ArenaQuery(size: 50, includeDeleted: true),
      ))
          .items);
    notifyListeners();
    await load();
  }

  @override
  Future<PageResult<Arena>> fetch(ArenaQuery query) => _repository.find(query);

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
  ArenaQuery withoutFilters(ArenaQuery query) => query.copyWith(
        search: '',
        city: null,
        capacityFrom: null,
        capacityTo: null,
        includeDeleted: false,
      );
}
