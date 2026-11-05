import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final size in const [Size(360, 640), Size(1920, 1080)]) {
    testWidgets('раскладка не ломается при окне ${size.width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final location in const [
        '/',
        '/calculator',
        '/converter',
        '/calculator/result?a=1&op=/&b=3',
        '/qwerty',
      ]) {
        await pumpApp(tester, location: location);
        expect(tester.takeException(), isNull, reason: 'адрес $location');
      }
    });
  }

  testWidgets('форма не растягивается на всю ширину монитора', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, location: '/calculator');

    final formWidth = tester.getSize(find.byType(Form)).width;
    expect(formWidth, lessThanOrEqualTo(420));
  });
}
