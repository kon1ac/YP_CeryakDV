import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../models/team.dart';
import '../repositories/hockey_player_repository.dart';
import 'entity_list_notifier.dart';

class PlayerListNotifier
    extends EntityListNotifier<HockeyPlayer, PlayerQuery> {
  PlayerListNotifier(this._repository, {PlayerQuery? initialQuery})
      : super(initialQuery ?? PlayerQuery.empty);

  final HockeyPlayerRepository _repository;

  List<Team> _teams = const [];
  List<Achievement> _achievements = const [];

  List<Arena> _arenas = const [];

  final Map<int, int> _jerseys = {};

  final Map<int, String> _emails = {};

  List<Team> get teams => _teams;

  List<Achievement> get achievements => _achievements;

  List<Arena> get arenas => _arenas;

  Set<int> achievementsOfTeam(int teamId) =>
      _achievementByTeam[teamId] ?? const <int>{};

  final Map<int, Set<int>> _achievementByTeam = {};

  @override
  Future<void> init() async {
    _teams = await _repository.teams();
    _arenas = await _repository.arenas();
    _achievements = await _repository.achievements();
    _achievementByTeam.clear();
    await _refreshIndexes();
    notifyListeners();
    await load();
  }

  Future<void> refreshIndexes() => _refreshIndexes();

  Future<void> _refreshIndexes() async {
    _jerseys.clear();
    _emails.clear();
    final page = await _repository.find(
      const PlayerQuery(size: 50, includeDeleted: true),
    );
    _achievementByTeam.clear();
    for (final player in page.items) {
      if (player.jerseyNumber != null) {
        _jerseys[player.id] = player.jerseyNumber!;
      }
      final email = player.contract?.email ?? '';
      if (email.isNotEmpty) _emails[player.id] = email.toLowerCase();
      if (player.achievementIds.isNotEmpty) {
        (_achievementByTeam[player.teamId] ??= <int>{})
            .addAll(player.achievementIds);
      }
    }
  }

  bool jerseyTakenLocally(int number, {int? exceptId}) => _jerseys.entries.any(
        (entry) => entry.key != exceptId && entry.value == number,
      );

  bool emailTakenLocally(String email, {int? exceptId}) {
    final needle = email.trim().toLowerCase();
    return _emails.entries.any(
      (entry) => entry.key != exceptId && entry.value == needle,
    );
  }

  @override
  Future<PageResult<HockeyPlayer>> fetch(PlayerQuery query) =>
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
  PlayerQuery withoutFilters(PlayerQuery query) => query.copyWith(
        search: '',
        category: null,
        teamId: null,
        achievementId: null,
        priceFrom: null,
        priceTo: null,
        includeDeleted: false,
      );
}
