const Object unset = Object();

const List<int> pageSizes = [10, 25, 50];

const int defaultSize = 10;

int pickSize(String? raw) {
  final value = int.tryParse((raw ?? '').trim());
  return pageSizes.contains(value) ? value! : defaultSize;
}

bool isSearchActiveFrom(String search) => search.trim().isNotEmpty;

abstract interface class Identifiable {
  int get id;

  DateTime? get deletedAt;

  bool get isDeleted;

  String get label;
}

abstract class ListQuery<Q extends ListQuery<Q>> {
  const ListQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = defaultSize,
    this.includeDeleted = false,
    this.simulateError = false,
  });

  final String search;

  final String sortField;

  final bool sortAscending;

  final int page;

  final int size;

  final bool includeDeleted;

  final bool simulateError;

  bool get isSearchActive => search.trim().isNotEmpty;

  bool get isFiltered;

  Map<String, String> toQueryParameters();

  Q withBase({
    Object? search = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  });

  Q withPage(int page);
}

double? parseDouble(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return double.tryParse(raw.trim().replaceAll(',', '.'));
}

int? parseInt(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return int.tryParse(raw.trim());
}

(String, bool) parseSort(String? raw, {String fallback = 'name'}) {
  if (raw == null || raw.trim().isEmpty) return (fallback, true);
  final parts = raw.split(',');
  final field = parts.first.trim();
  final descending = parts.length > 1 && parts[1].trim().toLowerCase() == 'desc';
  return (field.isEmpty ? fallback : field, !descending);
}

Map<String, String> baseQueryParameters({
  required String sortField,
  required bool sortAscending,
  required int page,
  required int size,
  required bool includeDeleted,
  required bool simulateError,
  String defaultSortField = 'name',
}) {
  return <String, String>{
    if (sortField != defaultSortField || !sortAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page > 1) 'page': '$page',
    if (size != defaultSize) 'size': '$size',
    if (includeDeleted) 'includeDeleted': 'true',
    if (simulateError) 'error': 'true',
  };
}

String plainNumber(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
