import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yp_ceryak/prefs.dart';
import 'package:yp_ceryak/router.dart';
import 'package:yp_ceryak/theme.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  String? location,
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  await AppPrefs.init();

  final router = buildRouter();
  if (location != null) {
    router.go(location);
  }

  final controller = ThemeController();

  await tester.pumpWidget(
    ThemeScope(
      controller: controller,
      child: MaterialApp.router(
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: controller.mode,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
