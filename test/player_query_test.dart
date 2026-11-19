import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/models/player_query.dart';

void main() {
  test('PlayerQuery roundtrips string teamId/achievementId', () {
    final query = PlayerQuery.fromQueryParameters({
      'teamId': 'abc123',
      'achievementId': 'ach9',
      'category': 'Вратарь',
      'page': '2',
      'size': '25',
    });
    expect(query.teamId, 'abc123');
    expect(query.achievementId, 'ach9');
    expect(query.category, 'Вратарь');
    expect(query.page, 2);
    expect(query.size, 25);
    final params = query.toQueryParameters();
    expect(params['teamId'], 'abc123');
    expect(params['achievementId'], 'ach9');
  });

  test('PlayerQuery.isFiltered when filters set', () {
    expect(const PlayerQuery().isFiltered, isFalse);
    expect(const PlayerQuery(category: 'Нападающий').isFiltered, isTrue);
    expect(const PlayerQuery(teamId: 't1').isFiltered, isTrue);
  });
}
