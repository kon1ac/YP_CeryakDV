import 'dart:math' as math;

import '../models/contract.dart';
import '../models/contract_entry.dart';
import '../models/contract_query.dart';
import '../models/page_result.dart';
import 'in_memory_catalog.dart';

abstract interface class ContractRepository {
  Future<PageResult<ContractEntry>> find(ContractQuery query);

  Future<ContractEntry?> findById(int id);

  Future<ContractEntry> update(ContractEntry entry);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids, {bool physical = false});
}

class InMemoryContractRepository implements ContractRepository {
  InMemoryContractRepository(this._catalog);

  final InMemoryCatalog _catalog;

  static const Duration _latency = Duration(milliseconds: 250);

  List<ContractEntry> get _entries {
    final rows = <ContractEntry>[];
    for (final player in _catalog.players) {
      final contract = player.contract;
      if (contract == null) continue;
      rows.add(
        ContractEntry(
          id: contract.id,
          playerId: player.id,
          playerName: player.name,
          number: contract.number,
          email: contract.email,
          salary: contract.salary,
          signedAt: contract.signedAt,
          expiresAt: contract.expiresAt,
          deletedAt: player.deletedAt,
        ),
      );
    }
    return rows;
  }

  @override
  Future<PageResult<ContractEntry>> find(ContractQuery query) async {
    await Future<void>.delayed(_latency);

    if (query.simulateError) {
      throw StateError('учебный API вернул 503 Service Unavailable');
    }

    var rows =
        _entries.where((e) => query.includeDeleted || !e.isDeleted).toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((e) =>
              e.email.toLowerCase().contains(needle) ||
              e.playerName.toLowerCase().contains(needle) ||
              '${e.number}'.contains(needle))
          .toList();
    }

    if (query.expiringSoon) {
      final limit = DateTime.now().add(const Duration(days: 180));
      rows = rows
          .where((e) => e.expiresAt != null && e.expiresAt!.isBefore(limit))
          .toList();
    }

    if (query.minSalary != null) {
      rows = rows.where((e) => e.salary >= query.minSalary!).toList();
    }
    if (query.maxSalary != null) {
      rows = rows.where((e) => e.salary <= query.maxSalary!).toList();
    }

    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'player' => a.playerName.toLowerCase().compareTo(
              b.playerName.toLowerCase(),
            ),
        'number' => a.number.compareTo(b.number),
        'salary' => a.salary.compareTo(b.salary),
        'signedAt' => a.signedAt.compareTo(b.signedAt),
        'expiresAt' => (a.expiresAt ?? DateTime(9999))
            .compareTo(b.expiresAt ?? DateTime(9999)),
        'id' => a.id.compareTo(b.id),
        _ => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
      };
      return query.sortAscending ? result : -result;
    });

    final total = rows.length;
    final lastPage = total == 0 ? 1 : (total / query.size).ceil();
    final page = query.page > lastPage ? lastPage : query.page;
    final from = (page - 1) * query.size;
    final to = math.min(from + query.size, total);
    final items =
        from >= total ? <ContractEntry>[] : rows.sublist(from, to);

    return PageResult(items: items, page: page, size: query.size, total: total);
  }

  @override
  Future<ContractEntry?> findById(int id) async {
    await Future<void>.delayed(_latency);
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<ContractEntry> update(ContractEntry entry) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(entry.playerId);
    final player = _catalog.players[index];
    final contract = player.contract;
    if (contract == null) throw StateError('У игрока нет контракта');

    _catalog.players[index] = player.copyWith(
      contract: Contract(
        id: contract.id,
        number: entry.number,
        email: entry.email,
        salary: entry.salary,
        signedAt: entry.signedAt,
        expiresAt: entry.expiresAt,
      ),
    );
    await _catalog.persist();
    return entry;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(_latency);
    final entry = await findById(id);
    if (entry == null) return;
    final index = _indexOf(entry.playerId);
    _catalog.players[index] =
        _catalog.players[index].copyWith(deletedAt: DateTime.now());
    await _catalog.persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(_latency);
    final entry = await findById(id);
    if (entry == null) return;
    final index = _indexOf(entry.playerId);
    _catalog.players[index] =
        _catalog.players[index].copyWith(clearContract: true);
    await _catalog.persist();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(_latency);
    final entry = await findById(id);
    if (entry == null) return;
    final index = _indexOf(entry.playerId);
    _catalog.players[index] =
        _catalog.players[index].copyWith(clearDeletedAt: true);
    await _catalog.persist();
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) async {
    await Future<void>.delayed(_latency);
    var count = 0;
    for (final id in ids) {
      final entry = await findById(id);
      if (entry == null) continue;
      final index = _indexOf(entry.playerId);
      final player = _catalog.players[index];
      if (physical) {
        if (player.contract == null) continue;
        _catalog.players[index] = player.copyWith(clearContract: true);
      } else {
        if (player.isDeleted) continue;
        _catalog.players[index] = player.copyWith(deletedAt: DateTime.now());
      }
      count++;
    }
    if (count > 0) await _catalog.persist();
    return count;
  }

  int _indexOf(int playerId) {
    final index = _catalog.players.indexWhere((p) => p.id == playerId);
    if (index == -1) throw StateError('Игрок $playerId не найден');
    return index;
  }
}
