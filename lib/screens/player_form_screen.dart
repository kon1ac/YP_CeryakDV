import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/hockey_player.dart';
import '../repositories/hockey_player_repository.dart';
import '../state/player_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/list_states.dart';
import 'entity_forms.dart';

class PlayerFormScreen extends StatefulWidget {
  const PlayerFormScreen({super.key, this.playerId});

  final int? playerId;

  @override
  State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends State<PlayerFormScreen> {
  HockeyPlayer? _player;

  FormSpec? _spec;

  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final model = context.read<PlayerListNotifier>();
    final repository = context.read<HockeyPlayerRepository>();

    try {
      if (model.teams.isEmpty) await model.init();
      HockeyPlayer? player;
      if (widget.playerId != null) {
        player = await repository.findById(widget.playerId!);
        if (player == null) throw StateError('Игрок не найден');
      }
      if (!mounted) return;
      setState(() {
        _player = player;
        _spec = playerFormSpec(
          data: player == null
              ? const PlayerFormData()
              : PlayerFormData.fromPlayer(player),
          teams: model.teams,
          achievements: model.achievements,
          achievementsOfTeam: model.achievementsOfTeam,
          editing: player != null,
          playerId: player?.id,
          jerseyTaken: (number, {exceptId}) =>
              _catalogJerseyTaken(model, number, exceptId),
          emailTaken: (email, {exceptId}) =>
              _catalogEmailTaken(model, email, exceptId),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  bool _catalogJerseyTaken(
    PlayerListNotifier model,
    int number,
    int? exceptId,
  ) {
    return model.jerseyTakenLocally(number, exceptId: exceptId);
  }

  bool _catalogEmailTaken(
    PlayerListNotifier model,
    String email,
    int? exceptId,
  ) {
    return model.emailTakenLocally(email, exceptId: exceptId);
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final repository = context.read<HockeyPlayerRepository>();
    final model = context.read<PlayerListNotifier>();

    final name = values['name']!.trim();
    final jerseyNumber = Validators.parseInt(values['jerseyNumber']);
    final email = values['contractEmail']!.trim();

    final errors = <String, String>{};
    if (jerseyNumber != null &&
        model.jerseyTakenLocally(jerseyNumber, exceptId: widget.playerId)) {
      errors['jerseyNumber'] = 'Этот номер уже занят в лиге';
    }
    if (email.isNotEmpty &&
        model.emailTakenLocally(email, exceptId: widget.playerId)) {
      errors['contractEmail'] = 'Этот адрес уже указан у другого игрока';
    }
    if (errors.isNotEmpty) return FormSubmitResult.failure(errors);

    final base = _player ??
        const HockeyPlayer(
          id: 0,
          name: '',
          description: '',
          price: 0,
          category: '',
          teamId: 0,
        );

    final draft = base.copyWith(
      name: name,
      description: values['description']!.trim(),
      price: double.tryParse(values['price']!.trim().replaceAll(',', '.')) ?? 0,
      category: values['category']!,
      teamId: Validators.parseInt(values['teamId']) ?? 0,
      jerseyNumber: jerseyNumber,
      achievementIds: [
        for (final raw in values['achievementIds']!.split(','))
          if (Validators.parseInt(raw) != null) Validators.parseInt(raw)!,
      ],
      contract: contractFromValues(values),
      clearContract: contractFromValues(values) == null,
    );

    if (_player == null) {
      await repository.create(draft);
    } else {
      await repository.update(draft);
    }
    await model.refreshIndexes();
    await model.load();
    return const FormSubmitResult(true);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Игрок')),
        body: ListErrorState(
          message: '$_error',
          onRetry: () {
            setState(() => _error = null);
            _prepare();
          },
        ),
      );
    }
    if (spec == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Игрок')),
        body: const ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/players'),
    );
  }
}
