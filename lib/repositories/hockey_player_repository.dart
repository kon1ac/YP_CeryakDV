import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../models/team.dart';

abstract interface class HockeyPlayerRepository {
  Future<PageResult<HockeyPlayer>> find(PlayerQuery query);

  Future<HockeyPlayer?> findById(int id);

  Future<HockeyPlayer> create(HockeyPlayer player);

  Future<HockeyPlayer> update(HockeyPlayer player);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids, {bool physical = false});

  Future<List<Team>> teams();

  Future<List<Arena>> arenas();

  Future<List<Achievement>> achievements();

  Future<bool> jerseyNumberTaken(int number, {int? exceptId});

  Future<bool> contractEmailTaken(String email, {int? exceptId});
}
