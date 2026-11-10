import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/team.dart';
import '../models/team_query.dart';
import '../state/load_status.dart';
import '../state/team_list_notifier.dart';
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

class TeamsListScreen extends StatefulWidget {
  const TeamsListScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  final _playersFromController = TextEditingController();
  final _playersToController = TextEditingController();

  bool _filtersOpen = true;

  bool _filtersInitialized = false;

  TeamListNotifier? _model;

  @override
  void initState() {
    super.initState();

    final incoming = TeamQuery.fromQueryParameters(widget.uri.queryParameters);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<TeamListNotifier>();
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
  void didUpdateWidget(TeamsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri == widget.uri) return;

    final incoming = TeamQuery.fromQueryParameters(widget.uri.queryParameters);
    _syncRangeFields(incoming);
    context.read<TeamListNotifier>().syncFromQuery(incoming);
  }

  @override
  void dispose() {
    final model = _model;
    if (model != null && model.onQueryChanged == _publish) {
      model.onQueryChanged = null;
    }
    _playersFromController.dispose();
    _playersToController.dispose();
    super.dispose();
  }

  void _publish(TeamQuery query) {
    if (!mounted) return;
    final location = Uri(
      path: widget.uri.path,
      queryParameters: query.toQueryParameters(),
    ).toString();
    context.go(location);
  }

  void _syncRangeFields(TeamQuery query) {
    _setField(_playersFromController, query.playersFrom);
    _setField(_playersToController, query.playersTo);
  }

  static void _setField(TextEditingController controller, int? value) {
    final text = value == null ? '' : '$value';
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _applyRosterRange(String _) async {
    final model = context.read<TeamListNotifier>();
    await model.applyQuery(
      model.query.copyWith(
        playersFrom: Format.parseCount(_playersFromController.text),
        playersTo: Format.parseCount(_playersToController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TeamListNotifier>();
    final query = model.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Команды'),
        actions: [
          IconButton(
            tooltip: 'Добавить',
            onPressed: () => context.go('/teams/new'),
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
                text: 'Показывать расформированные',
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
          child: const ListNavBar(active: ListDestination.teams),
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
          EntityPaginator<Team>(
            page: model.result,
            enabled: model.status == LoadStatus.success,
            onPageSizeChanged: model.changePageSize,
            onPageSelected: model.goToPage,
          ),
        ],
      ),
    );
  }

  Widget _filters(TeamListNotifier model) {
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
            width: 140,
            child: TextField(
              controller: _playersFromController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Игроков от',
                isDense: true,
              ),
              onSubmitted: _applyRosterRange,
              onEditingComplete: () => _applyRosterRange(''),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _playersToController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Игроков до',
                isDense: true,
              ),
              onSubmitted: _applyRosterRange,
              onEditingComplete: () => _applyRosterRange(''),
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
                'Показаны расформированные',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(TeamListNotifier model) {
    return switch (model.status) {
      LoadStatus.idle || LoadStatus.loading =>
        const ListLoadingState(message: 'Ищем команды…'),
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

  Widget _table(TeamListNotifier model) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EntityTable<Team>(
        columns: [
          TableColumnSpec(
            label: '№',
            sortField: 'id',
            numeric: true,
            width: 56,
            build: (t) => Text('${t.id}'),
          ),
          TableColumnSpec(
            label: 'Команда',
            sortField: 'name',
            build: (t) => _openLink('/teams/${t.id}', t.name),
          ),
          TableColumnSpec(
            label: 'Город',
            sortField: 'city',
            build: (t) => Text(t.city),
          ),
          TableColumnSpec(
            label: 'Основана',
            sortField: 'foundedYear',
            numeric: true,
            build: (t) => Text(t.foundedYear == 0 ? '—' : '${t.foundedYear}'),
          ),
          TableColumnSpec(
            label: 'Игроков',
            sortField: 'players',
            numeric: true,
            build: (t) => Text('${t.rosterSize}'),
          ),
          TableColumnSpec(
            label: 'Расформирована',
            build: (t) =>
                Text(t.deletedAt == null ? '—' : Format.date(t.deletedAt!)),
          ),
        ],
        items: model.result.items,
        idOf: (t) => t.id,
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

  Widget _cards(TeamListNotifier model) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: model.result.items.length,
      itemBuilder: (context, index) {
        final team = model.result.items[index];
        return EntityCard<Team>(
          item: team,
          selected: model.selected.contains(team.id),
          onSelectChanged: (value) => model.toggleSelection(team.id),
          title: _openLink('/teams/${team.id}', team.name),
          subtitle: Text(team.city),
          fields: [
            (
              'Основана',
              Text(team.foundedYear == 0 ? '—' : '${team.foundedYear}')
            ),
            ('Игроков в составе', Text('${team.rosterSize}')),
            if (team.deletedAt != null)
              ('Расформирована', Text(Format.date(team.deletedAt!))),
          ],
          actions: _rowActions(team),
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

  List<Widget> _rowActions(Team team) {
    final model = context.read<TeamListNotifier>();

    if (team.isDeleted) {
      return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/teams/${team.id}/edit'),
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
        IconButton(
          tooltip: 'Вернуть список',
          onPressed: () => model.restore(team.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить из базы',
          onPressed: () => _confirmDelete(team, physical: true),
          icon: const Icon(Icons.delete_forever, size: 20),
        ),
      ];
    }

    return [
      IconButton(
        tooltip: 'Расформировать',
        onPressed: () => _confirmDelete(team, physical: false),
        icon: const Icon(Icons.flag_outlined),
      ),
      IconButton(
        tooltip: 'Удалить из базы',
        onPressed: () => _confirmDelete(team, physical: true),
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
    ];
  }

  Future<void> _confirmDelete(Team team, {required bool physical}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            physical ? 'Удалить команду?' : 'Расформировать команду?'),
        content: Text(physical
            ? 'Команда «${team.name}» будет удалена безвозвратно.'
            : 'Команда «${team.name}» будет помечена расформированной '
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
            child: Text(physical ? 'Удалить' : 'Расформировать'),
          ),
        ],
      ),
    );
    if (confirmed == null || !confirmed || !mounted) return;

    final model = context.read<TeamListNotifier>();
    await (physical ? model.hardDelete(team.id) : model.softDelete(team.id));
    _toast(physical
        ? 'Команда «${team.name}» удалена'
        : 'Команда «${team.name}» расформирована');
  }

  Future<void> _confirmMassDelete(TeamListNotifier model) async {
    final count = model.selected.length;
    final physical = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Обработать $count'),
        content: Text(
          'Выбрано команд: $count. Логическое удаление помечает их '
          'расформированными, физическое — стирает из базы безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Расформировать'),
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
    if (physical == null || !physical || !mounted) return;

    final deleted = await model.deleteSelected(physical: physical);
    _toast(physical
        ? 'Удалено записей: $deleted'
        : 'Расформировано команд: $deleted');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
