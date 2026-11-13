import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/team.dart';
import '../repositories/team_repository.dart';
import '../state/team_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/list_states.dart';
import 'entity_forms.dart';

class TeamFormScreen extends StatefulWidget {
  const TeamFormScreen({super.key, this.teamId});

  final int? teamId;

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  Team? _team;

  FormSpec? _spec;

  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final model = context.read<TeamListNotifier>();
    final repository = context.read<TeamRepository>();

    try {
      if (model.arenas.isEmpty) await model.init();
      Team? team;
      if (widget.teamId != null) {
        team = await repository.findById(widget.teamId!);
        if (team == null) throw StateError('Команда не найдена');
      }
      if (!mounted) return;
      final taken = _nameTaken(model, team);
      setState(() {
        _team = team;
        _spec = teamFormSpec(
          team: team,
          arenas: model.arenas,
          nameTaken: taken,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  bool _nameTaken(TeamListNotifier model, Team? team) {
    final name = team?.name.trim().toLowerCase();
    return model.teamsSnapshot.any(
      (row) => row.id != team?.id && row.name.trim().toLowerCase() == name,
    );
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final repository = context.read<TeamRepository>();
    final model = context.read<TeamListNotifier>();

    final name = values['name']!.trim();
    final duplicate = model.teamsSnapshot.any(
      (row) =>
          row.id != _team?.id &&
          row.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      return const FormSubmitResult.failure(
        {'name': 'Команда с таким названием уже есть'},
      );
    }

    final base = _team ??
        const Team(id: 0, name: '', city: '', arenaId: 0);

    final draft = base.copyWith(
      name: name,
      city: values['city']!.trim(),
      foundedYear: Validators.parseInt(values['foundedYear']) ?? 0,
      arenaId: Validators.parseInt(values['arenaId']) ?? 0,
    );

    try {
      if (_team == null) {
        await repository.create(draft);
      } else {
        await repository.update(draft);
      }
      await model.load();
      return const FormSubmitResult(true);
    } on ValidationException catch (error) {
      return FormSubmitResult.failure(error.errors);
    } on ApiException catch (error) {
      return FormSubmitResult.failure({'': error.message});
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Команда')),
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
        appBar: AppBar(title: const Text('Команда')),
        body: const ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/teams'),
    );
  }
}
