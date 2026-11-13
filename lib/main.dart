import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_session.dart';
import 'core/dictionary_cache.dart';
import 'prefs.dart';
import 'repositories/achievement_repository.dart';
import 'repositories/api_achievement_repository.dart';
import 'repositories/api_arena_repository.dart';
import 'repositories/api_contract_repository.dart';
import 'repositories/api_hockey_player_repository.dart';
import 'repositories/api_team_repository.dart';
import 'repositories/arena_repository.dart';
import 'repositories/contract_repository.dart';
import 'repositories/hockey_player_repository.dart';
import 'repositories/team_repository.dart';
import 'router.dart';
import 'state/achievement_list_notifier.dart';
import 'state/arena_list_notifier.dart';
import 'state/contract_list_notifier.dart';
import 'state/player_list_notifier.dart';
import 'state/team_list_notifier.dart';
import 'theme.dart';

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();

  final auth = AuthSession();
  final dio = buildDio(tokenProvider: () => auth.accessToken);
  await auth.ensureSignedIn(dio);

  runApp(StoreApp(dio: dio, auth: auth));
}

class StoreApp extends StatefulWidget {
  const StoreApp({super.key, required this.dio, required this.auth});

  final Dio dio;
  final AuthSession auth;

  @override
  State<StoreApp> createState() => _StoreAppState();
}

class _StoreAppState extends State<StoreApp> {
  final _theme = ThemeController();
  final _cache = DictionaryCache();

  @override
  void dispose() {
    _theme.dispose();
    widget.dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>.value(value: widget.dio),
        Provider<AuthSession>.value(value: widget.auth),
        Provider<DictionaryCache>.value(value: _cache),
        ProxyProvider2<Dio, DictionaryCache, HockeyPlayerRepository>(
          update: (_, dio, cache, previous) =>
              previous ?? ApiHockeyPlayerRepository(dio, cache),
        ),
        ChangeNotifierProxyProvider<HockeyPlayerRepository, PlayerListNotifier>(
          create: (context) =>
              PlayerListNotifier(context.read<HockeyPlayerRepository>()),
          update: (_, repository, previous) =>
              previous ?? PlayerListNotifier(repository),
        ),
        ProxyProvider2<Dio, DictionaryCache, TeamRepository>(
          update: (_, dio, cache, previous) =>
              previous ?? ApiTeamRepository(dio, cache),
        ),
        ChangeNotifierProxyProvider<TeamRepository, TeamListNotifier>(
          create: (context) =>
              TeamListNotifier(context.read<TeamRepository>()),
          update: (_, repository, previous) =>
              previous ?? TeamListNotifier(repository),
        ),
        ProxyProvider2<Dio, DictionaryCache, ArenaRepository>(
          update: (_, dio, cache, previous) =>
              previous ?? ApiArenaRepository(dio, cache),
        ),
        ChangeNotifierProxyProvider<ArenaRepository, ArenaListNotifier>(
          create: (context) =>
              ArenaListNotifier(context.read<ArenaRepository>()),
          update: (_, repository, previous) =>
              previous ?? ArenaListNotifier(repository),
        ),
        ProxyProvider2<Dio, DictionaryCache, AchievementRepository>(
          update: (_, dio, cache, previous) =>
              previous ?? ApiAchievementRepository(dio, cache),
        ),
        ChangeNotifierProxyProvider<AchievementRepository,
            AchievementListNotifier>(
          create: (context) => AchievementListNotifier(
            context.read<AchievementRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? AchievementListNotifier(repository),
        ),
        ProxyProvider<Dio, ContractRepository>(
          update: (_, dio, previous) => previous ?? ApiContractRepository(dio),
        ),
        ChangeNotifierProxyProvider<ContractRepository, ContractListNotifier>(
          create: (context) =>
              ContractListNotifier(context.read<ContractRepository>()),
          update: (_, repository, previous) =>
              previous ?? ContractListNotifier(repository),
        ),
      ],
      child: ThemeScope(
        controller: _theme,
        child: AnimatedBuilder(
          animation: _theme,
          builder: (context, _) => MaterialApp.router(
            title: 'Витрина хоккейных игроков',
            debugShowCheckedModeBanner: false,
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            themeMode: _theme.mode,
            routerConfig: appRouter,
          ),
        ),
      ),
    );
  }
}
