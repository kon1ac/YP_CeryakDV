import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/contract.dart';
import '../models/hockey_player.dart';
import '../models/list_query.dart';
import '../models/team.dart';
import 'seed_data.dart';

class InMemoryCatalog {
  InMemoryCatalog()
      : players = [...SeedData.players],
        teams = [...SeedData.teams],
        arenas = [...SeedData.arenas],
        achievements = [...SeedData.achievements],
        nextPlayerIdValue = SeedData.players.length + 1,
        nextTeamIdValue = SeedData.teams.length + 1,
        nextArenaIdValue = SeedData.arenas.length + 1,
        nextAchievementIdValue = SeedData.achievements.length + 1;

  InMemoryCatalog.restored({
    required this.players,
    required this.teams,
    required this.arenas,
    required this.achievements,
    required int nextPlayerId,
    required int nextTeamId,
    required int nextArenaId,
    required int nextAchievementId,
  })  : nextPlayerIdValue = nextPlayerId,
        nextTeamIdValue = nextTeamId,
        nextArenaIdValue = nextArenaId,
        nextAchievementIdValue = nextAchievementId;

  final List<HockeyPlayer> players;
  final List<Team> teams;
  final List<Arena> arenas;
  final List<Achievement> achievements;

  int nextPlayerIdValue;
  int nextTeamIdValue;
  int nextArenaIdValue;
  int nextAchievementIdValue;

  Future<void> Function(InMemoryCatalog catalog)? onChanged;

  int nextPlayerId() => nextPlayerIdValue++;

  int nextTeamId() => nextTeamIdValue++;

  int nextArenaId() => nextArenaIdValue++;

  int nextAchievementId() => nextAchievementIdValue++;

  int nextContractId() {
    var max = 0;
    for (final player in players) {
      final id = player.contract?.id ?? 0;
      if (id > max) max = id;
    }
    return max + 1;
  }

  Future<void> persist() async {
    final handler = onChanged;
    if (handler == null) return;
    await handler(this);
  }

  int activePlayerCount(int teamId) =>
      players.where((p) => p.teamId == teamId && !p.isDeleted).length;

  int teamCountForArena(int arenaId) =>
      teams.where((t) => t.arenaId == arenaId && !t.isDeleted).length;

  int holderCountForAchievement(int achievementId) => players
      .where((p) => !p.isDeleted && p.achievementIds.contains(achievementId))
      .length;

  List<HockeyPlayer> playersOfTeam(int teamId) =>
      players.where((p) => p.teamId == teamId).toList();

  List<Team> teamsOfArena(int arenaId) =>
      teams.where((t) => t.arenaId == arenaId).toList();

  String teamNameById(int id) => _nameOf(teams, id);

  String arenaNameById(int id) => _nameOf(arenas, id);

  List<String> achievementNamesByIds(List<int> ids) {
    final byId = {for (final a in achievements) a.id: a.name};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Contract? contractById(int? id) {
    if (id == null) return null;
    for (final player in players) {
      if (player.contract?.id == id) return player.contract;
    }
    return null;
  }

  bool jerseyNumberTaken(int number, {int? exceptPlayerId}) => players.any(
        (p) => p.id != exceptPlayerId && p.jerseyNumber == number,
      );

  bool contractEmailTaken(String email, {int? exceptPlayerId}) {
    final needle = email.trim().toLowerCase();
    return players.any((p) =>
        p.id != exceptPlayerId &&
        p.contract != null &&
        p.contract!.email.trim().toLowerCase() == needle);
  }

  static String _nameOf(List<Identifiable> rows, int id) {
    for (final row in rows) {
      if (row.id == id) return row.label;
    }
    return '';
  }

  List<String> get teamNames => _sorted(teams.map((t) => t.name));

  List<String> get cities => _sorted(teams.map((t) => t.city));

  List<String> get arenaNames => _sorted(arenas.map((a) => a.name));

  List<String> get arenaCities => _sorted(arenas.map((a) => a.city));

  List<String> get achievementNames => _sorted(achievements.map((a) => a.name));

  static List<String> _sorted(Iterable<String> values) =>
      values.toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
