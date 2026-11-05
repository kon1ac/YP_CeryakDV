import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'prefs.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init();

  runApp(const CalcApp());
}

class CalcApp extends StatefulWidget {
  const CalcApp({super.key});

  @override
  State<CalcApp> createState() => _CalcAppState();
}

class _CalcAppState extends State<CalcApp> {
  final _theme = ThemeController();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _theme,
      child: AnimatedBuilder(
        animation: _theme,
        builder: (context, _) => MaterialApp.router(
          title: 'Калькулятор и конвертер',
          debugShowCheckedModeBanner: false,
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          themeMode: _theme.mode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
