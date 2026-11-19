import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/models/page_result.dart';
import 'package:yp_ceryak/widgets/entity_paginator.dart';

void main() {
  testWidgets('EntityPaginator shows range and next page', (tester) async {
    var selectedPage = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntityPaginator<int>(
            page: const PageResult(
              items: [1, 2, 3],
              page: 1,
              size: 10,
              total: 30,
            ),
            onPageSizeChanged: (_) {},
            onPageSelected: (p) => selectedPage = p,
          ),
        ),
      ),
    );
    expect(find.textContaining('из 30'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(selectedPage, 2);
  });
}
