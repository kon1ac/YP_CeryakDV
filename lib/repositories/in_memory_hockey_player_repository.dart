import 'dart:math' as math;

import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
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
              p.description.toLowerCase().contains(needle))
          .toList();
    }

    if (query.category != null) {
      rows = rows.where((p) => p.category == query.category).toList();
    }
    if (query.team != null) {
      rows = rows.where((p) => p.team == query.team).toList();
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
        'team' => a.team.toLowerCase().compareTo(b.team.toLowerCase()),
        'category' => a.category.toLowerCase().compareTo(b.category.toLowerCase()),
        'id' => a.id.compareTo(b.id),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });

    return _paginate(rows, query.page, query.size);
  }

  static PageResult<HockeyPlayer> _paginate(
    List<HockeyPlayer> rows,
    int requestedPage,
    int size,
  ) {
    final total = rows.length;
    final lastPage = total == 0 ? 1 : (total / size).ceil();
    final page = requestedPage > lastPage ? lastPage : requestedPage;
    final from = (page - 1) * size;
    final to = math.min(from + size, total);
    final items = from >= total ? <HockeyPlayer>[] : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: page,
      size: size,
      total: total,
    );
  }

  @override
  Future<HockeyPlayer?> findById(int id) async {
    await Future<void>.delayed(_latency);
    final index = _players.indexWhere((p) => p.id == id);
    return index == -1 ? null : _players[index];
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
      team: player.team,
      jerseyNumber: player.jerseyNumber,
    );
    _players.add(created);
    return created;
  }

  @override
  Future<HockeyPlayer> update(HockeyPlayer player) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(player.id);
    _players[index] = player;
    return player;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _players[index] = _players[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(_latency);
    _players.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _players[index] = _players[index].copyWith(clearDeletedAt: true);
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
    return count;
  }

  @override
  Future<List<String>> teamNames() async => _catalog.teamNames;

  int _indexOf(int id) {
    final index = _players.indexWhere((p) => p.id == id);
    if (index == -1) throw StateError('Игрок $id не найден');
    return index;
  }
}
