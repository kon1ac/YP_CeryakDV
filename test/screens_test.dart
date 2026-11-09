import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:yp_ceryak/repositories/hockey_player_repository.dart';
import 'package:yp_ceryak/repositories/in_memory_catalog.dart';
import 'package:yp_ceryak/repositories/in_memory_hockey_player_repository.dart';
import 'package:yp_ceryak/repositories/team_repository.dart';
import 'package:yp_ceryak/screens/players_list_screen.dart';
import 'package:yp_ceryak/screens/teams_list_screen.dart';
import 'package:yp_ceryak/state/player_list_notifier.dart';
import 'package:yp_ceryak/state/team_list_notifier.dart';
import 'package:yp_ceryak/theme.dart';

Widget _harness({required String location}) {
  final catalog = InMemoryCatalog();
  final players = InMemoryHockeyPlayerRepository(catalog);
  final teams = InMemoryTeamRepository(catalog);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/players',
        builder: (context, state) => PlayersListScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => TeamsListScreen(uri: state.uri),
      ),
    ],
  );
  addTearDown(router.dispose);

  return MultiProvider(
    providers: [
      Provider<HockeyPlayerRepository>.value(value: players),
      Provider<TeamRepository>.value(value: teams),
      ChangeNotifierProvider<PlayerListNotifier>(
        create: (_) => PlayerListNotifier(players),
      ),
      ChangeNotifierProvider<TeamListNotifier>(
        create: (_) => TeamListNotifier(teams),
      ),
    ],
    child: MaterialApp.router(
      theme: appTheme(Brightness.light),
      routerConfig: router,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Finder _byGenericType(String name) => find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString().split('<').first == name,
    );

void main() {
  testWidgets('на широком экране список игроков показан таблицей',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(location: '/players'));
    await _settle(tester);

    expect(find.byType(DataTable), findsOneWidget);
    expect(_byGenericType('EntityCard'), findsNothing);
    expect(find.text('Хоккеисты'), findsOneWidget);
  });

  testWidgets('на узком экране те же записи показаны карточками',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(location: '/players'));
    await _settle(tester);

    expect(find.byType(DataTable), findsNothing);
    expect(_byGenericType('EntityCard'), findsWidgets);
  });

  testWidgets('пагинатор показывает счётчик и номер страницы',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(location: '/players'));
    await _settle(tester);

    expect(find.textContaining('Записи 1–10 из'), findsOneWidget);
    expect(find.text('Стр. 1 из 4'), findsOneWidget);
  });

  testWidgets('условия из адреса восстанавливаются при открытии ссылки',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _harness(location: '/players?size=25&sort=price,desc&page=2'),
    );
    await _settle(tester);

    expect(find.text('Стр. 2 из 2'), findsOneWidget);
    expect(find.textContaining('Записи 26–'), findsOneWidget);
  });

  testWidgets('поиск без совпадений показывает пустое состояние с кнопкой',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(location: '/players?search=крякря'));
    await _settle(tester);

    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.text('Сбросить фильтры'), findsOneWidget);
  });

  testWidgets('сбой загрузки показывает состояние ошибки с кнопкой повтора',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(location: '/players?error=true'));
    await _settle(tester);

    expect(find.text('Не удалось загрузить данные'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('экран команд показывает колонку состава', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(location: '/teams'));
    await _settle(tester);

    expect(find.text('Команды'), findsWidgets);
    expect(find.text('Игроков'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
  });
}
