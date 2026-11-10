import 'list_query.dart';

class ContractQuery extends ListQuery<ContractQuery> {
  const ContractQuery({
    super.search = '',
    this.expiringSoon = false,
    this.minSalary,
    this.maxSalary,
    super.sortField = 'email',
    super.sortAscending = true,
    super.page = 1,
    super.size,
    super.includeDeleted = false,
    super.simulateError = false,
  });

  static const ContractQuery empty = ContractQuery();

  final bool expiringSoon;

  final double? minSalary;

  final double? maxSalary;

  @override
  bool get isSearchActive => isSearchActiveFrom(search);

  @override
  bool get isFiltered =>
      isSearchActive ||
      expiringSoon ||
      minSalary != null ||
      maxSalary != null ||
      includeDeleted;

  ContractQuery copyWith({
    Object? search = unset,
    bool? expiringSoon,
    Object? minSalary = unset,
    Object? maxSalary = unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    bool? simulateError,
  }) {
    return ContractQuery(
      search: search == unset ? this.search : search as String,
      expiringSoon: expiringSoon ?? this.expiringSoon,
      minSalary: minSalary == unset ? this.minSalary : minSalary as double?,
      maxSalary: maxSalary == unset ? this.maxSalary : maxSalary as double?,
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
        defaultSortField: 'email',
      ),
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (expiringSoon) 'expiring': 'true',
      if (minSalary != null) 'minSalary': plainNumber(minSalary!),
      if (maxSalary != null) 'maxSalary': plainNumber(maxSalary!),
    };
  }

  factory ContractQuery.fromQueryParameters(Map<String, String?> params) {
    final (sortField, sortAscending) =
        parseSort(params['sort'], fallback: 'email');
    return ContractQuery(
      search: params['search'] ?? '',
      expiringSoon: params['expiring'] == 'true',
      minSalary: parseDouble(params['minSalary']),
      maxSalary: parseDouble(params['maxSalary']),
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
      other is ContractQuery &&
      other.search == search &&
      other.expiringSoon == expiringSoon &&
      other.minSalary == minSalary &&
      other.maxSalary == maxSalary &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted &&
      other.simulateError == simulateError;

  @override
  int get hashCode => Object.hash(
        search,
        expiringSoon,
        minSalary,
        maxSalary,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
        simulateError,
      );

  @override
  ContractQuery withBase({
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
  ContractQuery withPage(int page) => copyWith(page: page);
}
