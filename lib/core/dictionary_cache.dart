import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/team.dart';

/// Кэш справочников: команды, арены, награды запрашиваются один раз.
class DictionaryCache {
  List<Team>? _teams;
  List<Arena>? _arenas;
  List<Achievement>? _achievements;

  Future<List<Team>> teams(Future<List<Team>> Function() loader) async {
    return _teams ??= List.unmodifiable(await loader());
  }

  Future<List<Arena>> arenas(Future<List<Arena>> Function() loader) async {
    return _arenas ??= List.unmodifiable(await loader());
  }

  Future<List<Achievement>> achievements(
    Future<List<Achievement>> Function() loader,
  ) async {
    return _achievements ??= List.unmodifiable(await loader());
  }

  void invalidateTeams() => _teams = null;

  void invalidateArenas() => _arenas = null;

  void invalidateAchievements() => _achievements = null;

  void invalidateAll() {
    invalidateTeams();
    invalidateArenas();
    invalidateAchievements();
  }
}
