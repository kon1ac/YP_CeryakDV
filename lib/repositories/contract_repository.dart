import '../models/contract_entry.dart';
import '../models/contract_query.dart';
import '../models/page_result.dart';

abstract interface class ContractRepository {
  Future<PageResult<ContractEntry>> find(ContractQuery query);

  Future<ContractEntry?> findById(String id);

  Future<ContractEntry> update(ContractEntry entry);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids, {bool physical = false});
}
