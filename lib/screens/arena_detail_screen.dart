import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/arena.dart';
import '../repositories/arena_repository.dart';
import '../state/arena_list_notifier.dart';
import '../utils/format.dart';
import '../widgets/entity_details.dart';

class ArenaDetailScreen extends StatefulWidget {
  const ArenaDetailScreen({super.key, required this.arenaId});

  final int arenaId;

  @override
  State<ArenaDetailScreen> createState() => _ArenaDetailScreenState();
}

class _ArenaDetailScreenState extends State<ArenaDetailScreen> {
  Arena? _arena;

  String? _error;

  bool _loading = true;

  ArenaListNotifier? _model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<ArenaListNotifier>();
      _model = model;
      model.addListener(_reload);
      _load();
    });
  }

  void _reload() {
    if (!mounted || _loading) return;
    _load();
  }

  @override
  void dispose() {
    _model?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final arena =
          await context.read<ArenaRepository>().findById(widget.arenaId);
      if (!mounted) return;
      setState(() {
        _arena = arena;
        _loading = false;
        if (arena == null) _error = 'Арена не найдена';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    final repository = context.read<ArenaRepository>();
    final model = context.read<ArenaListNotifier>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.hardDelete(id);
      await model.load();
      if (!mounted) return;
      router.go('/arenas');
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _restore(int id) async {
    final model = context.read<ArenaListNotifier>();
    await model.restore(id);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final arena = _arena;

    return EntityDetailsScreen(
      title: 'Карточка арены',
      subtitle: arena?.name,
      loading: _loading,
      error: _error,
      onRetry: _load,
      isDeleted: arena?.isDeleted ?? false,
      onEdit:
          arena == null ? null : () => context.go('/arenas/${arena.id}/edit'),
      onRestore: arena == null || !arena.isDeleted
          ? null
          : () => _restore(arena.id),
      onDelete: arena == null ? null : () => _delete(arena.id),
      sections: arena == null
          ? const []
          : [
              DetailSection(
                title: 'Основное',
                rows: [
                  DetailRow('Название', arena.name),
                  DetailRow('Город', arena.city),
                  DetailRow('Вместимость', Format.plain(arena.capacity.toDouble())),
                  DetailRow('Команд на арене', '${arena.teamCount}'),
                ],
              ),
              if (arena.deletedAt != null)
                DetailSection(
                  title: 'Удаление',
                  rows: [DetailRow('Закрыта', Format.date(arena.deletedAt!))],
                ),
            ],
    );
  }
}
