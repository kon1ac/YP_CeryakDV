import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'load_status.dart';

enum MutationMode { softDelete, hardDelete, restore }

abstract class EntityListNotifier<T extends Identifiable, Q extends ListQuery<Q>>
    extends ChangeNotifier {
  EntityListNotifier(Q initialQuery) : _query = initialQuery;

  static const Duration searchDebounce = Duration(milliseconds: 300);

  Q _query;
  PageResult<T> _result = PageResult<T>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Timer? _debounceTimer;
  String? _pendingSearch;
  final Set<int> _selectedIds = {};

  void Function(Q query)? onQueryChanged;

  Q get query => _query;

  String get searchText => _pendingSearch ?? _query.search;

  PageResult<T> get result => _result;

  LoadStatus get status => _status;

  String? get error => _error;

  Set<int> get selected => Set.unmodifiable(_selectedIds);

  bool get hasSelection => _selectedIds.isNotEmpty;

  bool get hasPendingSearch => _debounceTimer?.isActive ?? false;

  Future<PageResult<T>> fetch(Q query);

  Future<void> mutateOne(int id, MutationMode mode);

  Future<int> mutateMany(List<int> ids, MutationMode mode);

  Q withoutFilters(Q query);

  Future<void> init() => load();

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await fetch(_query);
      _status = LoadStatus.success;
    } on RequestCancelledException {
      // Устаревший поиск отменён — ждём актуальный ответ.
      return;
    } catch (e) {
      _error = '$e';
      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> applyQuery(Q next) async {
    if (next == _query) return;
    _query = next;
    _selectedIds.clear();
    onQueryChanged?.call(next);
    await load();
  }

  void adoptQuery(Q next) {
    _query = next;
    _selectedIds.clear();
  }

  Future<void> syncFromQuery(Q next) async {
    if (next == _query) return;
    _debounceTimer?.cancel();
    _pendingSearch = null;
    _query = next;
    _selectedIds.clear();
    await load();
  }

  void searchChanged(String text) {
    _pendingSearch = text;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(searchDebounce, () {
      _debounceTimer = null;
      _pendingSearch = null;
      applyQuery(_query.withBase(search: text));
    });
  }

  Future<void> resetFilters() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingSearch = null;
    await applyQuery(withoutFilters(_query));
  }

  void toggleSelection(int id) {
    if (!_selectedIds.add(id)) _selectedIds.remove(id);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelectPage() {
    final ids = _result.items.map((item) => item.id);
    final allSelected = ids.every(_selectedIds.contains);
    if (allSelected) {
      _selectedIds.removeAll(ids);
    } else {
      _selectedIds.addAll(ids);
    }
    notifyListeners();
  }

  Future<void> softDelete(int id) => _mutate(id, MutationMode.softDelete);

  Future<void> hardDelete(int id) => _mutate(id, MutationMode.hardDelete);

  Future<void> restore(int id) => _mutate(id, MutationMode.restore);

  Future<void> _mutate(int id, MutationMode mode) async {
    await mutateOne(id, mode);
    _selectedIds.remove(id);
    await load();
  }

  Future<int> deleteSelected({bool physical = false}) async {
    final ids = _selectedIds.toList();
    _selectedIds.clear();
    notifyListeners();
    final count = await mutateMany(
      ids,
      physical ? MutationMode.hardDelete : MutationMode.softDelete,
    );
    await load();
    return count;
  }

  Future<void> toggleShowDeleted() async {
    await applyQuery(
      _query.withBase(includeDeleted: !_query.includeDeleted),
    );
  }

  Future<void> changePageSize(int size) async {
    await applyQuery(_query.withBase(size: size));
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _result.totalPages || page == _query.page) return;
    _query = _query.withPage(page);
    onQueryChanged?.call(_query);
    await load();
  }

  Future<void> toggleSort(String field) async {
    final ascending = _query.sortField == field ? !_query.sortAscending : true;
    await applyQuery(
      _query.withBase(sortField: field, sortAscending: ascending),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    onQueryChanged = null;
    super.dispose();
  }
}
