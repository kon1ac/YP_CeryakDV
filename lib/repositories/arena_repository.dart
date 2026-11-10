import 'dart:math' as math;

import '../models/arena.dart';
import '../models/arena_query.dart';
import '../models/page_result.dart';
import 'in_memory_catalog.dart';

class RelatedRecordsException implements Exception {
  const RelatedRecordsException(this.message, this.count);

  final String message;

  final int count;

  @override
  String toString() => message;
}

abstract interface class ArenaRepository {
  Future<PageResult<Arena>> find(ArenaQuery query);

  Future<Arena?> findById(int id);

  Future<Arena> create(Arena arena);

  Future<Arena> update(Arena arena);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids, {bool physical = false});

  Future<List<String>> cityNames();

  Future<int> teamCountForArena(int arenaId);

  Future<int> teamsLinkedTo(int arenaId);
}

class InMemoryArenaRepository implements ArenaRepository {
  InMemoryArenaRepository(this._catalog);

  final InMemoryCatalog _catalog;

  List<Arena> get _arenas => _catalog.arenas;

  static const Duration _latency = Duration(milliseconds: 250);

  @override
  Future<PageResult<Arena>> find(ArenaQuery query) async {
    await Future<void>.delayed(_latency);

    if (query.simulateError) {
      throw StateError('учебный API вернул 503 Service Unavailable');
    }

    var rows =
        _arenas.where((a) => query.includeDeleted || !a.isDeleted).toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((a) =>
              a.name.toLowerCase().contains(needle) ||
              a.city.toLowerCase().contains(needle))
          .toList();
    }

    if (query.city != null) {
      rows = rows.where((a) => a.city == query.city).toList();
    }

    final occupancy = {
      for (final a in rows) a.id: _catalog.teamCountForArena(a.id),
    };

    if (query.capacityFrom != null) {
      rows = rows.where((a) => a.capacity >= query.capacityFrom!).toList();
    }
    if (query.capacityTo != null) {
      rows = rows.where((a) => a.capacity <= query.capacityTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'capacity' => a.capacity.compareTo(b.capacity),
        'teams' => occupancy[a.id]!.compareTo(occupancy[b.id]!),
        'id' => a.id.compareTo(b.id),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });

    final total = rows.length;
    final lastPage = total == 0 ? 1 : (total / query.size).ceil();
    final page = query.page > lastPage ? lastPage : query.page;
    final from = (page - 1) * query.size;
    final to = math.min(from + query.size, total);
    final items = from >= total
        ? <Arena>[]
        : rows
            .sublist(from, to)
            .map((a) => a.copyWith(teamCount: occupancy[a.id]))
            .toList();

    return PageResult(items: items, page: page, size: query.size, total: total);
  }

  @override
  Future<Arena?> findById(int id) async {
    await Future<void>.delayed(_latency);
    final index = _arenas.indexWhere((a) => a.id == id);
    if (index == -1) return null;
    return _arenas[index]
        .copyWith(teamCount: _catalog.teamCountForArena(id));
  }

  @override
  Future<Arena> create(Arena arena) async {
    await Future<void>.delayed(_latency);
    final created = Arena(
      id: _catalog.nextArenaId(),
      name: arena.name,
      city: arena.city,
      capacity: arena.capacity,
    );
    _arenas.add(created);
    await _catalog.persist();
    return created;
  }

  @override
  Future<Arena> update(Arena arena) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(arena.id);
    final next = arena.copyWith(deletedAt: _arenas[index].deletedAt);
    _arenas[index] = next;
    await _catalog.persist();
    return next;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _arenas[index] = _arenas[index].copyWith(deletedAt: DateTime.now());
    await _catalog.persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(_latency);
    final linked = await teamsLinkedTo(id);
    if (linked > 0) {
      throw RelatedRecordsException(
        'На арену ссылаются команды: $linked. '
        'Сначала перенесите их на другую арену или удалите.',
        linked,
      );
    }
    _arenas.removeWhere((a) => a.id == id);
    await _catalog.persist();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _arenas[index] = _arenas[index].copyWith(clearDeletedAt: true);
    await _catalog.persist();
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) async {
    await Future<void>.delayed(_latency);
    var count = 0;
    for (final id in ids) {
      final index = _arenas.indexWhere((a) => a.id == id);
      if (index == -1) continue;
      if (physical) {
        if (_catalog.teamCountForArena(id) > 0) continue;
        _arenas.removeAt(index);
      } else {
        if (_arenas[index].isDeleted) continue;
        _arenas[index] = _arenas[index].copyWith(deletedAt: DateTime.now());
      }
      count++;
    }
    if (count > 0) await _catalog.persist();
    return count;
  }

  @override
  Future<List<String>> cityNames() async => _catalog.arenaCities;

  @override
  Future<int> teamCountForArena(int arenaId) async {
    await Future<void>.delayed(_latency);
    return _catalog.teamCountForArena(arenaId);
  }

  @override
  Future<int> teamsLinkedTo(int arenaId) async {
    await Future<void>.delayed(_latency);
    return _catalog.teamsOfArena(arenaId).length;
  }

  int _indexOf(int id) {
    final index = _arenas.indexWhere((a) => a.id == id);
    if (index == -1) throw StateError('Арена $id не найдена');
    return index;
  }
}
