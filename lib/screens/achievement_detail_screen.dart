import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../repositories/achievement_repository.dart';
import '../state/achievement_list_notifier.dart';
import '../widgets/entity_details.dart';

class AchievementDetailScreen extends StatefulWidget {
  const AchievementDetailScreen({super.key, required this.achievementId});

  final int achievementId;

  @override
  State<AchievementDetailScreen> createState() =>
      _AchievementDetailScreenState();
}

class _AchievementDetailScreenState extends State<AchievementDetailScreen> {
  Achievement? _achievement;

  String? _error;

  bool _loading = true;

  AchievementListNotifier? _model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<AchievementListNotifier>();
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
      final achievement = await context
          .read<AchievementRepository>()
          .findById(widget.achievementId);
      if (!mounted) return;
      setState(() {
        _achievement = achievement;
        _loading = false;
        if (achievement == null) _error = 'Награда не найдена';
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
    final model = context.read<AchievementListNotifier>();
    final router = GoRouter.of(context);
    await model.hardDelete(id);
    if (!mounted) return;
    router.go('/achievements');
  }

  Future<void> _restore(int id) async {
    final model = context.read<AchievementListNotifier>();
    await model.restore(id);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = _achievement;

    return EntityDetailsScreen(
      title: 'Карточка награды',
      subtitle: achievement?.name,
      loading: _loading,
      error: _error,
      onRetry: _load,
      isDeleted: achievement?.isDeleted ?? false,
      onEdit: achievement == null
          ? null
          : () => context.go('/achievements/${achievement.id}/edit'),
      onRestore: achievement == null || !achievement.isDeleted
          ? null
          : () => _restore(achievement.id),
      onDelete:
          achievement == null ? null : () => _remove(achievement.id),
      sections: achievement == null
          ? const []
          : [
              DetailSection(
                title: 'Основное',
                rows: [
                  DetailRow('Название', achievement.name),
                  DetailRow(
                    'Описание',
                    achievement.description.isEmpty
                        ? '—'
                        : achievement.description,
                  ),
                  DetailRow('Год учреждения', '${achievement.year}'),
                  DetailRow('Обладателей', '${achievement.holderCount}'),
                ],
              ),
            ],
    );
  }
}
