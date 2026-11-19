import '../models/arena.dart';
import '../models/arena_query.dart';
import '../models/page_result.dart';

class RelatedRecordsException implements Exception {
  const RelatedRecordsException(this.message, this.count);

  final String message;

  final int count;

  @override
  String toString() => message;
}

abstract interface class ArenaRepository {
  Future<PageResult<Arena>> find(ArenaQuery query);

  Future<Arena?> findById(String id);

  Future<Arena> create(Arena arena);

  Future<Arena> update(Arena arena);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids, {bool physical = false});

  Future<List<String>> cityNames();

  Future<int> teamCountForArena(String arenaId);

  Future<int> teamsLinkedTo(String arenaId);
}
