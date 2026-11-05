import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/logic/currency.dart';

void main() {
  group('currencyByCode', () {
    test('находит валюту по коду', () {
      expect(currencyByCode('USD')?.name, 'Доллар США');
      expect(currencyByCode('RUB')?.rateToRub, 1);
    });

    test('возвращает null для неизвестного кода', () {
      expect(currencyByCode('XXX'), isNull);
      expect(currencyByCode(null), isNull);
      expect(currencyByCode(''), isNull);
    });

    test('в списке не меньше пяти валют и нет дубликатов', () {
      expect(currencies.length, greaterThanOrEqualTo(5));
      final codes = currencies.map((c) => c.code).toSet();
      expect(codes.length, currencies.length);
    });
  });

  group('convert', () {
    test('пересчитывает через рубль', () {
      final result = convert('100', 'USD', 'RUB') as ConversionSuccess;
      expect(result.value, closeTo(9250, 0.001));
    });

    test('пересчитывает между не-рублёвыми валютами', () {
      final result = convert('1', 'EUR', 'USD') as ConversionSuccess;
      expect(result.value, closeTo(100.2 / 92.5, 0.0001));
    });

    test('одинаковые валюты дают ту же сумму', () {
      final result = convert('42', 'EUR', 'EUR') as ConversionSuccess;
      expect(result.value, closeTo(42, 1e-9));
    });

    test('сумма с запятой', () {
      final result = convert('1,5', 'RUB', 'RUB') as ConversionSuccess;
      expect(result.value, 1.5);
    });

    test('нечисловая сумма — ошибка', () {
      expect(convert('abc', 'USD', 'RUB'), isA<ConversionFailure>());
      expect(convert(null, 'USD', 'RUB'), isA<ConversionFailure>());
    });

    test('неизвестная валюта — ошибка', () {
      expect(convert('10', 'XXX', 'RUB'), isA<ConversionFailure>());
      expect(convert('10', 'USD', 'XXX'), isA<ConversionFailure>());
      expect(convert('10', null, null), isA<ConversionFailure>());
    });
  });
}
