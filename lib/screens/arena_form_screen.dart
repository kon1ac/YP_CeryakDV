import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/arena.dart';
import '../repositories/arena_repository.dart';
import '../state/arena_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/list_states.dart';
import 'entity_forms.dart';

class ArenaFormScreen extends StatefulWidget {
  const ArenaFormScreen({super.key, this.arenaId});

  final int? arenaId;

  @override
  State<ArenaFormScreen> createState() => _ArenaFormScreenState();
}

class _ArenaFormScreenState extends State<ArenaFormScreen> {
  Arena? _arena;

  FormSpec? _spec;

  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final model = context.read<ArenaListNotifier>();
    final repository = context.read<ArenaRepository>();

    try {
      if (model.arenasSnapshot.isEmpty) await model.init();
      Arena? arena;
      if (widget.arenaId != null) {
        arena = await repository.findById(widget.arenaId!);
        if (arena == null) throw StateError('Арена не найдена');
      }
      if (!mounted) return;
      setState(() {
        _arena = arena;
        _spec = arenaFormSpec(
          arena: arena,
          nameTaken: _nameTaken(model, arena),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  bool _nameTaken(ArenaListNotifier model, Arena? arena) {
    final name = arena?.name.trim().toLowerCase();
    return model.arenasSnapshot.any(
      (row) => row.id != arena?.id && row.name.trim().toLowerCase() == name,
    );
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final repository = context.read<ArenaRepository>();
    final model = context.read<ArenaListNotifier>();

    final name = values['name']!.trim();
    final duplicate = model.arenasSnapshot.any(
      (row) =>
          row.id != _arena?.id &&
          row.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      return const FormSubmitResult.failure(
        {'name': 'Арена с таким названием уже есть'},
      );
    }

    final base = _arena ?? const Arena(id: 0, name: '', city: '');

    final draft = base.copyWith(
      name: name,
      city: values['city']!.trim(),
      capacity: Validators.parseInt(values['capacity']) ?? 0,
    );

    if (_arena == null) {
      await repository.create(draft);
    } else {
      await repository.update(draft);
    }
    await model.load();
    return const FormSubmitResult(true);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Арена')),
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
        appBar: AppBar(title: const Text('Арена')),
        body: const ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/arenas'),
    );
  }
}
