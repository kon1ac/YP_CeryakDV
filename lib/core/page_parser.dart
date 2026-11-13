import '../models/page_result.dart';

PageResult<T> parsePageResult<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson, {
  required int fallbackSize,
}) {
  final map = data is Map<String, dynamic>
      ? data
      : Map<String, dynamic>.from(data as Map);
  final rawItems = map['items'];
  final items = <T>[
    if (rawItems is List)
      for (final item in rawItems)
        if (item is Map) fromJson(Map<String, dynamic>.from(item)),
  ];
  return PageResult<T>(
    items: items,
    page: map['page'] as int? ?? 1,
    size: map['size'] as int? ?? fallbackSize,
    total: map['total'] as int? ?? items.length,
  );
}

Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  return Map<String, dynamic>.from(data as Map);
}
