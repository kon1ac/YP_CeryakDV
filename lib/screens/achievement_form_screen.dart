import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../repositories/achievement_repository.dart';
import '../state/achievement_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/list_states.dart';
import 'entity_forms.dart';

class AchievementFormScreen extends StatefulWidget {
  const AchievementFormScreen({super.key, this.achievementId});

  final int? achievementId;

  @override
  State<AchievementFormScreen> createState() => _AchievementFormScreenState();
}

class _AchievementFormScreenState extends State<AchievementFormScreen> {
  Achievement? _achievement;

  FormSpec? _spec;

  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final model = context.read<AchievementListNotifier>();
    final repository = context.read<AchievementRepository>();

    try {
      if (model.achievementsSnapshot.isEmpty) await model.init();
      Achievement? achievement;
      if (widget.achievementId != null) {
        achievement = await repository.findById(widget.achievementId!);
        if (achievement == null) throw StateError('Награда не найдена');
      }
      if (!mounted) return;
      setState(() {
        _achievement = achievement;
        _spec = achievementFormSpec(
          achievement: achievement,
          nameTaken: _nameTaken(model, achievement),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  bool _nameTaken(AchievementListNotifier model, Achievement? achievement) {
    final name = achievement?.name.trim().toLowerCase();
    return model.achievementsSnapshot.any(
      (row) =>
          row.id != achievement?.id && row.name.trim().toLowerCase() == name,
    );
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final repository = context.read<AchievementRepository>();
    final model = context.read<AchievementListNotifier>();

    final name = values['name']!.trim();
    final duplicate = model.achievementsSnapshot.any(
      (row) =>
          row.id != _achievement?.id &&
          row.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      return const FormSubmitResult.failure(
        {'name': 'Награда с таким названием уже есть'},
      );
    }

    final base =
        _achievement ?? const Achievement(id: 0, name: '', description: '');

    final draft = base.copyWith(
      name: name,
      description: values['description']!.trim(),
      year: Validators.parseInt(values['year']) ?? 0,
    );

    if (_achievement == null) {
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
        appBar: AppBar(title: const Text('Награда')),
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
        appBar: AppBar(title: const Text('Награда')),
        body: const ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/achievements'),
    );
  }
}
