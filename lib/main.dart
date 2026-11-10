import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'prefs.dart';
import 'repositories/achievement_repository.dart';
import 'repositories/arena_repository.dart';
import 'repositories/contract_repository.dart';
import 'repositories/hockey_player_repository.dart';
import 'repositories/in_memory_catalog.dart';
import 'repositories/in_memory_hockey_player_repository.dart';
import 'repositories/team_repository.dart';
import 'router.dart';
import 'state/achievement_list_notifier.dart';
import 'state/arena_list_notifier.dart';
import 'state/contract_list_notifier.dart';
import 'state/player_list_notifier.dart';
import 'state/team_list_notifier.dart';
import 'storage/catalog_store.dart';
import 'theme.dart';

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();

  final load = await CatalogStore.load();

  runApp(StoreApp(load: load));
}

class StoreApp extends StatefulWidget {
  const StoreApp({super.key, required this.load});

  final CatalogLoadResult load;

  @override
  State<StoreApp> createState() => _StoreAppState();
}

class _StoreAppState extends State<StoreApp> {
  final _theme = ThemeController();

  late final InMemoryCatalog _catalog = widget.load.catalog ?? InMemoryCatalog();

  @override
  void initState() {
    super.initState();
    _catalog.onChanged = CatalogStore.save;
    final notice = widget.load.notice;
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNotice(notice));
    }
  }

  void _showNotice(String notice) {
    final context = _messengerKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(notice)));
  }

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

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
        Provider<ArenaRepository>(
          create: (_) => InMemoryArenaRepository(_catalog),
        ),
        ChangeNotifierProvider<ArenaListNotifier>(
          create: (context) =>
              ArenaListNotifier(context.read<ArenaRepository>()),
        ),
        Provider<AchievementRepository>(
          create: (_) => InMemoryAchievementRepository(_catalog),
        ),
        Provider<ContractRepository>(
          create: (_) => InMemoryContractRepository(_catalog),
        ),
        ChangeNotifierProvider<ContractListNotifier>(
          create: (context) =>
              ContractListNotifier(context.read<ContractRepository>()),
        ),
        ChangeNotifierProvider<AchievementListNotifier>(
          create: (context) =>
              AchievementListNotifier(context.read<AchievementRepository>()),
        ),
      ],
      child: ThemeScope(
        controller: _theme,
        child: AnimatedBuilder(
          animation: _theme,
          builder: (context, _) => MaterialApp.router(
            title: 'Витрина хоккейных игроков',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: _messengerKey,
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
