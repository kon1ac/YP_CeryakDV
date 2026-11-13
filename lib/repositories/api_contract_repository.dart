import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/cancel_scope.dart';
import '../core/page_parser.dart';
import '../models/contract_entry.dart';
import '../models/contract_query.dart';
import '../models/page_result.dart';
import 'contract_repository.dart';

class ApiContractRepository implements ContractRepository {
  ApiContractRepository(this._dio);

  final Dio _dio;
  final CancelScope _findCancel = CancelScope();

  @override
  Future<PageResult<ContractEntry>> find(ContractQuery query) =>
      guard(() async {
        final token = _findCancel.next();
        final response = await _dio.get<dynamic>(
          '/contracts',
          queryParameters: {
            if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
            if (query.expiringSoon) 'expiringSoon': true,
            if (query.minSalary != null) 'minSalary': query.minSalary,
            if (query.maxSalary != null) 'maxSalary': query.maxSalary,
            'sort':
                '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
            'page': query.page,
            'size': query.size,
            if (query.includeDeleted) 'includeDeleted': true,
            if (query.simulateError) '__fail': 500,
          },
          cancelToken: token,
        );
        return parsePageResult(
          response.data,
          ContractEntry.fromJson,
          fallbackSize: query.size,
        );
      });

  @override
  Future<ContractEntry?> findById(int id) => guard(() async {
        try {
          final response = await _dio.get<dynamic>('/contracts/$id');
          return ContractEntry.fromJson(asJsonMap(response.data));
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<ContractEntry> update(ContractEntry entry) => guard(() async {
        final response = await _dio.put<dynamic>(
          '/contracts/${entry.id}',
          data: entry.toApiBody(),
        );
        return ContractEntry.fromJson(asJsonMap(response.data));
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete<dynamic>('/contracts/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete<dynamic>(
          '/contracts/$id',
          queryParameters: {'hard': true},
        ),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post<dynamic>('/contracts/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids, {bool physical = false}) =>
      guard(() async {
        final response = await _dio.post<dynamic>(
          '/contracts/bulk-delete',
          data: {'ids': ids, 'physical': physical},
        );
        return asJsonMap(response.data)['deleted'] as int? ?? 0;
      });
}
