import '../models/contract_entry.dart';
import '../models/contract_query.dart';
import '../models/page_result.dart';
import '../repositories/contract_repository.dart';
import 'entity_list_notifier.dart';

class ContractListNotifier
    extends EntityListNotifier<ContractEntry, ContractQuery> {
  ContractListNotifier(this._repository, {ContractQuery? initialQuery})
      : super(initialQuery ?? ContractQuery.empty);

  final ContractRepository _repository;

  @override
  Future<PageResult<ContractEntry>> fetch(ContractQuery query) =>
      _repository.find(query);

  @override
  Future<void> mutateOne(int id, MutationMode mode) => switch (mode) {
    MutationMode.softDelete => _repository.softDelete(id),
    MutationMode.hardDelete => _repository.hardDelete(id),
    MutationMode.restore => _repository.restore(id),
  };

  @override
  Future<int> mutateMany(List<int> ids, MutationMode mode) =>
      _repository.deleteMany(ids,
          physical: mode == MutationMode.hardDelete);

  @override
  ContractQuery withoutFilters(ContractQuery query) => query.copyWith(
        search: '',
        expiringSoon: false,
        minSalary: null,
        maxSalary: null,
        includeDeleted: false,
      );
}
