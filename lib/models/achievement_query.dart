import 'list_query.dart';

class AchievementQuery extends ListQuery<AchievementQuery> {
  const AchievementQuery({
    super.search = '',
    this.yearFrom,
    this.yearTo,
    super.sortField = 'name',
    super.sortAscending = true,
    super.page = 1,
    super.size,
    super.includeDeleted = false,
    super.simulateError = false,
  });

  static const AchievementQuery empty = AchievementQuery();

  final int? yearFrom;

  final int? yearTo;

  @override
  bool get isSearchActive => isSearchActiveFrom(search);

  @override
  bool get isFiltered =>
      isSearchActive ||
      yearFrom != null ||
      yearTo != null ||
      includeDeleted;

  AchievementQuery copyWith({
    Object? search = unset,
    Object? yearFrom = unset,
    Object? yearTo = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  }) {
    return AchievementQuery(
      search: search == unset ? this.search : search as String,
      yearFrom: yearFrom == unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      simulateError: simulateError ?? this.simulateError,
    );
  }

  @override
  Map<String, String> toQueryParameters() {
    return <String, String>{
      ...baseQueryParameters(
        sortField: sortField,
        sortAscending: sortAscending,
        page: page,
        size: size,
        includeDeleted: includeDeleted,
        simulateError: simulateError,
      ),
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (yearFrom != null) 'yearFrom': '$yearFrom',
      if (yearTo != null) 'yearTo': '$yearTo',
    };
  }

  factory AchievementQuery.fromQueryParameters(Map<String, String?> params) {
    final (sortField, sortAscending) = parseSort(params['sort']);
    return AchievementQuery(
      search: params['search'] ?? '',
      yearFrom: parseInt(params['yearFrom']),
      yearTo: parseInt(params['yearTo']),
      sortField: sortField,
      sortAscending: sortAscending,
      page: parseInt(params['page']) ?? 1,
      size: pickSize(params['size']),
      includeDeleted: params['includeDeleted'] == 'true',
      simulateError: params['error'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AchievementQuery &&
      other.search == search &&
      other.yearFrom == yearFrom &&
      other.yearTo == yearTo &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted &&
      other.simulateError == simulateError;

  @override
  int get hashCode => Object.hash(
        search,
        yearFrom,
        yearTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
        simulateError,
      );

  @override
  AchievementQuery withBase({
    Object? search = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  }) {
    return copyWith(
      search: search,
      sortField: sortField,
      sortAscending: sortAscending,
      page: page,
      size: size,
      includeDeleted: includeDeleted,
      simulateError: simulateError,
    );
  }

  @override
  AchievementQuery withPage(int page) => copyWith(page: page);
}
