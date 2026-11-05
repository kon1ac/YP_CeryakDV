import 'numbers.dart';

typedef Validator = String? Function(String?);

class V {
  static Validator number() {
    return (value) {
      if (value == null || value.trim().isEmpty) return 'Введите число';
      if (parseNumber(value) == null) return 'Это не число';
      return null;
    };
  }
}
