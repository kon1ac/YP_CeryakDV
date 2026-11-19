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
  final size = (map['size'] as num?)?.toInt() ??
      (map['perPage'] as num?)?.toInt() ??
      fallbackSize;
  final total = (map['total'] as num?)?.toInt() ??
      (map['totalItems'] as num?)?.toInt() ??
      items.length;
  return PageResult<T>(
    items: items,
    page: (map['page'] as num?)?.toInt() ?? 1,
    size: size,
    total: total,
  );
}

Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  return Map<String, dynamic>.from(data as Map);
}
