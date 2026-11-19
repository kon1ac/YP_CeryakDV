import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/core/id_codec.dart';

void main() {
  test('readId converts numbers and null', () {
    expect(readId(null), '');
    expect(readId(12), '12');
    expect(readId('abc'), 'abc');
  });

  test('readIdList skips empty', () {
    expect(readIdList([1, 'x', null, '']), ['1', 'x']);
    expect(readIdList('nope'), isEmpty);
  });

  test('readDate parses iso or null', () {
    expect(readDate(null), isNull);
    expect(readDate(''), isNull);
    expect(readDate('2024-01-02T00:00:00.000Z'), isNotNull);
  });
}
