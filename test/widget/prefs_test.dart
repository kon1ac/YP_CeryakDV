import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yp_ceryak/prefs.dart';
import 'package:yp_ceryak/theme.dart';

import '../helpers/pump_app.dart';

void main() {
  test('тема сохраняется в localStorage', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.init();

    final controller = ThemeController();
    expect(controller.isDark, isFalse);

    controller.toggle();
    expect(controller.isDark, isTrue);

    // Новый контроллер читает уже сохранённое значение.
    final restored = ThemeController();
    expect(restored.isDark, isTrue);
  });

  testWidgets('конвертер запоминает выбранную пару валют', (tester) async {
    await pumpApp(tester, location: '/converter');

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR — Евро').last);
    await tester.pumpAndSettle();

    expect(AppPrefs.instance.getString('converter_from'), 'EUR');
  });

  testWidgets('сохранённая пара валют восстанавливается при открытии',
      (tester) async {
    await pumpApp(
      tester,
      location: '/converter',
      initialPrefs: {'converter_from': 'EUR', 'converter_to': 'CNY'},
    );

    expect(find.text('EUR — Евро'), findsOneWidget);
    expect(find.text('CNY — Китайский юань'), findsOneWidget);
  });

  testWidgets('сохранённая тёмная тема применяется при запуске',
      (tester) async {
    await pumpApp(tester, initialPrefs: {'dark_theme': true});

    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });
}
