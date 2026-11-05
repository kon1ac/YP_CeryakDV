import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/logic/validators.dart';

void main() {
  group('V.number', () {
    test('пропускает числа в разной записи', () {
      final validate = V.number();
      expect(validate('5'), isNull);
      expect(validate('2.5'), isNull);
      expect(validate('2,5'), isNull);
      expect(validate(' -10 '), isNull);
    });

    test('ругает пустое поле', () {
      final validate = V.number();
      expect(validate(null), 'Введите число');
      expect(validate(''), 'Введите число');
      expect(validate('   '), 'Введите число');
    });

    test('ругает нечисловой ввод', () {
      final validate = V.number();
      expect(validate('abc'), 'Это не число');
      expect(validate('1.2.3'), 'Это не число');
    });
  });
}
