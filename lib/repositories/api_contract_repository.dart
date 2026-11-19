import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/page_parser.dart';
import '../core/pb_client.dart';
import '../models/contract_entry.dart';
import '../models/contract_query.dart';
import '../models/page_result.dart';
import 'contract_repository.dart';

class ApiContractRepository implements ContractRepository {
  ApiContractRepository(Dio dio) : _pb = PbClient(dio);

  final PbClient _pb;
  final CancelScope _findCancel = CancelScope();

  String _sort(ContractQuery query) {
    final prefix = query.sortAscending ? '' : '-';
    final field = switch (query.sortField) {
      'number' => 'number',
      'salary' => 'salary',
      'signedAt' => 'signedAt',
      'expiresAt' => 'expiresAt',
      'id' => 'id',
      _ => 'email',
    };
    return '$prefix$field';
  }

  String _filter(ContractQuery query) {
    return joinFilters([
      pbActiveFilter(includeDeleted: query.includeDeleted),
      if (query.search.trim().isNotEmpty)
        'email ~ ${pbQuote(query.search.trim())} || '
            'number ~ ${pbQuote(query.search.trim())}',
      if (query.minSalary != null) 'salary >= ${query.minSalary}',
      if (query.maxSalary != null) 'salary <= ${query.maxSalary}',
      if (query.expiringSoon)
        'expiresAt != "" && expiresAt <= ${pbQuote(DateTime.now().add(const Duration(days: 180)).toIso8601String().split('T').first)}',
    ]);
  }

  @override
  Future<PageResult<ContractEntry>> find(ContractQuery query) =>
      guard(() async {
        _findCancel.next();
        if (query.simulateError) {
          throw const ServerException('Учебная ошибка 500');
        }
        final data = await _pb.list(
          'contracts',
          page: query.page,
          perPage: query.size,
          filter: _filter(query),
          sort: _sort(query),
          expand: 'player',
        );
        return parsePageResult(
          data,
          ContractEntry.fromJson,
          fallbackSize: query.size,
        );
      });

  @override
  Future<ContractEntry?> findById(String id) => guard(() async {
        try {
          final data = await _pb.getOne('contracts', id, expand: 'player');
          return ContractEntry.fromJson(data);
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<ContractEntry> update(ContractEntry entry) => guard(() async {
        final data = await _pb.update(
          'contracts',
          entry.id,
          entry.toApiBody(),
          expand: 'player',
        );
        return ContractEntry.fromJson(data);
      });

  @override
  Future<void> softDelete(String id) => guard(() async {
        await _pb.update('contracts', id, {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        });
      });

  @override
  Future<void> hardDelete(String id) =>
      guard(() => _pb.delete('contracts', id));

  @override
  Future<void> restore(String id) =>
      guard(() => _pb.update('contracts', id, {'deletedAt': null}));

  @override
  Future<int> deleteMany(List<String> ids, {bool physical = false}) =>
      guard(() async {
        var count = 0;
        for (final id in ids) {
          if (physical) {
            await hardDelete(id);
          } else {
            await softDelete(id);
          }
          count++;
        }
        return count;
      });
}
