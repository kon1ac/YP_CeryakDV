import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/contract_entry.dart';
import '../models/contract_query.dart';
import '../state/contract_list_notifier.dart';
import '../state/load_status.dart';
import '../utils/format.dart';
import '../widgets/entity_card.dart';
import '../widgets/entity_paginator.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_nav_bar.dart';
import '../widgets/list_states.dart';
import '../widgets/search_field.dart';
import '../widgets/selection_bar.dart';
import 'checked_menu_item.dart';
import 'players_list_screen.dart' show tableBreakpoint;

class ContractsListScreen extends StatefulWidget {
  const ContractsListScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<ContractsListScreen> createState() => _ContractsListScreenState();
}

class _ContractsListScreenState extends State<ContractsListScreen> {
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();

  bool _filtersOpen = true;

  bool _filtersInitialized = false;

  ContractListNotifier? _model;

  @override
  void initState() {
    super.initState();

    final incoming = ContractQuery.fromQueryParameters(
      widget.uri.queryParameters,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<ContractListNotifier>();
      _model = model;
      model.onQueryChanged = _publish;
      model.adoptQuery(incoming);
      _syncSalaryFields(incoming);
      model.init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filtersInitialized) return;
    _filtersInitialized = true;
    _filtersOpen = MediaQuery.sizeOf(context).width >= tableBreakpoint;
  }

  @override
  void didUpdateWidget(ContractsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri == widget.uri) return;

    final incoming = ContractQuery.fromQueryParameters(
      widget.uri.queryParameters,
    );
    _syncSalaryFields(incoming);
    context.read<ContractListNotifier>().syncFromQuery(incoming);
  }

  @override
  void dispose() {
    final model = _model;
    if (model != null && model.onQueryChanged == _publish) {
      model.onQueryChanged = null;
    }
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  void _publish(ContractQuery query) {
    if (!mounted) return;
    final location = Uri(
      path: widget.uri.path,
      queryParameters: query.toQueryParameters(),
    ).toString();
    context.go(location);
  }

  void _syncSalaryFields(ContractQuery query) {
    _setField(_minSalaryController, query.minSalary);
    _setField(_maxSalaryController, query.maxSalary);
  }

  static void _setField(TextEditingController controller, double? value) {
    final text = value == null ? '' : Format.plain(value);
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _applySalaryRange(String _) async {
    final model = context.read<ContractListNotifier>();
    await model.applyQuery(
      model.query.copyWith(
        minSalary: Format.parseAmount(_minSalaryController.text),
        maxSalary: Format.parseAmount(_maxSalaryController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ContractListNotifier>();
    final query = model.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Контракты'),
        actions: [
          IconButton(
            tooltip: _filtersOpen ? 'Скрыть фильтры' : 'Показать фильтры',
            onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
            icon: Icon(
              _filtersOpen ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ещё',
            onSelected: (value) => switch (value) {
              'deleted' => model.toggleShowDeleted(),
              'reset' => model.resetFilters(),
              'error' => model.applyQuery(
                  query.copyWith(simulateError: !query.simulateError)),
              _ => null,
            },
            itemBuilder: (context) => [
              CheckedMenuItem(
                value: 'deleted',
                checked: query.includeDeleted,
                text: 'Показывать закрытые',
              ),
              CheckedMenuItem(
                value: 'error',
                checked: query.simulateError,
                text: 'Имитировать сбой загрузки',
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'reset',
                child: Text('Сбросить фильтры'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kListNavBarHeight),
          child: const ListNavBar(active: ListDestination.contracts),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    initialValue: model.searchText,
                    hintText: 'Поиск по почте, игроку или номеру',
                    onChanged: model.searchChanged,
                  ),
                ),
                if (model.hasPendingSearch)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          if (_filtersOpen) _filters(model),
          if (model.hasSelection)
            SelectionBar(
              count: model.selected.length,
              deletedMode: query.includeDeleted,
              onClear: model.clearSelection,
              onDelete: () => _confirmMassDelete(model),
            ),
          Expanded(child: _body(model)),
          EntityPaginator<ContractEntry>(
            page: model.result,
            enabled: model.status == LoadStatus.success,
            onPageSizeChanged: model.changePageSize,
            onPageSelected: model.goToPage,
          ),
        ],
      ),
    );
  }

  Widget _filters(ContractListNotifier model) {
    final theme = Theme.of(context);
    final query = model.query;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<bool>(
              initialValue: query.expiringSoon,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Срок'),
              items: const [
                DropdownMenuItem<bool>(
                  value: false,
                  child: Text('Любой'),
                ),
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text('Истекает в ближайшие 180 дней'),
                ),
              ],
              onChanged: (value) => model.applyQuery(
                query.copyWith(expiringSoon: value ?? false),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _minSalaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Зарплата от',
                isDense: true,
              ),
              onSubmitted: _applySalaryRange,
              onEditingComplete: () => _applySalaryRange(''),
            ),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _maxSalaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Зарплата до',
                isDense: true,
              ),
              onSubmitted: _applySalaryRange,
              onEditingComplete: () => _applySalaryRange(''),
            ),
          ),
          if (query.isFiltered)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextButton.icon(
                onPressed: model.resetFilters,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Сбросить'),
              ),
            ),
          if (query.includeDeleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Показаны закрытые контракты',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(ContractListNotifier model) {
    return switch (model.status) {
      LoadStatus.idle || LoadStatus.loading =>
        const ListLoadingState(message: 'Ищем контракты…'),
      LoadStatus.error => ListErrorState(
          message: model.error ?? 'Неизвестная ошибка',
          onRetry: model.load,
        ),
      LoadStatus.success => model.result.items.isEmpty
          ? ListEmptyState(
              onReset: model.query.isFiltered ? model.resetFilters : null,
            )
          : LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth >= tableBreakpoint
                      ? _table(model)
                      : _cards(model),
            ),
    };
  }

  Widget _table(ContractListNotifier model) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EntityTable<ContractEntry>(
        columns: [
          TableColumnSpec(
            label: '№',
            sortField: 'id',
            numeric: true,
            width: 56,
            build: (c) => Text('${c.id}'),
          ),
          TableColumnSpec(
            label: 'Игрок',
            sortField: 'player',
            build: (c) => Text(c.playerName),
          ),
          TableColumnSpec(
            label: 'Номер',
            sortField: 'number',
            numeric: true,
            width: 84,
            build: (c) => Text('${c.number}'),
          ),
          TableColumnSpec(
            label: 'Почта',
            sortField: 'email',
            build: (c) => Text(c.email),
          ),
          TableColumnSpec(
            label: 'Зарплата',
            sortField: 'salary',
            numeric: true,
            build: (c) => Text(Format.price(c.salary)),
          ),
          TableColumnSpec(
            label: 'Подписан',
            sortField: 'signedAt',
            build: (c) => Text(Format.date(c.signedAt)),
          ),
          TableColumnSpec(
            label: 'Действует до',
            sortField: 'expiresAt',
            build: (c) => Text(
              c.expiresAt == null ? 'бессрочно' : Format.date(c.expiresAt!),
            ),
          ),
          TableColumnSpec(
            label: 'Закрыт',
            build: (c) =>
                Text(c.deletedAt == null ? '—' : Format.date(c.deletedAt!)),
          ),
        ],
        items: model.result.items,
        idOf: (c) => c.id,
        selected: model.selected,
        sortField: model.query.sortField,
        sortAscending: model.query.sortAscending,
        onSort: model.toggleSort,
        onToggleSelect: model.toggleSelection,
        onToggleSelectAll: model.toggleSelectPage,
        actions: _rowActions,
      ),
    );
  }

  Widget _cards(ContractListNotifier model) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: model.result.items.length,
      itemBuilder: (context, index) {
        final entry = model.result.items[index];
        return EntityCard<ContractEntry>(
          item: entry,
          selected: model.selected.contains(entry.id),
          onSelectChanged: (value) => model.toggleSelection(entry.id),
          title: Text(entry.playerName),
          subtitle: Text(entry.email),
          fields: [
            ('Номер', Text('${entry.number}')),
            ('Зарплата', Text(Format.price(entry.salary))),
            ('Подписан', Text(Format.date(entry.signedAt))),
            (
              'Действует до',
              Text(entry.expiresAt == null
                  ? 'бессрочно'
                  : Format.date(entry.expiresAt!)),
            ),
            if (entry.deletedAt != null)
              ('Закрыт', Text(Format.date(entry.deletedAt!))),
          ],
          actions: _rowActions(entry),
        );
      },
    );
  }

  List<Widget> _rowActions(ContractEntry entry) {
    final model = context.read<ContractListNotifier>();

    if (entry.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () => model.restore(entry.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить из базы',
          onPressed: () => _confirmDelete(entry, physical: true),
          icon: const Icon(Icons.delete_forever, size: 20),
        ),
      ];
    }

    return [
      IconButton(
        tooltip: 'Игрок',
        onPressed: () => context.go('/players/${entry.playerId}'),
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
      IconButton(
        tooltip: 'Закрыть контракт',
        onPressed: () => _confirmDelete(entry, physical: false),
        icon: const Icon(Icons.lock_outline),
      ),
      IconButton(
        tooltip: 'Удалить из базы',
        onPressed: () => _confirmDelete(entry, physical: true),
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
    ];
  }

  Future<void> _confirmDelete(
    ContractEntry entry, {
    required bool physical,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(physical ? 'Удалить контракт?' : 'Закрыть контракт?'),
        content: Text(physical
            ? 'Контракт игрока «${entry.playerName}» будет стёрт безвозвратно.'
            : 'Контракт игрока «${entry.playerName}» будет закрыт '
                'и исчезнет из общего списка, но останется в базе.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: physical
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(physical ? 'Удалить' : 'Закрыть'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final model = context.read<ContractListNotifier>();
    await (physical ? model.hardDelete(entry.id) : model.softDelete(entry.id));
    _toast(physical ? 'Контракт удалён' : 'Контракт закрыт');
  }

  Future<void> _confirmMassDelete(ContractListNotifier model) async {
    final count = model.selected.length;
    final physical = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Обработать $count'),
        content: Text(
          'Выбрано контрактов: $count. Логическое удаление закрывает их, '
          'физическое — стирает из базы безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Закрыть'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить насовсем'),
          ),
        ],
      ),
    );
    if (physical == null || !mounted) return;

    final deleted = await model.deleteSelected(physical: physical);
    _toast(physical
        ? 'Удалено записей: $deleted'
        : 'Закрыто контрактов: $deleted');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
