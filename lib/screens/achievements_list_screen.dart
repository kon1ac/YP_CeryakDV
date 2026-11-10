import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../models/achievement_query.dart';
import '../state/achievement_list_notifier.dart';
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

class AchievementsListScreen extends StatefulWidget {
  const AchievementsListScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<AchievementsListScreen> createState() =>
      _AchievementsListScreenState();
}

class _AchievementsListScreenState extends State<AchievementsListScreen> {
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();

  bool _filtersOpen = true;

  bool _filtersInitialized = false;

  AchievementListNotifier? _model;

  @override
  void initState() {
    super.initState();

    final incoming =
        AchievementQuery.fromQueryParameters(widget.uri.queryParameters);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<AchievementListNotifier>();
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
  void didUpdateWidget(AchievementsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri == widget.uri) return;

    final incoming =
        AchievementQuery.fromQueryParameters(widget.uri.queryParameters);
    _syncRangeFields(incoming);
    context.read<AchievementListNotifier>().syncFromQuery(incoming);
  }

  @override
  void dispose() {
    final model = _model;
    if (model != null && model.onQueryChanged == _publish) {
      model.onQueryChanged = null;
    }
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  void _publish(AchievementQuery query) {
    if (!mounted) return;
    final location = Uri(
      path: widget.uri.path,
      queryParameters: query.toQueryParameters(),
    ).toString();
    context.go(location);
  }

  void _syncRangeFields(AchievementQuery query) {
    _setField(_yearFromController, query.yearFrom);
    _setField(_yearToController, query.yearTo);
  }

  static void _setField(TextEditingController controller, int? value) {
    final text = value == null ? '' : '$value';
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _applyYearRange(String _) async {
    final model = context.read<AchievementListNotifier>();
    await model.applyQuery(
      model.query.copyWith(
        yearFrom: Format.parseCount(_yearFromController.text),
        yearTo: Format.parseCount(_yearToController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AchievementListNotifier>();
    final query = model.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Награды'),
        actions: [
          IconButton(
            tooltip: 'Добавить',
            onPressed: () => context.go('/achievements/new'),
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
                text: 'Показывать отозванные',
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
          child: const ListNavBar(active: ListDestination.achievements),
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
                    hintText: 'Поиск по названию или описанию',
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
          EntityPaginator<Achievement>(
            page: model.result,
            enabled: model.status == LoadStatus.success,
            onPageSizeChanged: model.changePageSize,
            onPageSelected: model.goToPage,
          ),
        ],
      ),
    );
  }

  Widget _filters(AchievementListNotifier model) {
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
            width: 140,
            child: TextField(
              controller: _yearFromController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год от',
                isDense: true,
              ),
              onSubmitted: _applyYearRange,
              onEditingComplete: () => _applyYearRange(''),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _yearToController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год до',
                isDense: true,
              ),
              onSubmitted: _applyYearRange,
              onEditingComplete: () => _applyYearRange(''),
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
                'Показаны отозванные награды',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(AchievementListNotifier model) {
    return switch (model.status) {
      LoadStatus.idle || LoadStatus.loading =>
        const ListLoadingState(message: 'Ищем награды…'),
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

  Widget _table(AchievementListNotifier model) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EntityTable<Achievement>(
        columns: [
          TableColumnSpec(
            label: '№',
            sortField: 'id',
            numeric: true,
            width: 56,
            build: (a) => Text('${a.id}'),
          ),
          TableColumnSpec(
            label: 'Награда',
            sortField: 'name',
            build: (a) => _openLink('/achievements/${a.id}', a.name),
          ),
          TableColumnSpec(
            label: 'Описание',
            sortField: 'description',
            build: (a) => Text(a.description),
          ),
          TableColumnSpec(
            label: 'Год',
            sortField: 'year',
            numeric: true,
            build: (a) => Text(a.year == 0 ? '—' : '${a.year}'),
          ),
          TableColumnSpec(
            label: 'Обладателей',
            sortField: 'holders',
            numeric: true,
            build: (a) => Text('${a.holderCount}'),
          ),
          TableColumnSpec(
            label: 'Отозвана',
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

  Widget _cards(AchievementListNotifier model) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: model.result.items.length,
      itemBuilder: (context, index) {
        final achievement = model.result.items[index];
        return EntityCard<Achievement>(
          item: achievement,
          selected: model.selected.contains(achievement.id),
          onSelectChanged: (value) => model.toggleSelection(achievement.id),
          title: _openLink('/achievements/${achievement.id}', achievement.name),
          subtitle: Text(
            achievement.year == 0 ? 'Год не указан' : '${achievement.year}',
          ),
          fields: [
            ('Описание', Text(achievement.description)),
            ('Обладателей', Text('${achievement.holderCount}')),
            if (achievement.deletedAt != null)
              ('Отозвана', Text(Format.date(achievement.deletedAt!))),
          ],
          actions: _rowActions(achievement),
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

  List<Widget> _rowActions(Achievement achievement) {
    final model = context.read<AchievementListNotifier>();

    if (achievement.isDeleted) {
      return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/achievements/${achievement.id}/edit'),
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
        IconButton(
          tooltip: 'Вернуть награду',
          onPressed: () => model.restore(achievement.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить из базы',
          onPressed: () => _confirmDelete(achievement, physical: true),
          icon: const Icon(Icons.delete_forever, size: 20),
        ),
      ];
    }

    return [
      IconButton(
        tooltip: 'Отозвать награду',
        onPressed: () => _confirmDelete(achievement, physical: false),
        icon: const Icon(Icons.undo),
      ),
      IconButton(
        tooltip: 'Удалить из базы',
        onPressed: () => _confirmDelete(achievement, physical: true),
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
    ];
  }

  Future<void> _confirmDelete(
    Achievement achievement, {
    required bool physical,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(physical ? 'Удалить награду?' : 'Отозвать награду?'),
        content: Text(physical
            ? 'Награда «${achievement.name}» будет удалена безвозвратно.'
            : 'Награда «${achievement.name}» будет помечена отозванной '
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
            child: Text(physical ? 'Удалить' : 'Отозвать'),
          ),
        ],
      ),
    );
    if (confirmed == null || !confirmed || !mounted) return;

    final model = context.read<AchievementListNotifier>();
    await (physical
        ? model.hardDelete(achievement.id)
        : model.softDelete(achievement.id));
    _toast(physical
        ? 'Награда «${achievement.name}» удалена'
        : 'Награда «${achievement.name}» отозвана');
  }

  Future<void> _confirmMassDelete(AchievementListNotifier model) async {
    final count = model.selected.length;
    final physical = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Обработать $count'),
        content: Text(
          'Выбрано наград: $count. Логическое удаление помечает их '
          'отозванными, физическое — стирает из базы безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отозвать'),
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
    _toast(physical ? 'Удалено записей: $deleted' : 'Отозвано наград: $deleted');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
