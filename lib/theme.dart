import 'package:flutter/material.dart';

import 'prefs.dart';

const _darkKey = 'dark_theme';

const _seed = Color(0xFF1B5E9C);

ThemeData appTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.comfortable,
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
