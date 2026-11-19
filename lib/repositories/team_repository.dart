import '../models/arena.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import '../models/team_query.dart';

abstract interface class TeamRepository {
  Future<PageResult<Team>> find(TeamQuery query);

  Future<Team?> findById(String id);

  Future<Team> create(Team team);

  Future<Team> update(Team team);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids, {bool physical = false});

  Future<List<String>> cityNames();

  Future<List<Arena>> arenas();

  Future<int> playerCountForTeam(String teamId);
}
