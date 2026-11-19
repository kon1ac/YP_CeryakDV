import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/widgets/search_field.dart';

void main() {
  testWidgets('SearchField notifies on change', (tester) async {
    String? value;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchField(
            initialValue: '',
            hintText: 'Поиск',
            onChanged: (v) => value = v,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Овечкин');
    expect(value, 'Овечкин');
  });
}
