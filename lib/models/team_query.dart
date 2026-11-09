import 'list_query.dart';

class TeamQuery extends ListQuery {
  const TeamQuery({
    super.search = '',
    this.city,
    this.playersFrom,
    this.playersTo,
    super.sortField = 'name',
    super.sortAscending = true,
    super.page = 1,
    super.size,
    super.includeDeleted = false,
    super.simulateError = false,
  });

  static const TeamQuery empty = TeamQuery();

  final String? city;

  final int? playersFrom;

  final int? playersTo;

  @override
  bool get isSearchActive => isSearchActiveFrom(search);

  @override
  bool get isFiltered =>
      isSearchActive ||
      city != null ||
      playersFrom != null ||
      playersTo != null ||
      includeDeleted;

  TeamQuery copyWith({
    Object? search = unset,
    Object? city = unset,
    Object? playersFrom = unset,
    Object? playersTo = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  }) {
    return TeamQuery(
      search: search == unset ? this.search : search as String,
      city: city == unset ? this.city : city as String?,
      playersFrom:
          playersFrom == unset ? this.playersFrom : playersFrom as int?,
      playersTo: playersTo == unset ? this.playersTo : playersTo as int?,
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
      if (playersFrom != null) 'playersFrom': '$playersFrom',
      if (playersTo != null) 'playersTo': '$playersTo',
    };
  }

  factory TeamQuery.fromQueryParameters(Map<String, String?> params) {
    final (sortField, sortAscending) = parseSort(params['sort']);
    return TeamQuery(
      search: params['search'] ?? '',
      city: params['city'],
      playersFrom: parseInt(params['playersFrom']),
      playersTo: parseInt(params['playersTo']),
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
      other is TeamQuery &&
      other.search == search &&
      other.city == city &&
      other.playersFrom == playersFrom &&
      other.playersTo == playersTo &&
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
        playersFrom,
        playersTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
        simulateError,
      );
}
