import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/screens/calculator_screen.dart';
import 'package:yp_ceryak/screens/converter_screen.dart';
import 'package:yp_ceryak/screens/home_screen.dart';
import 'package:yp_ceryak/screens/not_found_screen.dart';
import 'package:yp_ceryak/screens/result_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('главная открывается по / и ведёт в калькулятор', (tester) async {
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Калькулятор'));
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorScreen), findsOneWidget);
  });

  testWidgets('главная ведёт в конвертер', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Конвертер валют'));
    await tester.pumpAndSettle();

    expect(find.byType(ConverterScreen), findsOneWidget);
  });

  testWidgets('калькулятор считает и открывает отдельный экран результата',
      (tester) async {
    await pumpApp(tester, location: '/calculator');

    await tester.enterText(find.byType(TextFormField).first, '2');
    await tester.enterText(find.byType(TextFormField).last, '3');
    await tester.tap(find.text('Вычислить'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('a=2'), findsOneWidget);
  });

  testWidgets('пустые поля не приводят к переходу', (tester) async {
    await pumpApp(tester, location: '/calculator');

    await tester.tap(find.text('Вычислить'));
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
    expect(find.text('Введите число'), findsNWidgets(2));
  });

  testWidgets('нечисловой ввод не приводит к переходу', (tester) async {
    await pumpApp(tester, location: '/calculator');

    await tester.enterText(find.byType(TextFormField).first, 'abc');
    await tester.enterText(find.byType(TextFormField).last, '2');
    await tester.tap(find.text('Вычислить'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsNothing);
    expect(find.text('Это не число'), findsOneWidget);
  });

  testWidgets('адрес результата открывается напрямую', (tester) async {
    await pumpApp(tester, location: '/calculator/result?a=10&op=*&b=4');

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('деление на ноль показывается сообщением', (tester) async {
    await pumpApp(tester, location: '/calculator/result?a=1&op=/&b=0');

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Деление на ноль невозможно'), findsOneWidget);
  });

  testWidgets('некорректные параметры дают сообщение, а не исключение',
      (tester) async {
    await pumpApp(tester, location: '/calculator/result?a=abc&op=/&b=xyz');

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('В адресе переданы не числа'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('неизвестный адрес показывает экран 404', (tester) async {
    await pumpApp(tester, location: '/qwerty');

    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.text('404'), findsOneWidget);
    expect(find.text('/qwerty'), findsOneWidget);
  });

  testWidgets('конвертер пересчитывает сумму на отдельном экране',
      (tester) async {
    await pumpApp(tester, location: '/converter');

    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.tap(find.text('Перевести'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    // По умолчанию RUB → USD, курс 92.5.
    expect(find.text('1.081081'), findsOneWidget);
  });

  testWidgets('кнопка темы переключает оформление', (tester) async {
    await pumpApp(tester);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });
}
