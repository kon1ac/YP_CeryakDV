import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/models/hockey_player.dart';
import 'package:yp_ceryak/utils/players_csv.dart';

void main() {
  test('playersToCsv includes header and rows', () {
    const players = [
      HockeyPlayer(
        id: 'p1',
        name: 'Иванов',
        description: 'desc',
        price: 1000,
        category: 'Нападающий',
        teamId: 't1',
        teamName: 'Спартак',
        status: 'in_roster',
        jerseyNumber: 17,
      ),
    ];
    final csv = playersToCsv(players);
    expect(csv, contains('id,name,category'));
    expect(csv, contains('p1'));
    expect(csv, contains('Иванов'));
    expect(csv, contains('Спартак'));
    expect(csv, contains('1000'));
  });

  test('playersToCsv handles empty list', () {
    final csv = playersToCsv(const []);
    expect(csv.trim().split('\n').length, 1);
    expect(csv, contains('jerseyNumber'));
  });
}
