import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/hockey_player.dart';
import '../models/player_query.dart';
import '../state/load_status.dart';
import '../state/player_list_notifier.dart';
import '../utils/format.dart';
import '../widgets/entity_card.dart';
import '../widgets/entity_paginator.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_nav_bar.dart';
import '../widgets/list_states.dart';
import '../widgets/search_field.dart';
import '../widgets/selection_bar.dart';
import 'checked_menu_item.dart';

const double tableBreakpoint = 600;

class PlayersListScreen extends StatefulWidget {
  const PlayersListScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends State<PlayersListScreen> {
  final _priceFromController = TextEditingController();
  final _priceToController = TextEditingController();

  bool _filtersOpen = true;

  bool _filtersInitialized = false;

  PlayerListNotifier? _model;

  PlayerQuery get _query => context.read<PlayerListNotifier>().query;

  @override
  void initState() {
    super.initState();

    final incoming = _queryFromUri(widget.uri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<PlayerListNotifier>();
      _model = model;
      model.onQueryChanged = _publish;
      model.adoptQuery(incoming);
      _syncPriceFields(incoming);
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
  void didUpdateWidget(PlayersListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri == widget.uri) return;

    final incoming = _queryFromUri(widget.uri);
    _syncPriceFields(incoming);
    context.read<PlayerListNotifier>().syncFromQuery(incoming);
  }

  @override
  void dispose() {
    final model = _model;
    if (model != null && model.onQueryChanged == _publish) {
      model.onQueryChanged = null;
    }
    _priceFromController.dispose();
    _priceToController.dispose();
    super.dispose();
  }

  static PlayerQuery _queryFromUri(Uri uri) =>
      PlayerQuery.fromQueryParameters(uri.queryParameters);

  void _publish(PlayerQuery query) {
    if (!mounted) return;
    final location = Uri(
      path: widget.uri.path,
      queryParameters: query.toQueryParameters(),
    ).toString();
    context.go(location);
  }

  void _syncPriceFields(PlayerQuery query) {
    _setField(_priceFromController, query.priceFrom);
    _setField(_priceToController, query.priceTo);
  }

  static void _setField(TextEditingController controller, double? value) {
    final text = value == null ? '' : Format.plain(value);
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _applyPriceRange(String _) async {
    final model = context.read<PlayerListNotifier>();
    await model.applyQuery(
      _query.copyWith(
        priceFrom: Format.parseAmount(_priceFromController.text),
        priceTo: Format.parseAmount(_priceToController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PlayerListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Хоккеисты'),
        actions: [
          IconButton(
            tooltip: 'Добавить игрока',
            onPressed: () => context.go('/players/new'),
            icon: const Icon(Icons.person_add_alt),
          ),
          IconButton(
            tooltip: _filtersOpen ? 'Скрыть фильтры' : 'Показать фильтры',
            onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
            icon: Icon(_filtersOpen ? Icons.filter_alt : Icons.filter_alt_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ещё',
            onSelected: (value) => switch (value) {
              'deleted' => model.toggleShowDeleted(),
              'reset' => model.resetFilters(),
              'error' => model.applyQuery(
                  _query.copyWith(simulateError: !_query.simulateError)),
              _ => null,
            },
            itemBuilder: (context) => [
              CheckedMenuItem(
                value: 'deleted',
                checked: _query.includeDeleted,
                text: 'Показывать проданных',
              ),
              CheckedMenuItem(
                value: 'error',
                checked: _query.simulateError,
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
          child: const ListNavBar(active: ListDestination.players),
        ),
      ),
      body: Column(
        children: [
          _controls(model),
          if (_filtersOpen) _filters(model),
          if (model.hasSelection)
            SelectionBar(
              count: model.selected.length,
              deletedMode: _query.includeDeleted,
              onClear: model.clearSelection,
              onDelete: () => _confirmMassDelete(model),
            ),
          Expanded(child: _body(model)),
          EntityPaginator<HockeyPlayer>(
            page: model.result,
            enabled: model.status == LoadStatus.success,
            onPageSizeChanged: model.changePageSize,
            onPageSelected: model.goToPage,
          ),
        ],
      ),
    );
  }

  Widget _controls(PlayerListNotifier model) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              initialValue: model.searchText,
              hintText: 'Поиск по имени, номеру или описанию',
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
    );
  }

  Widget _filters(PlayerListNotifier model) {
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
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: query.category,
              isExpanded: true,
              hint: const Text('Амплуа'),
              decoration: const InputDecoration(labelText: 'Амплуа'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Любое'),
                ),
                for (final category in PlayerQuery.categories)
                  DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
              ],
              onChanged: (value) =>
                  model.applyQuery(query.copyWith(category: value)),
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<int>(
              initialValue: query.teamId,
              isExpanded: true,
              hint: const Text('Команда'),
              decoration: const InputDecoration(labelText: 'Команда'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Любая'),
                ),
                for (final team in model.teams)
                  DropdownMenuItem<int>(value: team.id, child: Text(team.name)),
              ],
              onChanged: (value) =>
                  model.applyQuery(query.copyWith(teamId: value)),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<int>(
              initialValue: query.achievementId,
              isExpanded: true,
              hint: const Text('Награда'),
              decoration: const InputDecoration(labelText: 'Награда'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Любая'),
                ),
                for (final achievement in model.achievements)
                  DropdownMenuItem<int>(
                    value: achievement.id,
                    child: Text(achievement.name),
                  ),
              ],
              onChanged: (value) =>
                  model.applyQuery(query.copyWith(achievementId: value)),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _priceFromController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена от',
                isDense: true,
              ),
              onSubmitted: _applyPriceRange,
              onEditingComplete: () => _applyPriceRange(''),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _priceToController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена до',
                isDense: true,
              ),
              onSubmitted: _applyPriceRange,
              onEditingComplete: () => _applyPriceRange(''),
            ),
          ),
          if (query.isFiltered)
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: TextButton.icon(
                onPressed: model.resetFilters,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Сбросить'),
              ),
            ),
          if (query.includeDeleted)
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Показаны проданные',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(PlayerListNotifier model) {
    return switch (model.status) {
      LoadStatus.idle || LoadStatus.loading =>
        const ListLoadingState(message: 'Ищем хоккеистов…'),
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

  Widget _table(PlayerListNotifier model) {
    final columns = <TableColumnSpec<HockeyPlayer>>[
      TableColumnSpec(
        label: '№',
        sortField: 'id',
        numeric: true,
        width: 56,
        build: (p) => Text('${p.id}'),
      ),
      TableColumnSpec(
        label: 'Игрок',
        sortField: 'name',
        build: (p) => _openLink('/players/${p.id}', p.name),
      ),
      TableColumnSpec(
        label: 'Номер',
        sortField: 'jerseyNumber',
        numeric: true,
        width: 76,
        build: (p) => Text(p.jerseyNumber == null ? '—' : '${p.jerseyNumber}'),
      ),
      TableColumnSpec(
        label: 'Амплуа',
        sortField: 'category',
        build: (p) => Text(p.category),
      ),
      TableColumnSpec(
        label: 'Команда',
        sortField: 'team',
        build: (p) => Text(p.teamName),
      ),
      TableColumnSpec(
        label: 'Награды',
        sortField: 'achievements',
        build: (p) => Text(
          p.achievementNames.isEmpty ? '—' : p.achievementNames.join(', '),
        ),
      ),
      TableColumnSpec(
        label: 'Контракт',
        sortField: 'contract',
        build: (p) => Text(
          p.contract == null ? '—' : Format.price(p.contract!.salary),
        ),
      ),
      TableColumnSpec(
        label: 'Цена',
        sortField: 'price',
        numeric: true,
        build: (p) => Text(Format.price(p.price)),
      ),
      TableColumnSpec(
        label: 'Продан',
        build: (p) => Text(p.deletedAt == null ? '—' : Format.date(p.deletedAt!)),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EntityTable<HockeyPlayer>(
        columns: columns,
        items: model.result.items,
        idOf: (p) => p.id,
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

  Widget _cards(PlayerListNotifier model) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: model.result.items.length,
      itemBuilder: (context, index) {
        final player = model.result.items[index];
        return EntityCard<HockeyPlayer>(
          item: player,
          selected: model.selected.contains(player.id),
          onSelectChanged: (value) => model.toggleSelection(player.id),
          title: _openLink('/players/${player.id}', player.name),
          subtitle: Text('${player.category} · ${player.teamName}'),
          fields: [
            ('Цена', Text(Format.price(player.price))),
            (
              'Награды',
              Text(
                player.achievementNames.isEmpty
                    ? '—'
                    : player.achievementNames.join(', '),
              )
            ),
            if (player.contract != null)
              ('Контракт', Text(Format.price(player.contract!.salary))),
            (
              'Номер',
              Text(player.jerseyNumber == null
                  ? '—'
                  : '${player.jerseyNumber}')
            ),
            ('Описание', Text(player.description)),
            if (player.deletedAt != null)
              ('Продан', Text(Format.date(player.deletedAt!))),
          ],
          actions: _rowActions(player),
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

  List<Widget> _rowActions(HockeyPlayer player) {
    final model = context.read<PlayerListNotifier>();

    if (player.isDeleted) {
      return [
        IconButton(
          tooltip: 'Вернуть в продажу',
          onPressed: () => model.restore(player.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить из базы',
          onPressed: () => _confirmDelete(player, physical: true),
          icon: const Icon(Icons.delete_forever, size: 20),
        ),
      ];
    }

    return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/players/${player.id}/edit'),
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
      IconButton(
        tooltip: 'Продать',
        onPressed: () => _confirmDelete(player, physical: false),
        icon: const Icon(Icons.sell_outlined),
      ),
      IconButton(
        tooltip: 'Удалить из базы',
        onPressed: () => _confirmDelete(player, physical: true),
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
    ];
  }

  Future<void> _confirmDelete(HockeyPlayer player, {required bool physical}) async {
    final confirmed = await _ask(
      title: physical ? 'Удалить запись?' : 'Продать игрока?',
      message: physical
          ? 'Игрок «${player.name}» будет удалён безвозвратно, '
              'восстановить его будет нельзя.'
          : 'Игрок «${player.name}» будет помечен проданным и исчезнет '
              'из общего списка, но останется в базе.',
      confirmLabel: physical ? 'Удалить' : 'Продать',
      danger: physical,
    );
    if (!confirmed || !mounted) return;

    final model = context.read<PlayerListNotifier>();
    await (physical ? model.hardDelete(player.id) : model.softDelete(player.id));
    _toast(physical
        ? 'Игрок «${player.name}» удалён'
        : 'Игрок «${player.name}» помечен проданным');
  }

  Future<void> _confirmMassDelete(PlayerListNotifier model) async {
    final count = model.selected.length;
    final physical = await _askDeleteMode(count: count);
    if (physical == null || !mounted) return;

    final deleted = await model.deleteSelected(physical: physical);
    _toast(physical
        ? 'Удалено записей: $deleted'
        : 'Помечено проданными: $deleted');
  }

  Future<bool?> _askDeleteMode({required int count}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Обработать $count'),
        content: Text(
          'Выбрано записей: $count. '
          'Логическое удаление помечает их проданными, '
          'физическое — стирает из базы безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Пометить проданными'),
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
  }

  Future<bool> _ask({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
