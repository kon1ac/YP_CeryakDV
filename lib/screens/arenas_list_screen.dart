import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/arena.dart';
import '../models/arena_query.dart';
import '../state/arena_list_notifier.dart';
import '../repositories/arena_repository.dart';
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

class ArenasListScreen extends StatefulWidget {
  const ArenasListScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<ArenasListScreen> createState() => _ArenasListScreenState();
}

class _ArenasListScreenState extends State<ArenasListScreen> {
  final _capacityFromController = TextEditingController();
  final _capacityToController = TextEditingController();

  bool _filtersOpen = true;

  bool _filtersInitialized = false;

  ArenaListNotifier? _model;

  @override
  void initState() {
    super.initState();

    final incoming = ArenaQuery.fromQueryParameters(widget.uri.queryParameters);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<ArenaListNotifier>();
      _model = model;
      model.onQueryChanged = _publish;
      model.adoptQuery(incoming);
      _syncRangeFields(incoming);
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
  void didUpdateWidget(ArenasListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri == widget.uri) return;

    final incoming = ArenaQuery.fromQueryParameters(widget.uri.queryParameters);
    _syncRangeFields(incoming);
    context.read<ArenaListNotifier>().syncFromQuery(incoming);
  }

  @override
  void dispose() {
    final model = _model;
    if (model != null && model.onQueryChanged == _publish) {
      model.onQueryChanged = null;
    }
    _capacityFromController.dispose();
    _capacityToController.dispose();
    super.dispose();
  }

  void _publish(ArenaQuery query) {
    if (!mounted) return;
    final location = Uri(
      path: widget.uri.path,
      queryParameters: query.toQueryParameters(),
    ).toString();
    context.go(location);
  }

  void _syncRangeFields(ArenaQuery query) {
    _setField(_capacityFromController, query.capacityFrom);
    _setField(_capacityToController, query.capacityTo);
  }

  static void _setField(TextEditingController controller, int? value) {
    final text = value == null ? '' : '$value';
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _applyCapacityRange(String _) async {
    final model = context.read<ArenaListNotifier>();
    await model.applyQuery(
      model.query.copyWith(
        capacityFrom: Format.parseCount(_capacityFromController.text),
        capacityTo: Format.parseCount(_capacityToController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ArenaListNotifier>();
    final query = model.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Арены'),
        actions: [
          IconButton(
            tooltip: 'Добавить',
            onPressed: () => context.go('/arenas/new'),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: _filtersOpen ? 'Скрыть фильтры' : 'Показать фильтры',
            onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
            icon: Icon(
                _filtersOpen ? Icons.filter_alt : Icons.filter_alt_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ещё',
            onSelected: (value) => switch (value) {
              'deleted' => model.toggleShowDeleted(),
              'reset' => model.resetFilters(),
              'error' => model.applyQuery(
                  model.query.copyWith(simulateError: !query.simulateError)),
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
          child: const ListNavBar(active: ListDestination.arenas),
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
                    hintText: 'Поиск по названию или городу',
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
          EntityPaginator<Arena>(
            page: model.result,
            enabled: model.status == LoadStatus.success,
            onPageSizeChanged: model.changePageSize,
            onPageSelected: model.goToPage,
          ),
        ],
      ),
    );
  }

  Widget _filters(ArenaListNotifier model) {
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
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: query.city,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Город'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Любой'),
                ),
                for (final city in model.cityOptions)
                  DropdownMenuItem<String>(value: city, child: Text(city)),
              ],
              onChanged: (value) => model.applyQuery(
                query.copyWith(city: value),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _capacityFromController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Мест от',
                isDense: true,
              ),
              onSubmitted: _applyCapacityRange,
              onEditingComplete: () => _applyCapacityRange(''),
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _capacityToController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Мест до',
                isDense: true,
              ),
              onSubmitted: _applyCapacityRange,
              onEditingComplete: () => _applyCapacityRange(''),
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
                'Показаны закрытые арены',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(ArenaListNotifier model) {
    return switch (model.status) {
      LoadStatus.idle || LoadStatus.loading =>
        const ListLoadingState(message: 'Ищем арены…'),
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

  Widget _table(ArenaListNotifier model) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EntityTable<Arena>(
        columns: [
          TableColumnSpec(
            label: '№',
            sortField: 'id',
            numeric: true,
            width: 56,
            build: (a) => Text('${a.id}'),
          ),
          TableColumnSpec(
            label: 'Арена',
            sortField: 'name',
            build: (a) => _openLink('/arenas/${a.id}', a.name),
          ),
          TableColumnSpec(
            label: 'Город',
            sortField: 'city',
            build: (a) => Text(a.city),
          ),
          TableColumnSpec(
            label: 'Вместимость',
            sortField: 'capacity',
            numeric: true,
            build: (a) => Text(Format.plain(a.capacity.toDouble())),
          ),
          TableColumnSpec(
            label: 'Команд',
            sortField: 'teams',
            numeric: true,
            build: (a) => Text('${a.teamCount}'),
          ),
          TableColumnSpec(
            label: 'Закрыта',
            build: (a) =>
                Text(a.deletedAt == null ? '—' : Format.date(a.deletedAt!)),
          ),
        ],
        items: model.result.items,
        idOf: (a) => a.id,
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

  Widget _cards(ArenaListNotifier model) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: model.result.items.length,
      itemBuilder: (context, index) {
        final arena = model.result.items[index];
        return EntityCard<Arena>(
          item: arena,
          selected: model.selected.contains(arena.id),
          onSelectChanged: (value) => model.toggleSelection(arena.id),
          title: _openLink('/arenas/${arena.id}', arena.name),
          subtitle: Text(arena.city),
          fields: [
            ('Вместимость', Text('${arena.capacity}')),
            ('Команд', Text('${arena.teamCount}')),
            if (arena.deletedAt != null)
              ('Закрыта', Text(Format.date(arena.deletedAt!))),
          ],
          actions: _rowActions(arena),
        );
      },
    );
  }

  Widget _openLink(String location, String text) {
    return InkWell(
      onTap: () => context.go(location),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  List<Widget> _rowActions(Arena arena) {
    final model = context.read<ArenaListNotifier>();

    if (arena.isDeleted) {
      return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/arenas/${arena.id}/edit'),
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
        IconButton(
          tooltip: 'Открыть заново',
          onPressed: () => model.restore(arena.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить из базы',
          onPressed: () => _confirmDelete(arena, physical: true),
          icon: const Icon(Icons.delete_forever, size: 20),
        ),
      ];
    }

    return [
      IconButton(
        tooltip: 'Закрыть арену',
        onPressed: () => _confirmDelete(arena, physical: false),
        icon: const Icon(Icons.lock_outline),
      ),
      IconButton(
        tooltip: 'Удалить из базы',
        onPressed: () => _confirmDelete(arena, physical: true),
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
    ];
  }

  Future<void> _confirmDelete(Arena arena, {required bool physical}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(physical ? 'Удалить арену?' : 'Закрыть арену?'),
        content: Text(physical
            ? 'Арена «${arena.name}» будет удалена безвозвратно.'
            : 'Арена «${arena.name}» будет помечена закрытой '
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
    if (confirmed == null || !confirmed || !mounted) return;

    final model = context.read<ArenaListNotifier>();
    try {
      await (physical
          ? model.hardDelete(arena.id)
          : model.softDelete(arena.id));
    } on RelatedRecordsException catch (e) {
      await _explainRelations(e, arena.name);
      return;
    }
    _toast(physical
        ? 'Арена «${arena.name}» удалена'
        : 'Арена «${arena.name}» закрыта');
  }

  Future<void> _explainRelations(
    RelatedRecordsException error,
    String name,
  ) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить нельзя'),
        content: Text(
          'Арена «$name» используется: связанных записей — ${error.count}. '
          'Сначала перенесите команды на другую арену или удалите их.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMassDelete(ArenaListNotifier model) async {
    final count = model.selected.length;
    final physical = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Обработать $count'),
        content: Text(
          'Выбрано арен: $count. Логическое удаление помечает их закрытыми, '
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

    final int deleted;
    try {
      deleted = await model.deleteSelected(physical: physical);
    } on RelatedRecordsException catch (e) {
      await _explainRelations(e, 'выбранные арены');
      return;
    }
    if (!physical) {
      _toast('Закрыто арен: $deleted');
      return;
    }
    final skipped = count - deleted;
    _toast(skipped > 0
        ? 'Удалено: $deleted, пропущено из-за связей: $skipped'
        : 'Удалено записей: $deleted');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
