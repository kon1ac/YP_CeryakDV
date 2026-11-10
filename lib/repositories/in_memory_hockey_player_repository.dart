import 'dart:math' as math;

import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/contract.dart';
import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../models/team.dart';
import 'hockey_player_repository.dart';
import 'in_memory_catalog.dart';

class InMemoryHockeyPlayerRepository implements HockeyPlayerRepository {
  InMemoryHockeyPlayerRepository(this._catalog);

  final InMemoryCatalog _catalog;

  List<HockeyPlayer> get _players => _catalog.players;

  static const Duration _latency = Duration(milliseconds: 250);

  @override
  Future<PageResult<HockeyPlayer>> find(PlayerQuery query) async {
    await Future<void>.delayed(_latency);

    if (query.simulateError) {
      throw StateError('учебный API вернул 503 Service Unavailable');
    }

    var rows =
        _players.where((p) => query.includeDeleted || !p.isDeleted).toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(needle) ||
              '${p.jerseyNumber ?? ''}'.contains(needle) ||
              p.description.toLowerCase().contains(needle) ||
              (p.contract?.email.toLowerCase().contains(needle) ?? false))
          .toList();
    }

    if (query.category != null) {
      rows = rows.where((p) => p.category == query.category).toList();
    }
    if (query.teamId != null) {
      rows = rows.where((p) => p.teamId == query.teamId).toList();
    }
    if (query.achievementId != null) {
      rows = rows
          .where((p) => p.achievementIds.contains(query.achievementId))
          .toList();
    }
    if (query.priceFrom != null) {
      rows = rows.where((p) => p.price >= query.priceFrom!).toList();
    }
    if (query.priceTo != null) {
      rows = rows.where((p) => p.price <= query.priceTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'price' => a.price.compareTo(b.price),
        'jerseyNumber' => (a.jerseyNumber ?? 0).compareTo(b.jerseyNumber ?? 0),
        'team' => _catalog
            .teamNameById(a.teamId)
            .toLowerCase()
            .compareTo(_catalog.teamNameById(b.teamId).toLowerCase()),
        'category' => a.category.compareTo(b.category),
        'achievements' =>
          a.achievementIds.length.compareTo(b.achievementIds.length),
        'contract' => (a.contract?.salary ?? 0).compareTo(b.contract?.salary ?? 0),
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
        ? <HockeyPlayer>[]
        : rows.sublist(from, to).map(_decorate).toList();

    return PageResult(items: items, page: page, size: query.size, total: total);
  }

  HockeyPlayer _decorate(HockeyPlayer player) {
    return player.copyWith(
      teamName: _catalog.teamNameById(player.teamId),
      achievementNames: _catalog.achievementNamesByIds(player.achievementIds),
    );
  }

  @override
  Future<HockeyPlayer?> findById(int id) async {
    await Future<void>.delayed(_latency);
    final index = _players.indexWhere((p) => p.id == id);
    return index == -1 ? null : _decorate(_players[index]);
  }

  @override
  Future<HockeyPlayer> create(HockeyPlayer player) async {
    await Future<void>.delayed(_latency);
    final created = HockeyPlayer(
      id: _catalog.nextPlayerId(),
      name: player.name,
      description: player.description,
      price: player.price,
      category: player.category,
      teamId: player.teamId,
      achievementIds: player.achievementIds,
      contract: _withFreshId(player.contract),
      jerseyNumber: player.jerseyNumber,
    );
    _players.add(created);
    await _catalog.persist();
    return _decorate(created);
  }

  @override
  Future<HockeyPlayer> update(HockeyPlayer player) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(player.id);
    final previous = _players[index];
    final next = player.copyWith(
      contract: player.contract == null ? null : _withFreshId(player.contract),
      clearContract: player.contract == null,
      deletedAt: previous.deletedAt,
    );
    _players[index] = next;
    await _catalog.persist();
    return _decorate(next);
  }

  Contract? _withFreshId(Contract? contract) {
    if (contract == null) return null;
    if (contract.id > 0) return contract;
    return Contract(
      id: _catalog.nextContractId(),
      number: contract.number,
      email: contract.email,
      salary: contract.salary,
      signedAt: contract.signedAt,
      expiresAt: contract.expiresAt,
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _players[index] = _players[index].copyWith(deletedAt: DateTime.now());
    await _catalog.persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(_latency);
    _players.removeWhere((p) => p.id == id);
    await _catalog.persist();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _players[index] = _players[index].copyWith(clearDeletedAt: true);
    await _catalog.persist();
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) async {
    await Future<void>.delayed(_latency);
    var count = 0;
    for (final id in ids) {
      final index = _players.indexWhere((p) => p.id == id);
      if (index == -1) continue;
      if (physical) {
        _players.removeAt(index);
      } else {
        if (_players[index].isDeleted) continue;
        _players[index] = _players[index].copyWith(deletedAt: DateTime.now());
      }
      count++;
    }
    if (count > 0) await _catalog.persist();
    return count;
  }

  @override
  Future<List<Team>> teams() async {
    await Future<void>.delayed(_latency);
    return _catalog.teams.where((t) => !t.isDeleted).toList();
  }

  @override
  Future<List<Arena>> arenas() async {
    await Future<void>.delayed(_latency);
    return _catalog.arenas.where((a) => !a.isDeleted).toList();
  }

  @override
  Future<List<Achievement>> achievements() async {
    await Future<void>.delayed(_latency);
    return _catalog.achievements.where((a) => !a.isDeleted).toList();
  }

  @override
  Future<bool> jerseyNumberTaken(int number, {int? exceptId}) async =>
      _catalog.jerseyNumberTaken(number, exceptPlayerId: exceptId);

  @override
  Future<bool> contractEmailTaken(String email, {int? exceptId}) async =>
      _catalog.contractEmailTaken(email, exceptPlayerId: exceptId);

  int _indexOf(int id) {
    final index = _players.indexWhere((p) => p.id == id);
    if (index == -1) throw StateError('Игрок $id не найден');
    return index;
  }
}
