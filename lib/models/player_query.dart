import 'list_query.dart';

class PlayerQuery extends ListQuery<PlayerQuery> {
  const PlayerQuery({
    super.search = '',
    this.category,
    this.teamId,
    this.achievementId,
    this.priceFrom,
    this.priceTo,
    super.sortField = 'name',
    super.sortAscending = true,
    super.page = 1,
    super.size,
    super.includeDeleted = false,
    super.simulateError = false,
  });

  static const PlayerQuery empty = PlayerQuery();

  static const List<String> categories = [
    'Нападающий',
    'Защитник',
    'Вратарь',
    'Тренер',
    'Спортивный директор',
  ];

  final String? category;

  final int? teamId;

  final int? achievementId;

  final double? priceFrom;

  final double? priceTo;

  @override
  bool get isSearchActive => isSearchActiveFrom(search);

  @override
  bool get isFiltered =>
      isSearchActive ||
      category != null ||
      teamId != null ||
      achievementId != null ||
      priceFrom != null ||
      priceTo != null ||
      includeDeleted;

  PlayerQuery copyWith({
    Object? search = unset,
    Object? category = unset,
    Object? teamId = unset,
    Object? achievementId = unset,
    Object? priceFrom = unset,
    Object? priceTo = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  }) {
    return PlayerQuery(
      search: search == unset ? this.search : search as String,
      category: category == unset ? this.category : category as String?,
      teamId: teamId == unset ? this.teamId : teamId as int?,
      achievementId:
          achievementId == unset ? this.achievementId : achievementId as int?,
      priceFrom: priceFrom == unset ? this.priceFrom : priceFrom as double?,
      priceTo: priceTo == unset ? this.priceTo : priceTo as double?,
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
      'category': ?category,
      if (teamId != null) 'teamId': '$teamId',
      if (achievementId != null) 'achievementId': '$achievementId',
      if (priceFrom != null) 'priceFrom': plainNumber(priceFrom!),
      if (priceTo != null) 'priceTo': plainNumber(priceTo!),
    };
  }

  factory PlayerQuery.fromQueryParameters(Map<String, String?> params) {
    final (sortField, sortAscending) = parseSort(params['sort']);
    return PlayerQuery(
      search: params['search'] ?? '',
      category: params['category'],
      teamId: parseInt(params['teamId']),
      achievementId: parseInt(params['achievementId']),
      priceFrom: parseDouble(params['priceFrom']),
      priceTo: parseDouble(params['priceTo']),
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
      other is PlayerQuery &&
      other.search == search &&
      other.category == category &&
      other.teamId == teamId &&
      other.achievementId == achievementId &&
      other.priceFrom == priceFrom &&
      other.priceTo == priceTo &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted &&
      other.simulateError == simulateError;

  @override
  int get hashCode => Object.hash(
        search,
        category,
        teamId,
        achievementId,
        priceFrom,
        priceTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
        simulateError,
      );

  @override
  PlayerQuery withBase({
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
  PlayerQuery withPage(int page) => copyWith(page: page);
}
