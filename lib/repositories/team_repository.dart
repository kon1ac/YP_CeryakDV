import 'dart:math' as math;

import '../models/arena.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import '../models/team_query.dart';
import 'in_memory_catalog.dart';

abstract interface class TeamRepository {
  Future<PageResult<Team>> find(TeamQuery query);

  Future<Team?> findById(int id);

  Future<Team> create(Team team);

  Future<Team> update(Team team);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids, {bool physical = false});

  Future<List<String>> cityNames();

  Future<List<Arena>> arenas();

  Future<int> playerCountForTeam(int teamId);
}

class InMemoryTeamRepository implements TeamRepository {
  InMemoryTeamRepository(this._catalog);

  final InMemoryCatalog _catalog;

  List<Team> get _teams => _catalog.teams;

  static const Duration _latency = Duration(milliseconds: 250);

  @override
  Future<PageResult<Team>> find(TeamQuery query) async {
    await Future<void>.delayed(_latency);

    if (query.simulateError) {
      throw StateError('учебный API вернул 503 Service Unavailable');
    }

    var rows = _teams.where((t) => query.includeDeleted || !t.isDeleted).toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((t) =>
              t.name.toLowerCase().contains(needle) ||
              t.city.toLowerCase().contains(needle))
          .toList();
    }

    if (query.city != null) {
      rows = rows.where((t) => t.city == query.city).toList();
    }
    if (query.arenaId != null) {
      rows = rows.where((t) => t.arenaId == query.arenaId).toList();
    }
    final rosters = {
      for (final t in rows) t.id: _catalog.activePlayerCount(t.id),
    };

    if (query.playersFrom != null) {
      rows = rows.where((t) => rosters[t.id]! >= query.playersFrom!).toList();
    }
    if (query.playersTo != null) {
      rows = rows.where((t) => rosters[t.id]! <= query.playersTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        'players' => rosters[a.id]!.compareTo(rosters[b.id]!),
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
        ? <Team>[]
        : rows
            .sublist(from, to)
            .map((t) => _decorate(t, rosters[t.id]!))
            .toList();

    return PageResult(items: items, page: page, size: query.size, total: total);
  }

  Team _decorate(Team team, int roster) => team.copyWith(
        rosterSize: roster,
        arenaName: _catalog.arenaNameById(team.arenaId),
      );

  @override
  Future<Team?> findById(int id) async {
    await Future<void>.delayed(_latency);
    final index = _teams.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    return _decorate(_teams[index], _catalog.activePlayerCount(id));
  }

  @override
  Future<Team> create(Team team) async {
    await Future<void>.delayed(_latency);
    final created = Team(
      id: _catalog.nextTeamId(),
      name: team.name,
      city: team.city,
      foundedYear: team.foundedYear,
      arenaId: team.arenaId,
    );
    _teams.add(created);
    await _catalog.persist();
    return _decorate(created, 0);
  }

  @override
  Future<Team> update(Team team) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(team.id);
    final next = team.copyWith(deletedAt: _teams[index].deletedAt);
    _teams[index] = next;
    await _catalog.persist();
    return _decorate(next, _catalog.activePlayerCount(next.id));
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _teams[index] = _teams[index].copyWith(deletedAt: DateTime.now());
    await _catalog.persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(_latency);
    _teams.removeWhere((t) => t.id == id);
    await _catalog.persist();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _teams[index] = _teams[index].copyWith(clearDeletedAt: true);
    await _catalog.persist();
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) async {
    await Future<void>.delayed(_latency);
    var count = 0;
    for (final id in ids) {
      final index = _teams.indexWhere((t) => t.id == id);
      if (index == -1) continue;
      if (physical) {
        _teams.removeAt(index);
      } else {
        if (_teams[index].isDeleted) continue;
        _teams[index] = _teams[index].copyWith(deletedAt: DateTime.now());
      }
      count++;
    }
    if (count > 0) await _catalog.persist();
    return count;
  }

  @override
  Future<List<String>> cityNames() async => _catalog.cities;

  @override
  Future<List<Arena>> arenas() async {
    await Future<void>.delayed(_latency);
    return _catalog.arenas.where((a) => !a.isDeleted).toList();
  }

  @override
  Future<int> playerCountForTeam(int teamId) async {
    await Future<void>.delayed(_latency);
    return _catalog.activePlayerCount(teamId);
  }

  int _indexOf(int id) {
    final index = _teams.indexWhere((t) => t.id == id);
    if (index == -1) throw StateError('Команда $id не найдена');
    return index;
  }
}
