import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/logic/calculator.dart';
import 'package:yp_ceryak/logic/numbers.dart';

void main() {
  group('parseNumber', () {
    test('понимает точку и запятую', () {
      expect(parseNumber('2.5'), 2.5);
      expect(parseNumber('2,5'), 2.5);
      expect(parseNumber(' -3 '), -3);
    });

    test('возвращает null для пустого и нечислового ввода', () {
      expect(parseNumber(null), isNull);
      expect(parseNumber(''), isNull);
      expect(parseNumber('   '), isNull);
      expect(parseNumber('abc'), isNull);
      expect(parseNumber('1,2,3'), isNull);
    });
  });

  group('formatNumber', () {
    test('убирает хвостовые нули', () {
      expect(formatNumber(5), '5');
      expect(formatNumber(2.5), '2.5');
      expect(formatNumber(0.1 + 0.2), '0.3');
    });

    test('округляет длинную дробь', () {
      expect(formatNumber(1 / 3), '0.333333');
      expect(formatNumber(2 / 3), '0.666667');
    });

    test('очень маленькие числа пишет экспонентой', () {
      expect(formatNumber(0.0000001), contains('e'));
    });
  });

  group('calculate', () {
    test('выполняет четыре операции', () {
      expect((calculate('2', '+', '3') as CalcSuccess).value, 5);
      expect((calculate('2', '-', '3') as CalcSuccess).value, -1);
      expect((calculate('2', '*', '3') as CalcSuccess).value, 6);
      expect((calculate('6', '/', '3') as CalcSuccess).value, 2);
    });

    test('понимает запятую в параметрах адреса', () {
      expect((calculate('1,5', '+', '2,5') as CalcSuccess).value, 4);
    });

    test('деление на ноль — ошибка', () {
      final result = calculate('1', '/', '0');
      expect(result, isA<CalcFailure>());
      expect((result as CalcFailure).message, contains('ноль'));
    });

    test('нечисловые параметры — ошибка', () {
      expect(calculate('abc', '+', '2'), isA<CalcFailure>());
      expect(calculate('2', '+', ''), isA<CalcFailure>());
    });

    test('отсутствующие параметры — ошибка', () {
      expect(calculate(null, null, null), isA<CalcFailure>());
      expect(calculate('2', '+', null), isA<CalcFailure>());
    });

    test('неизвестная операция — ошибка', () {
      final result = calculate('2', '%', '3');
      expect(result, isA<CalcFailure>());
      expect((result as CalcFailure).message, contains('операция'));
    });
  });
}
