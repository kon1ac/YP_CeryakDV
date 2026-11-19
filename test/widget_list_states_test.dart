import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/widgets/list_states.dart';

void main() {
  testWidgets('ListLoadingState shows progress and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ListLoadingState())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Загрузка…'), findsOneWidget);
  });

  testWidgets('ListEmptyState shows reset when provided', (tester) async {
    var reset = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListEmptyState(onReset: () => reset = true),
        ),
      ),
    );
    expect(find.text('Ничего не найдено'), findsOneWidget);
    await tester.tap(find.text('Сбросить фильтры'));
    expect(reset, isTrue);
  });

  testWidgets('ListErrorState retry button works', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListErrorState(
            message: 'сеть упала',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.textContaining('сеть упала'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });
}
