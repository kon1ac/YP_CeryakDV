import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../models/team.dart';

abstract interface class HockeyPlayerRepository {
  Future<PageResult<HockeyPlayer>> find(PlayerQuery query);

  Future<HockeyPlayer?> findById(String id);

  Future<HockeyPlayer> create(HockeyPlayer player);

  Future<HockeyPlayer> update(HockeyPlayer player);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids, {bool physical = false});

  Future<List<Team>> teams();

  Future<List<Arena>> arenas();

  Future<List<Achievement>> achievements();

  Future<bool> jerseyNumberTaken(int number, {String? exceptId});

  Future<bool> contractEmailTaken(String email, {String? exceptId});
}
