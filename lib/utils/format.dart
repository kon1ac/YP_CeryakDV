class Format {
  const Format._();

  static String price(double value) {
    final rounded = value.roundToDouble();
    final whole = rounded == value ? _group(value.toInt()) : _group(value);
    return '$whole\u00A0₽';
  }

  static String _group(num value) {
    final text = value.abs().toString();
    final dot = text.indexOf('.');
    final digits = dot == -1 ? text : text.substring(0, dot);
    final fraction = dot == -1 ? '' : text.substring(dot);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00A0');
      buffer.write(digits[i]);
    }
    final sign = value < 0 ? '−' : '';
    return '$sign$buffer$fraction';
  }

  static String date(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.day)}.${_two(local.month)}.${local.year}';
  }

  static String plain(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();

  static double? parseAmount(String raw) {
    final cleaned = _strip(raw);
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static int? parseCount(String raw) {
    final cleaned = _strip(raw);
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  static String _strip(String raw) => raw
      .trim()
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');

  static String _two(int value) => value.toString().padLeft(2, '0');
}
