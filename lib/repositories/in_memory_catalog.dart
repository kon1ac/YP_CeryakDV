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

  String nextPlayerId() => '${nextPlayerIdValue++}';

  String nextTeamId() => '${nextTeamIdValue++}';

  String nextArenaId() => '${nextArenaIdValue++}';

  String nextAchievementId() => '${nextAchievementIdValue++}';

  String nextContractId() {
    var max = 0;
    for (final player in players) {
      final id = player.contract?.id;
      if (id == null || id.isEmpty) continue;
      final n = int.tryParse(id) ?? 0;
      if (n > max) max = n;
    }
    return '${max + 1}';
  }

  Future<void> persist() async {
    final handler = onChanged;
    if (handler == null) return;
    await handler(this);
  }

  int activePlayerCount(String teamId) =>
      players.where((p) => p.teamId == teamId && !p.isDeleted).length;

  int teamCountForArena(String arenaId) =>
      teams.where((t) => t.arenaId == arenaId && !t.isDeleted).length;

  int holderCountForAchievement(String achievementId) => players
      .where((p) => !p.isDeleted && p.achievementIds.contains(achievementId))
      .length;

  List<HockeyPlayer> playersOfTeam(String teamId) =>
      players.where((p) => p.teamId == teamId).toList();

  List<Team> teamsOfArena(String arenaId) =>
      teams.where((t) => t.arenaId == arenaId).toList();

  String teamNameById(String id) => _nameOf(teams, id);

  String arenaNameById(String id) => _nameOf(arenas, id);

  List<String> achievementNamesByIds(List<String> ids) {
    final byId = {for (final a in achievements) a.id: a.name};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Contract? contractById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final player in players) {
      if (player.contract?.id == id) return player.contract;
    }
    return null;
  }

  bool jerseyNumberTaken(int number, {String? exceptPlayerId}) => players.any(
        (p) => p.id != exceptPlayerId && p.jerseyNumber == number,
      );

  bool contractEmailTaken(String email, {String? exceptPlayerId}) {
    final needle = email.trim().toLowerCase();
    return players.any((p) =>
        p.id != exceptPlayerId &&
        p.contract != null &&
        p.contract!.email.trim().toLowerCase() == needle);
  }

  static String _nameOf(List<Identifiable> rows, String id) {
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