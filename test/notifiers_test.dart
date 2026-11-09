import 'package:flutter_test/flutter_test.dart';

import 'package:yp_ceryak/models/player_query.dart';
import 'package:yp_ceryak/models/team_query.dart';
import 'package:yp_ceryak/repositories/in_memory_catalog.dart';
import 'package:yp_ceryak/repositories/in_memory_hockey_player_repository.dart';
import 'package:yp_ceryak/repositories/team_repository.dart';
import 'package:yp_ceryak/state/load_status.dart';
import 'package:yp_ceryak/state/player_list_notifier.dart';
import 'package:yp_ceryak/state/team_list_notifier.dart';

const Duration _wait = Duration(milliseconds: 900);

void main() {
  late InMemoryCatalog catalog;
  late InMemoryHockeyPlayerRepository players;
  late InMemoryTeamRepository teams;
  late PlayerListNotifier model;

  setUp(() {
    catalog = InMemoryCatalog();
    players = InMemoryHockeyPlayerRepository(catalog);
    teams = InMemoryTeamRepository(catalog);
    model = PlayerListNotifier(players);
  });

  tearDown(() => model.dispose());

  test('поиск стартует не раньше задержки ввода', () async {
    expect(PlayerListNotifier.searchDebounce.inMilliseconds,
        greaterThanOrEqualTo(300));

    model.adoptQuery(const PlayerQuery(size: 10));
    await model.init();
    expect(model.query.search, isEmpty);

    model.searchChanged('матв');
    expect(model.query.search, isEmpty);
    expect(model.searchText, 'матв');
    expect(model.hasPendingSearch, isTrue);

    await Future<void>.delayed(_wait);

    expect(model.query.search, 'матв');
    expect(model.hasPendingSearch, isFalse);
    expect(model.searchText, 'матв');
    expect(model.status, LoadStatus.success);
    expect(model.result.items, isNotEmpty);
  });

  test('повторный ввод перезапускает задержку', () async {
    model.adoptQuery(const PlayerQuery(size: 10));
    await model.init();

    model.searchChanged('ма');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    model.searchChanged('матв');
    await Future<void>.delayed(_wait);

    expect(model.query.search, 'матв');
    expect(model.result.items.every((p) =>
        p.name.toLowerCase().contains('матв') ||
        p.description.toLowerCase().contains('матв')), isTrue);
  });

  test('условия публикуются в адрес только при пользовательском действии',
      () async {
    final published = <PlayerQuery>[];
    model.onQueryChanged = published.add;
    model.adoptQuery(const PlayerQuery(size: 10));
    await model.init();

    expect(published, isEmpty);

    await model.applyQuery(const PlayerQuery(search: 'витан', size: 10));
    expect(published, hasLength(1));
    expect(published.single.search, 'витан');

    await model.applyQuery(const PlayerQuery(search: 'витан', size: 10));
    expect(published, hasLength(1));
  });

  test('syncFromQuery применяет условия из адреса без публикации адреса',
      () async {
    final published = <PlayerQuery>[];
    model.onQueryChanged = published.add;
    model.adoptQuery(const PlayerQuery(size: 10));
    await model.init();

    await model.syncFromQuery(const PlayerQuery(size: 10, page: 2));

    expect(model.query.page, 2);
    expect(published, isEmpty);
    expect(model.result.page, 2);
  });

  test('смена страницы сохраняет выделение, смена фильтра — нет', () async {
    model.adoptQuery(const PlayerQuery(size: 10));
    await model.init();
    model.toggleSelection(model.result.items.first.id);
    expect(model.hasSelection, isTrue);

    await model.goToPage(2);
    expect(model.query.page, 2);
    expect(model.hasSelection, isTrue);

    await model.applyQuery(model.query.copyWith(category: 'Вратарь'));
    expect(model.hasSelection, isFalse);
  });

  test('сброс фильтров оставляет размер и сортировку', () async {
    model.adoptQuery(const PlayerQuery(size: 25, sortField: 'price'));
    await model.init();
    await model.applyQuery(
        model.query.copyWith(category: 'Нападающий', search: 'медвед'));

    await model.resetFilters();

    expect(model.query.category, isNull);
    expect(model.query.search, isEmpty);
    expect(model.query.size, 25);
    expect(model.query.sortField, 'price');
    expect(model.result.total,
        catalog.players.where((p) => !p.isDeleted).length);
  });

  test(
      'сортировка разворачивается повторным кликом по той же колонке', () async {
    model.adoptQuery(const PlayerQuery(size: 50));
    await model.init();

    await model.toggleSort('price');
    expect(model.query.sortField, 'price');
    expect(model.query.sortAscending, isTrue);

    await model.toggleSort('price');
    expect(model.query.sortAscending, isFalse);

    final descending = model.result.items.map((p) => p.price).toList();
    expect(descending, descending.toList()..sort((a, b) => b.compareTo(a)));
  });

  test('отметка «проданные» и массовое удаление работают через notifier',
      () async {
    model.adoptQuery(const PlayerQuery(size: 50));
    await model.init();
    final total = model.result.total;

    model.toggleSelectPage();
    final selectedCount = model.result.items.length;
    expect(model.selected, hasLength(selectedCount));

    final deleted = await model.deleteSelected();
    expect(deleted, selectedCount);
    expect(model.hasSelection, isFalse);
    expect(model.result.total, lessThan(total));

    await model.toggleShowDeleted();
    expect(model.query.includeDeleted, isTrue);
    expect(model.result.total, catalog.players.length);
  });

  test('сбой загрузки переводит экран в состояние ошибки', () async {
    model.adoptQuery(const PlayerQuery(size: 10));
    await model.init();

    await model.applyQuery(model.query.copyWith(simulateError: true));

    expect(model.status, LoadStatus.error);
    expect(model.error, isNotNull);

    await model.applyQuery(model.query.copyWith(simulateError: false));
    expect(model.status, LoadStatus.success);
    expect(model.result.items, isNotEmpty);
  });

  test('нотифайер команд загружает список и города', () async {
    final teamsModel = TeamListNotifier(teams);
    addTearDown(teamsModel.dispose);
    teamsModel.adoptQuery(const TeamQuery(size: 50));
    await teamsModel.init();

    expect(teamsModel.cityOptions, isNotEmpty);
    expect(teamsModel.status, LoadStatus.success);
    expect(teamsModel.result.total,
        catalog.teams.where((t) => !t.isDeleted).length);
    expect(teamsModel.result.items.any((t) => t.rosterSize > 0), isTrue);

    final city = teamsModel.cityOptions.first;
    await teamsModel.applyQuery(teamsModel.query.copyWith(search: city));

    expect(teamsModel.result.items, isNotEmpty);
    expect(
      teamsModel.result.items.every((t) =>
          t.name.toLowerCase().contains(city.toLowerCase()) ||
          t.city.toLowerCase().contains(city.toLowerCase())),
      isTrue,
    );
  });
}
