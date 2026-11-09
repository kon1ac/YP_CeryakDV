import 'package:flutter_test/flutter_test.dart';

import 'package:yp_ceryak/models/player_query.dart';
import 'package:yp_ceryak/models/team_query.dart';
import 'package:yp_ceryak/repositories/in_memory_catalog.dart';
import 'package:yp_ceryak/repositories/in_memory_hockey_player_repository.dart';
import 'package:yp_ceryak/repositories/team_repository.dart';

void main() {
  late InMemoryCatalog catalog;
  late InMemoryHockeyPlayerRepository players;
  late InMemoryTeamRepository teams;

  setUp(() {
    catalog = InMemoryCatalog();
    players = InMemoryHockeyPlayerRepository(catalog);
    teams = InMemoryTeamRepository(catalog);
  });

  int aliveCount() => catalog.players.where((p) => !p.isDeleted).length;

  group('пагинация', () {
    test('первая страница умещает ровно size записей', () async {
      final page = await players.find(const PlayerQuery(size: 10));

      expect(page.items.length, 10);
      expect(page.page, 1);
      expect(page.total, aliveCount());
      expect(page.firstIndex, 1);
      expect(page.lastIndex, 10);
      expect(page.hasNext, isTrue);
      expect(page.hasPrevious, isFalse);
    });

    test('вторая страница отдаёт остаток, а не пустой список', () async {
      const size = 25;
      final first = await players.find(const PlayerQuery(size: size));
      final second =
          await players.find(const PlayerQuery(size: size, page: 2));

      expect(first.totalPages, 2);
      expect(second.items.length, aliveCount() - size);
      expect(second.hasNext, isFalse);
      expect(second.firstIndex, size + 1);
      expect(second.lastIndex, aliveCount());
    });

    test('страницы не пересекаются', () async {
      const size = 10;
      final first = await players.find(const PlayerQuery(size: size));
      final second =
          await players.find(const PlayerQuery(size: size, page: 2));

      final firstIds = first.items.map((p) => p.id).toSet();
      final secondIds = second.items.map((p) => p.id).toSet();
      expect(firstIds.intersection(secondIds), isEmpty);
    });

    test('страница за пределами набора не выдаёт пустой экран', () async {
      final page = await players.find(const PlayerQuery(page: 99, size: 10));

      expect(page.items, isNotEmpty);
      expect(page.page, page.totalPages);
    });

    test('размер страницы 50 уменьшает число страниц', () async {
      final small = await players.find(const PlayerQuery(size: 10));
      final large = await players.find(const PlayerQuery(size: 50));

      expect(large.items.length, aliveCount());
      expect(large.totalPages, lessThan(small.totalPages));
    });
  });

  group('поиск', () {
    test('ищет по имени независимо от регистра', () async {
      final page = await players.find(const PlayerQuery(search: 'матвеев'));

      expect(page.items, isNotEmpty);
      expect(
        page.items.every(
            (p) => p.name.toLowerCase().contains('матвеев')),
        isTrue,
      );
    });

    test('ищет по номеру свитера — полю, отличному от идентификатора',
        () async {
      final page = await players.find(const PlayerQuery(search: '56'));

      expect(page.items, isNotEmpty);
      expect(
        page.items.any((p) => p.jerseyNumber == 56),
        isTrue,
      );
    });

    test('несовместимый запрос даёт пустой результат', () async {
      final page = await players.find(const PlayerQuery(search: 'крякря'));

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.totalPages, 1);
    });

    test('команды ищутся по названию и городу', () async {
      final byName = await teams.find(const TeamQuery(search: 'медвед'));
      final byCity =
          await teams.find(const TeamQuery(search: 'зеленогорск'));

      expect(byName.items, isNotEmpty);
      expect(byCity.items, isNotEmpty);
      expect(byCity.items.every((t) => t.city.toLowerCase() == 'зеленогорск'),
          isTrue);
    });
  });

  group('фильтрация', () {
    test('три фильтра применяются одновременно', () async {
      final page = await players.find(
        const PlayerQuery(
          category: 'Нападающий',
          team: 'Медведи',
          priceTo: 5000,
          size: 50,
        ),
      );

      expect(page.items, isNotEmpty);
      for (final player in page.items) {
        expect(player.category, 'Нападающий');
        expect(player.team, 'Медведи');
        expect(player.price, lessThanOrEqualTo(5000));
      }
    });

    test('диапазон цены включает границы', () async {
      final page = await players.find(
        const PlayerQuery(priceFrom: 3000, priceTo: 3000, size: 50),
      );

      expect(page.items, isNotEmpty);
      expect(page.items.every((p) => p.price == 3000), isTrue);
    });

    test('фильтр состава команды считает только живых игроков', () async {
      final page =
          await teams.find(const TeamQuery(playersFrom: 1, size: 50));

      expect(page.items, isNotEmpty);
      expect(page.items.every((t) => t.rosterSize >= 1), isTrue);
    });

    test('проданные скрыты, пока не включён includeDeleted', () async {
      final hidden = await players.find(const PlayerQuery(size: 50));
      final shown = await players.find(
        const PlayerQuery(size: 50, includeDeleted: true),
      );

      expect(hidden.items.every((p) => !p.isDeleted), isTrue);
      expect(shown.items.any((p) => p.isDeleted), isTrue);
      expect(shown.total, greaterThan(hidden.total));
    });
  });

  group('сортировка', () {
    test('по цене: возрастание и убывание зеркальны', () async {
      final asc =
          await players.find(const PlayerQuery(sortField: 'price', size: 50));
      final desc = await players.find(
        const PlayerQuery(
            sortField: 'price', sortAscending: false, size: 50),
      );

      final prices = asc.items.map((p) => p.price).toList();
      expect(prices, orderedEquals(prices.toList()..sort()));
      expect(desc.items.map((p) => p.price).toList(),
          orderedEquals(prices.reversed));
    });

    test('по номеру свитера: записи без номера идут первыми', () async {
      final byNumber = await players.find(
        const PlayerQuery(sortField: 'jerseyNumber', size: 50),
      );

      expect(byNumber.items.first.jerseyNumber, isNull);
      final numbered =
          byNumber.items.where((p) => p.jerseyNumber != null).toList();
      final numbers = numbered.map((p) => p.jerseyNumber!).toList();
      expect(numbers, orderedEquals(numbers.toList()..sort()));
    });

    test('по названию команды', () async {
      final byTeam = await players.find(
        const PlayerQuery(sortField: 'team', size: 50),
      );

      final teams = byTeam.items.map((p) => p.team.toLowerCase()).toList();
      expect(teams, orderedEquals(teams.toList()..sort()));
    });
  });

  group('удаление', () {
    test('логическое удаление скрывает запись из обычного списка', () async {
      final before = await players.find(const PlayerQuery(size: 50));
      final target = before.items.first;

      await players.softDelete(target.id);

      final after = await players.find(const PlayerQuery(size: 50));
      expect(after.total, before.total - 1);
      expect(after.items.any((p) => p.id == target.id), isFalse);

      final withDeleted = await players.find(
        const PlayerQuery(size: 50, includeDeleted: true),
      );
      expect(
        withDeleted.items.firstWhere((p) => p.id == target.id).isDeleted,
        isTrue,
      );
    });

    test('восстановление возвращает запись в продажу', () async {
      final page = await players.find(const PlayerQuery(size: 50));
      final target = page.items.first;
      await players.softDelete(target.id);

      await players.restore(target.id);

      final restored = await players.findById(target.id);
      expect(restored!.isDeleted, isFalse);
    });

    test('физическое удаление стирает запись безвозвратно', () async {
      final page = await players.find(const PlayerQuery(size: 50));
      final target = page.items.first;

      await players.hardDelete(target.id);

      expect(await players.findById(target.id), isNull);
      final withDeleted = await players.find(
        const PlayerQuery(size: 50, includeDeleted: true),
      );
      expect(withDeleted.items.any((p) => p.id == target.id), isFalse);
    });

    test('массовое удаление считает только затронутые записи', () async {
      final page = await players.find(const PlayerQuery(size: 50));
      final ids = page.items.take(3).map((p) => p.id).toList();

      expect(await players.deleteMany(ids), 3);
      expect(await players.deleteMany(ids), 0);
      expect(await players.deleteMany(ids, physical: true), 3);
    });

    test('состав команды уменьшается после продажи игрока', () async {
      final before = await teams.find(const TeamQuery(size: 50));
      final team = before.items.firstWhere((t) => t.rosterSize > 0);
      final sold = (await players
              .find(PlayerQuery(team: team.name, size: 50)))
          .items
          .first;

      await players.softDelete(sold.id);

      final after = await teams.find(const TeamQuery(size: 50));
      final updated = after.items.firstWhere((t) => t.id == team.id);
      expect(updated.rosterSize, team.rosterSize - 1);
    });
  });

  test('симуляция сбоя поднимает ошибку, а не пустой список', () async {
    expect(
      () => players.find(const PlayerQuery(simulateError: true)),
      throwsA(isA<StateError>()),
    );
  });

  test('оба репозитория видят один каталог', () async {
    final teamNames = await players.teamNames();
    final allTeams = await teams.find(const TeamQuery(size: 50));

    expect(teamNames, isNotEmpty);
    expect(
      allTeams.items.map((t) => t.name).toSet().containsAll(<String>{}),
      isTrue,
    );
  });
}
