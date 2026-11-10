typedef TextValidator = String? Function(String? value);

class Validators {
  const Validators._();

  static String? required(String? value, {String message = 'Поле обязательно'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? maxLength(String? value, int max, {String? message}) {
    final text = value?.trim() ?? '';
    if (text.length <= max) return null;
    return message ?? 'Не больше $max символов';
  }

  static String? minLength(String? value, int min, {String? message}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.length >= min) return null;
    return message ?? 'Не меньше $min символов';
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
    if (!pattern.hasMatch(text)) return 'Некорректный адрес почты';
    return null;
  }

  static String? integer(
    String? value, {
    int? min,
    int? max,
    String? message,
    String? rangeMessage,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return message ?? 'Нужно целое число';
    if (min != null && parsed < min) {
      return rangeMessage ?? 'Не меньше $min';
    }
    if (max != null && parsed > max) {
      return rangeMessage ?? 'Не больше $max';
    }
    return null;
  }

  static String? decimal(
    String? value, {
    double? min,
    double? max,
    String? message,
    String? rangeMessage,
  }) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return message ?? 'Нужно число';
    if (min != null && parsed < min) {
      return rangeMessage ?? 'Не меньше ${_trim(min)}';
    }
    if (max != null && parsed > max) {
      return rangeMessage ?? 'Не больше ${_trim(max)}';
    }
    return null;
  }

  static String? positive(String? value, {String? message}) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return message ?? 'Нужно число';
    if (parsed <= 0) return message ?? 'Значение должно быть больше нуля';
    return null;
  }

  static String? year(String? value) => integer(
        value,
        min: 1900,
        max: 2100,
        message: 'Нужен год, например 2024',
        rangeMessage: 'Год должен быть между 1900 и 2100',
      );

  static String? unique(
    String? value, {
    required bool Function(String candidate) exists,
    String message = 'Такое значение уже используется',
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (exists(text)) return message;
    return null;
  }

  static int? parseInt(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  static DateTime? parseDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String? date(String? value, {String? message}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return message ?? 'Дата в формате 2025-08-01';
    return null;
  }

  static TextValidator all(List<TextValidator> validators) => (value) {
        for (final validator in validators) {
          final error = validator(value);
          if (error != null) return error;
        }
        return null;
      };

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
