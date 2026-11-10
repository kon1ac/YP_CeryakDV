import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/hockey_player.dart';
import '../repositories/hockey_player_repository.dart';
import '../state/player_list_notifier.dart';
import '../utils/format.dart';
import '../widgets/entity_details.dart';

class PlayerDetailScreen extends StatefulWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final int playerId;

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  HockeyPlayer? _player;

  String? _error;

  bool _loading = true;

  PlayerListNotifier? _model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<PlayerListNotifier>();
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
      final player =
          await context.read<HockeyPlayerRepository>().findById(widget.playerId);
      if (!mounted) return;
      setState(() {
        _player = player;
        _loading = false;
        if (player == null) _error = 'Игрок не найден';
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
    final model = context.read<PlayerListNotifier>();
    final router = GoRouter.of(context);
    await model.hardDelete(id);
    if (!mounted) return;
    router.go('/players');
  }

  Future<void> _restore(int id) async {
    final model = context.read<PlayerListNotifier>();
    await model.restore(id);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;

    return EntityDetailsScreen(
      title: 'Карточка игрока',
      subtitle: player?.name,
      loading: _loading,
      error: _error,
      onRetry: _load,
      isDeleted: player?.isDeleted ?? false,
      onEdit: player == null
          ? null
          : () => context.go('/players/${player.id}/edit'),
      onRestore: player == null || !player.isDeleted
          ? null
          : () => _restore(player.id),
      onDelete: player == null
          ? null
          : () => _remove(player.id),
      sections: player == null
          ? const []
          : [
              DetailSection(
                title: 'Основное',
                rows: [
                  DetailRow('Имя', player.name),
                  DetailRow('Амплуа', player.category),
                  DetailRow('Команда', player.teamName),
                  DetailRow(
                    'Игровой номер',
                    player.jerseyNumber?.toString() ?? '—',
                  ),
                  DetailRow('Стоимость', Format.price(player.price)),
                  DetailRow(
                    'Описание',
                    player.description.isEmpty ? '—' : player.description,
                  ),
                ],
              ),
              DetailSection(
                title: 'Награды',
                rows: [
                  DetailRow(
                    'Всего',
                    '${player.achievementNames.length}',
                  ),
                  for (final name in player.achievementNames)
                    DetailRow('Награда', name),
                ],
              ),
              DetailSection(
                title: 'Контракт',
                rows: player.contract == null
                    ? const [DetailRow('Статус', 'контракта нет')]
                    : [
                        DetailRow('Номер', '${player.contract!.number}'),
                        DetailRow('Почта', player.contract!.email),
                        DetailRow(
                          'Зарплата',
                          Format.price(player.contract!.salary),
                        ),
                        DetailRow(
                          'Подписан',
                          Format.date(player.contract!.signedAt),
                        ),
                        DetailRow(
                          'Действует до',
                          player.contract!.expiresAt == null
                              ? 'бессрочно'
                              : Format.date(player.contract!.expiresAt!),
                        ),
                      ],
              ),
              if (player.deletedAt != null)
                DetailSection(
                  title: 'Удаление',
                  rows: [DetailRow('Удалён', Format.date(player.deletedAt!))],
                ),
            ],
    );
  }
}
