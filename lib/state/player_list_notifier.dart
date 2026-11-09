import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hockey_player.dart';
import '../models/page_result.dart';
import '../models/player_query.dart';
import '../repositories/hockey_player_repository.dart';
import 'load_status.dart';

class PlayerListNotifier extends ChangeNotifier {
  PlayerListNotifier(this._repository, {PlayerQuery? initialQuery})
      : _query = initialQuery ?? PlayerQuery.empty;

  static const Duration searchDebounce = Duration(milliseconds: 300);

  final HockeyPlayerRepository _repository;

  PlayerQuery _query;
  PageResult<HockeyPlayer> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<String> _teamOptions = const [];
  Timer? _debounceTimer;

  String? _pendingSearch;

  void Function(PlayerQuery query)? onQueryChanged;

  PlayerQuery get query => _query;

  String get searchText => _pendingSearch ?? _query.search;

  PageResult<HockeyPlayer> get result => _result;

  LoadStatus get status => _status;

  String? get error => _error;

  List<String> get teamOptions => _teamOptions;

  Set<int> get selected => Set.unmodifiable(_selectedIds);

  final Set<int> _selectedIds = {};

  bool get hasSelection => _selectedIds.isNotEmpty;

  bool get isBusy => _status == LoadStatus.loading;

  bool get hasPendingSearch => _debounceTimer?.isActive ?? false;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> init() async {
    _teamOptions = await _repository.teamNames();
    notifyListeners();
    await load();
  }

  Future<void> applyQuery(PlayerQuery next) async {
    if (next == _query) return;
    _query = next;
    _selectedIds.clear();
    onQueryChanged?.call(next);
    await load();
  }

  void adoptQuery(PlayerQuery next) {
    _query = next;
    _selectedIds.clear();
  }

  Future<void> syncFromQuery(PlayerQuery next) async {
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
      applyQuery(_query.copyWith(search: text));
    });
  }

  Future<void> resetFilters() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingSearch = null;
    await applyQuery(
      PlayerQuery(size: _query.size, sortField: _query.sortField),
    );
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
    final ids = _result.items.map((p) => p.id);
    final allSelected = ids.every(_selectedIds.contains);
    if (allSelected) {
      _selectedIds.removeAll(ids);
    } else {
      _selectedIds.addAll(ids);
    }
    notifyListeners();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selectedIds.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selectedIds.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    _selectedIds.remove(id);
    await load();
  }

  Future<int> deleteSelected({bool physical = false}) async {
    final ids = _selectedIds.toList();
    _selectedIds.clear();
    notifyListeners();
    final count = await _repository.deleteMany(ids, physical: physical);
    await load();
    return count;
  }

  Future<void> toggleShowDeleted() async {
    await applyQuery(_query.copyWith(includeDeleted: !_query.includeDeleted));
  }

  Future<void> changePageSize(int size) async {
    await applyQuery(_query.copyWith(size: size));
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _result.totalPages || page == _query.page) return;
    _query = _query.copyWith(page: page);
    onQueryChanged?.call(_query);
    await load();
  }

  Future<void> toggleSort(String field) async {
    final ascending =
        _query.sortField == field ? !_query.sortAscending : true;
    await applyQuery(
      _query.copyWith(sortField: field, sortAscending: ascending),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    onQueryChanged = null;
    super.dispose();
  }
}
