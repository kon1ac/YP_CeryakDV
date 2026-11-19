import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/models/hockey_player.dart';
import 'package:yp_ceryak/utils/format.dart';

void main() {
  testWidgets('status label and Format.price render in UI', (tester) async {
    const player = HockeyPlayer(
      id: '1',
      name: 'Тест',
      description: '',
      price: 1500000,
      category: 'Нападающий',
      teamId: 't',
      status: 'injured',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text(player.statusLabel),
              Text(Format.price(player.price)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Травмирован'), findsOneWidget);
    expect(find.textContaining('₽'), findsOneWidget);
  });
}
