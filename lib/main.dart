import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'prefs.dart';
import 'repositories/hockey_player_repository.dart';
import 'repositories/in_memory_catalog.dart';
import 'repositories/in_memory_hockey_player_repository.dart';
import 'repositories/team_repository.dart';
import 'router.dart';
import 'state/player_list_notifier.dart';
import 'state/team_list_notifier.dart';
import 'theme.dart';

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();

  runApp(const StoreApp());
}

class StoreApp extends StatefulWidget {
  const StoreApp({super.key});

  @override
  State<StoreApp> createState() => _StoreAppState();
}

class _StoreAppState extends State<StoreApp> {
  final _theme = ThemeController();

  final _catalog = InMemoryCatalog();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HockeyPlayerRepository>(
          create: (_) => InMemoryHockeyPlayerRepository(_catalog),
        ),
        ChangeNotifierProvider<PlayerListNotifier>(
          create: (context) =>
              PlayerListNotifier(context.read<HockeyPlayerRepository>()),
        ),
        Provider<TeamRepository>(
          create: (_) => InMemoryTeamRepository(_catalog),
        ),
        ChangeNotifierProvider<TeamListNotifier>(
          create: (context) =>
              TeamListNotifier(context.read<TeamRepository>()),
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
