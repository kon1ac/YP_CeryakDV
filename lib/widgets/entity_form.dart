import 'package:flutter/material.dart';

import '../utils/validators.dart';

class FormOption {
  const FormOption(this.value, this.label);

  final String value;

  final String label;
}

typedef CascadeResolver = List<FormOption> Function(Map<String, String> values);

sealed class FormFieldSpec {
  const FormFieldSpec({
    required this.key,
    required this.label,
    this.helper,
    this.validator,
  });

  final String key;

  final String label;

  final String? helper;

  final TextValidator? validator;

  String get initialText;

  String? get initialChoice;

  Set<String> get initialChoices => const {};

  CascadeResolver? get cascade => null;
}

class TextFieldSpec extends FormFieldSpec {
  const TextFieldSpec({
    required super.key,
    required super.label,
    super.helper,
    super.validator,
    this.initial = '',
    this.hint,
    this.maxLines = 1,
    this.numeric = false,
    this.email = false,
    this.enabled = true,
  });

  final String initial;

  final String? hint;

  final int maxLines;

  final bool numeric;

  final bool email;

  final bool enabled;

  @override
  String get initialText => initial;

  @override
  String? get initialChoice => null;
}

class SelectFieldSpec extends FormFieldSpec {
  const SelectFieldSpec({
    required super.key,
    required super.label,
    super.helper,
    super.validator,
    required this.options,
    this.initial,
    this.emptyLabel = 'Не выбрано',
    this.cascade,
  });

  final List<FormOption> options;

  final String? initial;

  final String emptyLabel;

  @override
  final CascadeResolver? cascade;

  @override
  String get initialText => initial ?? '';

  @override
  String? get initialChoice => initial;
}

class MultiSelectFieldSpec extends FormFieldSpec {
  const MultiSelectFieldSpec({
    required super.key,
    required super.label,
    super.helper,
    super.validator,
    required this.options,
    this.initial = const {},
    this.cascade,
  });

  final List<FormOption> options;

  final Set<String> initial;

  @override
  final CascadeResolver? cascade;

  @override
  String get initialText => initial.join(',');

  @override
  String? get initialChoice => null;

  @override
  Set<String> get initialChoices => initial;
}

class FormSectionSpec {
  const FormSectionSpec({required this.title, required this.fields});

  final String title;

  final List<FormFieldSpec> fields;
}

class FormSpec {
  const FormSpec({
    required this.title,
    required this.sections,
    this.submitLabel = 'Сохранить',
  });

  final String title;

  final List<FormSectionSpec> sections;

  final String submitLabel;

  List<FormFieldSpec> get fields => [
        for (final section in sections) ...section.fields,
      ];

  FormSpec copyWith({
    String? title,
    List<FormSectionSpec>? sections,
    String? submitLabel,
  }) {
    return FormSpec(
      title: title ?? this.title,
      sections: sections ?? this.sections,
      submitLabel: submitLabel ?? this.submitLabel,
    );
  }
}

class FormSubmitResult {
  const FormSubmitResult(this.ok, {this.errors = const {}});

  const FormSubmitResult.failure(this.errors) : ok = false;

  final bool ok;

  final Map<String, String> errors;
}

class EntityFormScreen extends StatefulWidget {
  const EntityFormScreen({
    super.key,
    required this.spec,
    required this.onSubmit,
    this.confirmExit = true,
    this.onSaved,
  });

  final FormSpec spec;

  final Future<FormSubmitResult> Function(Map<String, String> values) onSubmit;

  final bool confirmExit;

  final VoidCallback? onSaved;

  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _text = {};

  final Map<String, String?> _choices = {};

  final Map<String, Set<String>> _multi = {};

  final Map<String, String> _initialText = {};

  final Map<String, String?> _initialChoice = {};

  final Map<String, Set<String>> _initialMulti = {};

  final Map<String, String> _serverErrors = {};

  bool _dirty = false;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.spec.fields) {
      switch (field) {
        case TextFieldSpec():
          _text[field.key] = TextEditingController(text: field.initial);
          _initialText[field.key] = field.initial;
        case SelectFieldSpec():
          _choices[field.key] = field.initial;
          _initialChoice[field.key] = field.initial;
        case MultiSelectFieldSpec():
          _multi[field.key] = {...field.initial};
          _initialMulti[field.key] = {...field.initial};
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<FormOption> _optionsOf(FormFieldSpec field, List<FormOption> fallback) {
    final resolver = field.cascade;
    if (resolver == null) return fallback;
    return resolver(_values);
  }

  Map<String, String> get _values => {
        for (final entry in _text.entries) entry.key: entry.value.text,
        for (final entry in _choices.entries) entry.key: entry.value ?? '',
        for (final entry in _multi.entries)
          entry.key: (entry.value.toList()..sort()).join(','),
      };

  bool get _changed {
    for (final entry in _text.entries) {
      if (entry.value.text != _initialText[entry.key]) return true;
    }
    for (final entry in _choices.entries) {
      if (entry.value != _initialChoice[entry.key]) return true;
    }
    for (final entry in _multi.entries) {
      final initial = _initialMulti[entry.key] ?? const <String>{};
      if (entry.value.length != initial.length) return true;
      if (!entry.value.containsAll(initial)) return true;
    }
    return false;
  }

  void _touch() {
    final changed = _changed;
    if (changed != _dirty) setState(() => _dirty = changed);
  }

  void _clearServerError(String key) {
    if (!_serverErrors.containsKey(key)) return;
    setState(() => _serverErrors.remove(key));
  }

  FormFieldValidator<String> _validatorFor(FormFieldSpec field) {
    return (value) {
      final server = _serverErrors[field.key];
      if (server != null) return server;
      return field.validator?.call(value);
    };
  }

  Future<void> _submit() async {
    setState(_serverErrors.clear);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final result = await widget.onSubmit(_values);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.ok) {
      setState(() => _dirty = false);
      widget.onSaved?.call();
      _close();
      return;
    }

    setState(() => _serverErrors.addAll(result.errors));
    _formKey.currentState?.validate();
    if (result.errors.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Не удалось сохранить')));
    }
  }

  Future<bool> _confirmLeave() async {
    if (!widget.confirmExit || !_dirty) return true;
    final theme = Theme.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Есть несохранённые изменения'),
        content: const Text('Если уйти сейчас, введённые данные пропадут.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Уйти без сохранения'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _leave() async {
    if (!await _confirmLeave() || !mounted) return;
    setState(() => _dirty = false);
    _close();
  }

  void _close() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<Object?>(
      canPop: !widget.confirmExit || !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.spec.title),
          actions: [
            if (_dirty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'не сохранено',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              for (final section in widget.spec.sections) ...[
                if (section.title.isNotEmpty) ...[
                  Text(section.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                ],
                for (final field in section.fields) ...[
                  _field(field),
                  const SizedBox(height: 16),
                ],
                if (section.title.isNotEmpty) const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _leave,
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.spec.submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(FormFieldSpec field) {
    return switch (field) {
      TextFieldSpec() => TextFormField(
          controller: _text[field.key],
          enabled: field.enabled && !_submitting,
          maxLines: field.maxLines,
          keyboardType: field.numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : field.email
                  ? TextInputType.emailAddress
                  : TextInputType.text,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            helperText: field.helper,
            border: const OutlineInputBorder(),
          ),
          validator: _validatorFor(field),
          onChanged: (_) {
            _clearServerError(field.key);
            _touch();
          },
        ),
      SelectFieldSpec() => _selectField(field),
      MultiSelectFieldSpec() => _multiField(field),
    };
  }

  Widget _selectField(SelectFieldSpec field) {
    final options = _optionsOf(field, field.options);
    final current = _choices[field.key];
    final known = options.any((option) => option.value == current);
    final signature = options.map((option) => option.value).join('|');

    return DropdownButtonFormField<String?>(
      key: ValueKey<String>('${field.key}#$signature'),
      initialValue: known ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.helper,
        border: const OutlineInputBorder(),
      ),
      hint: Text(options.isEmpty ? 'Сначала выберите значение выше' : field.emptyLabel),
      items: [
        for (final option in options)
          DropdownMenuItem<String?>(
            value: option.value,
            child: Text(option.label),
          ),
      ],
      validator: (value) => _validatorFor(field)(value),
      onChanged: _submitting
          ? null
          : (value) {
              setState(() => _choices[field.key] = value);
              _clearServerError(field.key);
              _touch();
            },
    );
  }

  Widget _multiField(MultiSelectFieldSpec field) {
    final theme = Theme.of(context);
    final selected = _multi[field.key] ?? <String>{};
    final options = _optionsOf(field, field.options);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.helper,
        border: const OutlineInputBorder(),
        errorText: _serverErrors[field.key] ?? field.validator?.call(''),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (options.isEmpty)
            Text(
              'Нет доступных значений — сначала выберите команду',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in options)
                  FilterChip(
                    label: Text(option.label),
                    selected: selected.contains(option.value),
                    onSelected: _submitting
                        ? null
                        : (on) {
                            setState(() {
                              if (on) {
                                selected.add(option.value);
                              } else {
                                selected.remove(option.value);
                              }
                            });
                            _clearServerError(field.key);
                            _touch();
                          },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
