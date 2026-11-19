import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/breakpoints.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';
import '../models/scout_report.dart';
import '../models/shortlist_entry.dart';
import '../models/transfer_offer.dart';
import '../repositories/role_entity_api.dart';
import '../widgets/auth_menu_button.dart';
import '../widgets/list_nav_bar.dart';
import '../widgets/list_states.dart';
import '../widgets/search_field.dart';

String verdictLabel(String verdict) => switch (verdict) {
      'recommend' => 'Рекомендовать',
      'watch' => 'Наблюдать',
      'reject' => 'Отклонить',
      _ => verdict,
    };

Color verdictColor(ColorScheme scheme, String verdict) => switch (verdict) {
      'recommend' => scheme.primary,
      'reject' => scheme.error,
      _ => scheme.tertiary,
    };

String offerStatusLabel(String status) => switch (status) {
      'pending' => 'Ожидает',
      'accepted' => 'Принят',
      'rejected' => 'Отклонён',
      'withdrawn' => 'Отозван',
      _ => status,
    };

/// Универсальный CRUD-список для ролевых разделов.
class RoleEntityListScreen extends StatefulWidget {
  const RoleEntityListScreen({
    super.key,
    required this.title,
    required this.active,
    required this.endpoint,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.searchHint,
    required this.itemBuilder,
    this.createPath,
    this.createLabel = 'Создать',
    this.mutable = true,
  });

  final String title;
  final ListDestination active;
  final String endpoint;
  final String? createPath;
  final String createLabel;
  final String emptyTitle;
  final String emptyMessage;
  final String searchHint;
  final bool mutable;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> json,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  ) itemBuilder;

  @override
  State<RoleEntityListScreen> createState() => _RoleEntityListScreenState();
}

class _RoleEntityListScreenState extends State<RoleEntityListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String _query = '';
  bool _busy = false;

  RoleEntityApi? _api;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _api = RoleEntityApi(context.read<Dio>());
      _load();
    });
  }

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return [
      for (final item in _items)
        if ('$item'.toLowerCase().contains(q)) item,
    ];
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await api.list(widget.endpoint, size: 100);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> json) async {
    final api = _api;
    final idRaw = json['id'];
    final id = idRaw == null ? null : '$idRaw';
    if (api == null || id == null || id.isEmpty) return;
    final label = json['playerName'] ??
        json['fullName'] ??
        json['username'] ??
        '#$id';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('«$label» будет убрана из списка (мягкое удаление).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await api.delete(widget.endpoint, id);
      if (!mounted) return;
      setState(() {
        _items = [for (final row in _items) if (row['id'] != id) row];
        _busy = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Удалено')));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  void _edit(Map<String, dynamic> json) {
    final base = widget.createPath?.replaceAll('/new', '');
    final idRaw = json['id'];
    final id = idRaw == null ? null : '$idRaw';
    if (base == null || id == null || id.isEmpty) return;
    context.go('$base/$id/edit');
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = widget.mutable && widget.createPath != null;
    final compact = Breakpoints.isCompact(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const AuthMenuButton(),
        ],
      ),
      floatingActionButton: !canCreate
          ? null
          : compact
              ? FloatingActionButton(
                  onPressed: () => context.go(widget.createPath!),
                  tooltip: widget.createLabel,
                  child: const Icon(Icons.add),
                )
              : FloatingActionButton.extended(
                  onPressed: () => context.go(widget.createPath!),
                  icon: const Icon(Icons.add),
                  label: Text(widget.createLabel),
                ),
      body: _buildBody(canCreate),
      bottomNavigationBar: ListNavBar(active: widget.active),
    );
  }

  Widget _buildBody(bool canCreate) {
    if (_loading) {
      return const ListLoadingState(message: 'Загружаем…');
    }
    if (_error != null) {
      return ListErrorState(message: _error!, onRetry: _load);
    }

    final visible = _visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchField(
            initialValue: _query,
            hintText: widget.searchHint,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              visible.length == _items.length
                  ? 'Всего: ${_items.length}'
                  : 'Показано: ${visible.length} из ${_items.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? ListEmptyState(
                  title: _items.isEmpty
                      ? widget.emptyTitle
                      : 'Ничего не найдено',
                  message: _items.isEmpty
                      ? widget.emptyMessage
                      : 'Попробуйте другой запрос.',
                  onReset: _items.isEmpty && canCreate
                      ? () => context.go(widget.createPath!)
                      : (_query.isNotEmpty
                          ? () => setState(() => _query = '')
                          : null),
                  resetLabel: _items.isEmpty && canCreate
                      ? widget.createLabel
                      : 'Сбросить поиск',
                  resetIcon: _items.isEmpty && canCreate
                      ? Icons.add
                      : Icons.filter_alt_off,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final json = visible[index];
                      return widget.itemBuilder(
                        context,
                        json,
                        widget.mutable ? () => _edit(json) : null,
                        widget.mutable ? () => _confirmDelete(json) : null,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    this.leading,
    this.chips = const [],
    this.onEdit,
    this.onDelete,
  });

  final Widget title;
  final Widget subtitle;
  final Widget? leading;
  final List<Widget> chips;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = Breakpoints.isCompact(context);
    final actions = <Widget>[
      if (!compact && onEdit != null)
        IconButton(
          tooltip: 'Изменить',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      if (!compact && onDelete != null)
        IconButton(
          tooltip: 'Удалить',
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
          ),
        ),
      if (compact && (onEdit != null || onDelete != null))
        PopupMenuButton<String>(
          tooltip: 'Действия',
          onSelected: (value) {
            if (value == 'edit') onEdit?.call();
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => [
            if (onEdit != null)
              const PopupMenuItem(value: 'edit', child: Text('Изменить')),
            if (onDelete != null)
              const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
    ];

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, compact ? 0 : 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle.merge(
                      style: theme.textTheme.titleSmall,
                      child: title,
                    ),
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: subtitle,
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: chips),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

Widget _chip(BuildContext context, String label, {Color? color}) {
  final scheme = Theme.of(context).colorScheme;
  final fg = color ?? scheme.onSurfaceVariant;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: fg.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
    ),
  );
}

// ─── Конкретные экраны ──────────────────────────────────────────────────────

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleEntityListScreen(
      title: 'Офферы',
      active: ListDestination.offers,
      endpoint: '/offers',
      createPath: '/offers/new',
      createLabel: 'Оффер',
      emptyTitle: 'Офферов пока нет',
      emptyMessage: 'Создайте предложение игроку в команду.',
      searchHint: 'Игрок, команда, статус…',
      itemBuilder: (context, json, onEdit, onDelete) {
        final offer = TransferOffer.fromJson(json);
        final scheme = Theme.of(context).colorScheme;
        final statusColor = switch (offer.status) {
          'accepted' => scheme.primary,
          'rejected' => scheme.error,
          _ => scheme.tertiary,
        };
        return _RoleTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.15),
            foregroundColor: statusColor,
            child: const Icon(Icons.local_offer_outlined, size: 20),
          ),
          title: Text(offer.label),
          subtitle: Text(
            '${offer.salary.toStringAsFixed(0)} ₽'
            '${offer.message.isEmpty ? '' : ' · ${offer.message}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          chips: [
            _chip(
              context,
              offerStatusLabel(offer.status),
              color: statusColor,
            ),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

class ScoutReportsListScreen extends StatelessWidget {
  const ScoutReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleEntityListScreen(
      title: 'Отчёты скаута',
      active: ListDestination.scoutReports,
      endpoint: '/scout-reports',
      createPath: '/scout-reports/new',
      createLabel: 'Отчёт',
      emptyTitle: 'Отчётов пока нет',
      emptyMessage: 'Создайте первый отчёт по игроку.',
      searchHint: 'Игрок, вердикт, текст…',
      itemBuilder: (context, json, onEdit, onDelete) {
        final report = ScoutReport.fromJson(json);
        final scheme = Theme.of(context).colorScheme;
        final color = verdictColor(scheme, report.verdict);
        return _RoleTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            child: Text(
              '${report.rating}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(report.playerName),
          subtitle: Text(
            report.summary.isEmpty ? 'Без текста' : report.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          chips: [
            _chip(context, verdictLabel(report.verdict), color: color),
            _chip(context, '${report.rating}/10'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

class ShortlistScreen extends StatelessWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleEntityListScreen(
      title: 'Шортлист',
      active: ListDestination.shortlist,
      endpoint: '/shortlist',
      createPath: '/shortlist/new',
      createLabel: 'Игрок',
      emptyTitle: 'Шортлист пуст',
      emptyMessage: 'Добавьте игрока, за которым хотите следить.',
      searchHint: 'Игрок или заметка…',
      itemBuilder: (context, json, onEdit, onDelete) {
        final entry = ShortlistEntry.fromJson(json);
        return _RoleTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.bookmark_added_outlined,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(entry.playerName),
          subtitle: Text(
            entry.note.isEmpty ? 'Без заметки' : entry.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleEntityListScreen(
      title: 'Пользователи',
      active: ListDestination.users,
      endpoint: '/users',
      createPath: '/users/new',
      createLabel: 'Пользователь',
      emptyTitle: 'Пользователей нет',
      emptyMessage: 'Создайте учётную запись для скаута, спонсора или админа.',
      searchHint: 'Логин, ФИО, роль…',
      itemBuilder: (context, json, onEdit, onDelete) {
        final user = AppUser.fromJson(json);
        final scheme = Theme.of(context).colorScheme;
        final roleColor = switch (user.role) {
          AppRole.admin => scheme.error,
          AppRole.sponsor => scheme.primary,
          AppRole.scout => scheme.tertiary,
        };
        final initial = user.displayName.trim().isNotEmpty
            ? user.displayName.trim().substring(0, 1).toUpperCase()
            : '?';
        return _RoleTile(
          leading: CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.15),
            foregroundColor: roleColor,
            child: Text(initial),
          ),
          title: Text(user.displayName),
          subtitle: Text('${user.username} · ${user.email}'),
          chips: [
            _chip(context, user.role.label, color: roleColor),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}
