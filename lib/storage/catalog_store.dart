import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/hockey_player.dart';
import '../models/team.dart';
import '../repositories/in_memory_catalog.dart';

enum CatalogLoadStatus { restored, seeded, migrated, reset }

class CatalogLoadResult {
  const CatalogLoadResult(this.status, this.notice, {this.catalog});

  final CatalogLoadStatus status;

  final String? notice;

  final InMemoryCatalog? catalog;

  bool get restored => status == CatalogLoadStatus.restored;
}

class CatalogStore {
  CatalogStore._();

  static const int version = 2;

  static const String key = 'catalog.v$version';

  static const List<String> legacyKeys = ['catalog.v1'];

  static Future<CatalogLoadResult> load() async {
    final prefs = await SharedPreferences.getInstance();

    final legacyFound = legacyKeys.any(prefs.containsKey);
    for (final legacy in legacyKeys) {
      if (prefs.containsKey(legacy)) await prefs.remove(legacy);
    }

    final raw = prefs.getString(key);
    if (raw != null) {
      final restored = _decode(raw);
      if (restored != null) {
        return CatalogLoadResult(
          CatalogLoadStatus.restored,
          null,
          catalog: restored,
        );
      }
      await prefs.remove(key);
      return const CatalogLoadResult(
        CatalogLoadStatus.reset,
        'Сохранённые данные повреждены и не читаются. '
        'Справочник загружен заново, правки придётся внести повторно.',
      );
    }

    if (legacyFound) {
      return const CatalogLoadResult(
        CatalogLoadStatus.migrated,
        'Формат хранения обновился. Прежние записи несовместимы, '
        'поэтому справочник загружен заново.',
      );
    }

    return const CatalogLoadResult(CatalogLoadStatus.seeded, null);
  }

  static Future<InMemoryCatalog?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return _decode(raw);
  }

  static InMemoryCatalog? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      if (json['version'] != version) return null;
      return catalogFromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(InMemoryCatalog catalog) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(catalogToJson(catalog)));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    for (final legacy in legacyKeys) {
      await prefs.remove(legacy);
    }
  }
}

Map<String, dynamic> catalogToJson(InMemoryCatalog catalog) => {
      'version': CatalogStore.version,
      'players': [for (final player in catalog.players) player.toJson()],
      'teams': [for (final team in catalog.teams) team.toJson()],
      'arenas': [for (final arena in catalog.arenas) arena.toJson()],
      'achievements': [
        for (final achievement in catalog.achievements) achievement.toJson(),
      ],
      'counters': {
        'player': catalog.nextPlayerIdValue,
        'team': catalog.nextTeamIdValue,
        'arena': catalog.nextArenaIdValue,
        'achievement': catalog.nextAchievementIdValue,
      },
    };

InMemoryCatalog catalogFromJson(Map<String, dynamic> json) {
  List<T> rows<T>(String key, T Function(Map<String, dynamic>) build) {
    final raw = json[key];
    if (raw is! List) return <T>[];
    return [
      for (final item in raw)
        if (item is Map) build(Map<String, dynamic>.from(item)),
    ];
  }

  final players = rows('players', HockeyPlayer.fromJson);
  final teams = rows('teams', Team.fromJson);
  final arenas = rows('arenas', Arena.fromJson);
  final achievements = rows('achievements', Achievement.fromJson);
  final counters = json['counters'];
  final counterMap =
      counters is Map ? Map<String, dynamic>.from(counters) : const {};

  int next(String name, int fallback) => counterMap[name] as int? ?? fallback;

  return InMemoryCatalog.restored(
    players: players,
    teams: teams,
    arenas: arenas,
    achievements: achievements,
    nextPlayerId: next('player', players.length + 1),
    nextTeamId: next('team', teams.length + 1),
    nextArenaId: next('arena', arenas.length + 1),
    nextAchievementId: next('achievement', achievements.length + 1),
  );
}
