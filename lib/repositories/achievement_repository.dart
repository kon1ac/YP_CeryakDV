import 'dart:math' as math;

import '../models/achievement.dart';
import '../models/achievement_query.dart';
import '../models/page_result.dart';
import 'in_memory_catalog.dart';

abstract interface class AchievementRepository {
  Future<PageResult<Achievement>> find(AchievementQuery query);

  Future<Achievement?> findById(int id);

  Future<Achievement> create(Achievement achievement);

  Future<Achievement> update(Achievement achievement);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids, {bool physical = false});

  Future<int> holderCountForAchievement(int achievementId);
}

class InMemoryAchievementRepository implements AchievementRepository {
  InMemoryAchievementRepository(this._catalog);

  final InMemoryCatalog _catalog;

  List<Achievement> get _achievements => _catalog.achievements;

  static const Duration _latency = Duration(milliseconds: 250);

  @override
  Future<PageResult<Achievement>> find(AchievementQuery query) async {
    await Future<void>.delayed(_latency);

    if (query.simulateError) {
      throw StateError('учебный API вернул 503 Service Unavailable');
    }

    var rows = _achievements
        .where((a) => query.includeDeleted || !a.isDeleted)
        .toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((a) =>
              a.name.toLowerCase().contains(needle) ||
              a.description.toLowerCase().contains(needle))
          .toList();
    }

    final holders = {
      for (final a in rows) a.id: _catalog.holderCountForAchievement(a.id),
    };

    if (query.yearFrom != null) {
      rows = rows.where((a) => a.year >= query.yearFrom!).toList();
    }
    if (query.yearTo != null) {
      rows = rows.where((a) => a.year <= query.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'year' => a.year.compareTo(b.year),
        'holders' => holders[a.id]!.compareTo(holders[b.id]!),
        'description' =>
          a.description.toLowerCase().compareTo(b.description.toLowerCase()),
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
        ? <Achievement>[]
        : rows
            .sublist(from, to)
            .map((a) => a.copyWith(holderCount: holders[a.id]))
            .toList();

    return PageResult(items: items, page: page, size: query.size, total: total);
  }

  @override
  Future<Achievement?> findById(int id) async {
    await Future<void>.delayed(_latency);
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) return null;
    return _achievements[index]
        .copyWith(holderCount: _catalog.holderCountForAchievement(id));
  }

  @override
  Future<Achievement> create(Achievement achievement) async {
    await Future<void>.delayed(_latency);
    final created = Achievement(
      id: _catalog.nextAchievementId(),
      name: achievement.name,
      description: achievement.description,
      year: achievement.year,
    );
    _achievements.add(created);
    await _catalog.persist();
    return created;
  }

  @override
  Future<Achievement> update(Achievement achievement) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(achievement.id);
    final next = achievement.copyWith(
      deletedAt: _achievements[index].deletedAt,
    );
    _achievements[index] = next;
    await _catalog.persist();
    return next;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _achievements[index] =
        _achievements[index].copyWith(deletedAt: DateTime.now());
    await _catalog.persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(_latency);
    _achievements.removeWhere((a) => a.id == id);
    await _catalog.persist();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(_latency);
    final index = _indexOf(id);
    _achievements[index] = _achievements[index].copyWith(clearDeletedAt: true);
    await _catalog.persist();
  }

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) async {
    await Future<void>.delayed(_latency);
    var count = 0;
    for (final id in ids) {
      final index = _achievements.indexWhere((a) => a.id == id);
      if (index == -1) continue;
      if (physical) {
        _achievements.removeAt(index);
      } else {
        if (_achievements[index].isDeleted) continue;
        _achievements[index] =
            _achievements[index].copyWith(deletedAt: DateTime.now());
      }
      count++;
    }
    if (count > 0) await _catalog.persist();
    return count;
  }

  @override
  Future<int> holderCountForAchievement(int achievementId) async {
    await Future<void>.delayed(_latency);
    return _catalog.holderCountForAchievement(achievementId);
  }

  int _indexOf(int id) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) throw StateError('Награда $id не найдена');
    return index;
  }
}
