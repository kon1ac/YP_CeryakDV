import 'package:flutter_test/flutter_test.dart';

import 'package:yp_ceryak/models/list_query.dart';
import 'package:yp_ceryak/models/player_query.dart';
import 'package:yp_ceryak/models/team_query.dart';

void main() {
  group('сериализация условий отбора в адрес', () {
    test('пустой запрос не добавляет в адрес ничего', () {
      expect(PlayerQuery.empty.toQueryParameters(), isEmpty);
      expect(TeamQuery.empty.toQueryParameters(), isEmpty);
    });

    test('полный набор условий проходит туда и обратно', () {
      const original = PlayerQuery(
        search: 'костров',
        category: 'Нападающий',
        team: 'Медведи',
        priceFrom: 1000,
        priceTo: 5000,
        sortField: 'price',
        sortAscending: false,
        page: 3,
        size: 25,
        includeDeleted: true,
      );

      final restored =
          PlayerQuery.fromQueryParameters(original.toQueryParameters());

      expect(restored, original);
    });

    test('адрес команды переживает пересылку без потерь', () {
      const original = TeamQuery(
        search: 'омск',
        city: 'Омск',
        playersFrom: 5,
        playersTo: 20,
        sortField: 'players',
        sortAscending: false,
        page: 2,
        size: 50,
      );

      final restored =
          TeamQuery.fromQueryParameters(original.toQueryParameters());

      expect(restored, original);
    });

    test('равные по смыслу условия дают равные объекты', () {
      const a = PlayerQuery(search: 'хоккей', size: 25);
      const b = PlayerQuery(search: 'хоккей', size: 25);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const PlayerQuery(search: 'хоккей', size: 50)));
    });
  });

  group('разбор параметров адреса', () {
    test('недопустимый размер страницы заменяется значением по умолчанию', () {
      expect(pickSize('25'), 25);
      expect(pickSize('7'), defaultSize);
      expect(pickSize(null), defaultSize);
      expect(pickSize('abc'), defaultSize);
    });

    test('сортировка понимает направление и значение по умолчанию', () {
      expect(parseSort('price,desc'), ('price', false));
      expect(parseSort('price,asc'), ('price', true));
      expect(parseSort('price'), ('price', true));
      expect(parseSort(null), ('name', true));
      expect(parseSort(''), ('name', true));
    });

    test('дробная цена сохраняется в адресе без артефактов', () {
      expect(plainNumber(4000), '4000');
      expect(plainNumber(4000.5), '4000.5');
      expect(parseDouble('4000,5'), 4000.5);
      expect(parseDouble(''), isNull);
    });
  });
}
