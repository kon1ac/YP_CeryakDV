import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/team.dart';
import '../repositories/team_repository.dart';
import '../state/team_list_notifier.dart';
import '../utils/format.dart';
import '../widgets/entity_details.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final int teamId;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;

  String? _error;

  bool _loading = true;

  TeamListNotifier? _model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<TeamListNotifier>();
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
      final team = await context.read<TeamRepository>().findById(widget.teamId);
      if (!mounted) return;
      setState(() {
        _team = team;
        _loading = false;
        if (team == null) _error = 'Команда не найдена';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _remove(int id) async {
    final model = context.read<TeamListNotifier>();
    final router = GoRouter.of(context);
    await model.hardDelete(id);
    if (!mounted) return;
    router.go('/teams');
  }

  Future<void> _restore(int id) async {
    final model = context.read<TeamListNotifier>();
    await model.restore(id);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;

    return EntityDetailsScreen(
      title: 'Карточка команды',
      subtitle: team?.name,
      loading: _loading,
      error: _error,
      onRetry: _load,
      isDeleted: team?.isDeleted ?? false,
      onEdit:
          team == null ? null : () => context.go('/teams/${team.id}/edit'),
      onRestore: team == null || !team.isDeleted
          ? null
          : () => _restore(team.id),
      onDelete: team == null ? null : () => _remove(team.id),
      sections: team == null
          ? const []
          : [
              DetailSection(
                title: 'Основное',
                rows: [
                  DetailRow('Название', team.name),
                  DetailRow('Город', team.city),
                  DetailRow('Год основания', '${team.foundedYear}'),
                  DetailRow(
                    'Домашняя арена',
                    team.arenaName.isEmpty ? '—' : team.arenaName,
                  ),
                  DetailRow('Игроков в составе', '${team.rosterSize}'),
                ],
              ),
              if (team.deletedAt != null)
                DetailSection(
                  title: 'Удаление',
                  rows: [DetailRow('Расформирована', Format.date(team.deletedAt!))],
                ),
            ],
    );
  }
}
