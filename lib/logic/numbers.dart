
double? parseNumber(String? raw) {
  if (raw == null) return null;
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String formatNumber(double value) {
  if (!value.isFinite) return '—';
  if (value != 0 && value.abs() < 0.000001) {
    return value.toStringAsExponential(3);
  }
  var text = value.toStringAsFixed(6);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}
