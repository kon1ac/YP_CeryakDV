import 'package:flutter/material.dart';

import 'prefs.dart';

const _darkKey = 'dark_theme';

ThemeData appTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}

class ThemeController extends ChangeNotifier {
  bool _isDark = AppPrefs.instance.getBool(_darkKey) ?? false;

  bool get isDark => _isDark;

  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    AppPrefs.instance.setBool(_darkKey, _isDark);
    notifyListeners();
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope!.notifier!;
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    return IconButton(
      tooltip: controller.isDark ? 'Светлая тема' : 'Тёмная тема',
      onPressed: controller.toggle,
      icon: Icon(controller.isDark ? Icons.light_mode : Icons.dark_mode),
    );
  }
}
