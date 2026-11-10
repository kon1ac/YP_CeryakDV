import 'list_query.dart';

class ArenaQuery extends ListQuery<ArenaQuery> {
  const ArenaQuery({
    super.search = '',
    this.city,
    this.capacityFrom,
    this.capacityTo,
    super.sortField = 'name',
    super.sortAscending = true,
    super.page = 1,
    super.size,
    super.includeDeleted = false,
    super.simulateError = false,
  });

  static const ArenaQuery empty = ArenaQuery();

  final String? city;

  final int? capacityFrom;

  final int? capacityTo;

  @override
  bool get isSearchActive => isSearchActiveFrom(search);

  @override
  bool get isFiltered =>
      isSearchActive ||
      city != null ||
      capacityFrom != null ||
      capacityTo != null ||
      includeDeleted;

  ArenaQuery copyWith({
    Object? search = unset,
    Object? city = unset,
    Object? capacityFrom = unset,
    Object? capacityTo = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  }) {
    return ArenaQuery(
      search: search == unset ? this.search : search as String,
      city: city == unset ? this.city : city as String?,
      capacityFrom: capacityFrom == unset
          ? this.capacityFrom
          : capacityFrom as int?,
      capacityTo:
          capacityTo == unset ? this.capacityTo : capacityTo as int?,
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
      'city': ?city,
      if (capacityFrom != null) 'capacityFrom': '$capacityFrom',
      if (capacityTo != null) 'capacityTo': '$capacityTo',
    };
  }

  factory ArenaQuery.fromQueryParameters(Map<String, String?> params) {
    final (sortField, sortAscending) = parseSort(params['sort']);
    return ArenaQuery(
      search: params['search'] ?? '',
      city: params['city'],
      capacityFrom: parseInt(params['capacityFrom']),
      capacityTo: parseInt(params['capacityTo']),
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
      other is ArenaQuery &&
      other.search == search &&
      other.city == city &&
      other.capacityFrom == capacityFrom &&
      other.capacityTo == capacityTo &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted &&
      other.simulateError == simulateError;

  @override
  int get hashCode => Object.hash(
        search,
        city,
        capacityFrom,
        capacityTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
        simulateError,
      );

  @override
  ArenaQuery withBase({
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
  ArenaQuery withPage(int page) => copyWith(page: page);
}
