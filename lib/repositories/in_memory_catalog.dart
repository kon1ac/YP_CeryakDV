import '../models/hockey_player.dart';
import '../models/team.dart';
import 'seed_data.dart';

class InMemoryCatalog {
  InMemoryCatalog()
      : players = [...SeedData.players],
        teams = [...SeedData.teams],
        _nextPlayerId = SeedData.players.length + 1,
        _nextTeamId = SeedData.teams.length + 1;

  final List<HockeyPlayer> players;
  final List<Team> teams;

  int _nextPlayerId;
  int _nextTeamId;

  int nextPlayerId() => _nextPlayerId++;

  int nextTeamId() => _nextTeamId++;

  int activePlayerCount(String teamName) => players
      .where((p) => p.team == teamName && !p.isDeleted)
      .length;

  List<String> get teamNames {
    final names = teams.map((t) => t.name).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  List<String> get cities {
    final values = teams.map((t) => t.city).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }
}
