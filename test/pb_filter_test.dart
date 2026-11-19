import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/core/pb_client.dart';

void main() {
  test('pbQuote escapes single quotes', () {
    expect(pbQuote("O'Brien"), "'O\\'Brien'");
  });

  test('pbActiveFilter hides deleted by default', () {
    expect(pbActiveFilter(), contains('deletedAt'));
    expect(pbActiveFilter(includeDeleted: true), isNull);
  });

  test('joinFilters combines non-empty parts', () {
    expect(joinFilters([null, '', 'a = 1', 'b = 2']), '(a = 1) && (b = 2)');
    expect(joinFilters([null, '']), '');
  });
}
