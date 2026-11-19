String readId(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

List<String> readIdList(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item != null && '$item'.isNotEmpty) '$item',
  ];
}

DateTime? readDate(dynamic value) {
  if (value == null || (value is String && value.isEmpty)) return null;
  return DateTime.tryParse(value.toString());
}
