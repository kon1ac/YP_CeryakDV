import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/core/page_parser.dart';

void main() {
  test('parsePageResult reads PocketBase totalItems/perPage', () {
    final page = parsePageResult(
      {
        'page': 2,
        'perPage': 25,
        'totalItems': 40,
        'items': [
          {'id': 'a', 'name': 'A'},
          {'id': 'b', 'name': 'B'},
        ],
      },
      (json) => json['id'] as String,
      fallbackSize: 10,
    );
    expect(page.page, 2);
    expect(page.size, 25);
    expect(page.total, 40);
    expect(page.items, ['a', 'b']);
  });

  test('parsePageResult falls back to size/total keys', () {
    final page = parsePageResult(
      {
        'page': 1,
        'size': 10,
        'total': 1,
        'items': [
          {'v': 1},
        ],
      },
      (json) => json['v'] as int,
      fallbackSize: 5,
    );
    expect(page.size, 10);
    expect(page.total, 1);
    expect(page.items.single, 1);
  });
}
