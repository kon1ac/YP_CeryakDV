import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';
import '../models/scout_report.dart';
import '../models/shortlist_entry.dart';
import '../models/transfer_offer.dart';
import '../repositories/role_entity_api.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/list_states.dart';

const _offerStatusOptions = [
  FormOption('pending', 'Ожидает'),
  FormOption('accepted', 'Принят'),
  FormOption('rejected', 'Отклонён'),
];

const _verdictOptions = [
  FormOption('recommend', 'Рекомендовать'),
  FormOption('watch', 'Наблюдать'),
  FormOption('reject', 'Отклонить'),
];

List<FormOption> get _ratingOptions => [
      for (var i = 1; i <= 10; i++) FormOption('$i', '$i / 10'),
    ];

const _roleOptions = [
  FormOption('scout', 'Скаут'),
  FormOption('sponsor', 'Спонсор'),
  FormOption('admin', 'Админ'),
];

String? _passwordRules(String? value, {required bool required}) {
  final text = value ?? '';
  if (text.isEmpty) {
    return required ? 'Укажите пароль' : null;
  }
  if (text.length < 8) return 'Пароль не короче восьми символов';
  if (!RegExp(r'\d').hasMatch(text)) return 'Пароль должен содержать цифру';
  if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/'`~]''').hasMatch(text)) {
    return 'Пароль должен содержать специальный символ';
  }
  return null;
}

// ─── Оффер ──────────────────────────────────────────────────────────────────

class OfferFormScreen extends StatefulWidget {
  const OfferFormScreen({super.key, this.offerId});

  final String? offerId;

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  FormSpec? _spec;
  TransferOffer? _offer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final api = RoleEntityApi(context.read<Dio>());
    try {
      final players = await api.playerOptions();
      final teams = await api.teamOptions();
      TransferOffer? offer;
      if (widget.offerId != null) {
        final json = await api.getById('/offers', widget.offerId!);
        offer = TransferOffer.fromJson(json);
      }
      if (!mounted) return;
      setState(() {
        _offer = offer;
        _spec = FormSpec(
          title: offer == null ? 'Новый оффер' : 'Оффер: ${offer.playerName}',
          submitLabel: offer == null ? 'Создать' : 'Сохранить',
          sections: [
            FormSectionSpec(
              title: 'Предложение',
              fields: [
                SelectFieldSpec(
                  key: 'playerId',
                  label: 'Игрок',
                  options: players,
                  initial: offer == null ? null : '${offer.playerId}',
                  validator: (v) =>
                      Validators.required(v, message: 'Выберите игрока'),
                ),
                SelectFieldSpec(
                  key: 'teamId',
                  label: 'Команда',
                  options: teams,
                  initial: offer == null ? null : '${offer.teamId}',
                  validator: (v) =>
                      Validators.required(v, message: 'Выберите команду'),
                ),
                TextFieldSpec(
                  key: 'salary',
                  label: 'Оклад, ₽',
                  initial: offer == null
                      ? ''
                      : offer.salary.toStringAsFixed(
                          offer.salary == offer.salary.roundToDouble() ? 0 : 2,
                        ),
                  numeric: true,
                  validator: Validators.all([
                    (v) => Validators.required(v, message: 'Укажите оклад'),
                    (v) => Validators.decimal(v, min: 0),
                  ]),
                ),
                SelectFieldSpec(
                  key: 'status',
                  label: 'Статус',
                  options: _offerStatusOptions,
                  initial: offer?.status ?? 'pending',
                  validator: (v) =>
                      Validators.required(v, message: 'Укажите статус'),
                ),
                TextFieldSpec(
                  key: 'message',
                  label: 'Сообщение',
                  initial: offer?.message ?? '',
                  maxLines: 4,
                  hint: 'Условия, роль в составе, комментарий…',
                ),
              ],
            ),
          ],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final api = RoleEntityApi(context.read<Dio>());
    final salaryRaw = values['salary']!.trim().replaceAll(',', '.');
    final body = {
      'player': values['playerId']!,
      'team': values['teamId']!,
      'salary': double.parse(salaryRaw),
      'status': values['status']!,
      'message': values['message']!.trim(),
    };
    try {
      if (_offer == null) {
        await api.create('/offers', body);
      } else {
        await api.update('/offers', _offer!.id, body);
      }
      return const FormSubmitResult(true);
    } on ValidationException catch (error) {
      return FormSubmitResult.failure(error.errors);
    } on ApiException catch (error) {
      return FormSubmitResult.failure({'': error.message});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Оффер')),
        body: ListErrorState(
          message: '$_error',
          onRetry: () {
            setState(() => _error = null);
            _prepare();
          },
        ),
      );
    }
    final spec = _spec;
    if (spec == null) {
      return const Scaffold(
        body: ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/offers'),
    );
  }
}

// ─── Отчёт скаута ───────────────────────────────────────────────────────────

class ScoutReportFormScreen extends StatefulWidget {
  const ScoutReportFormScreen({super.key, this.reportId});

  final String? reportId;

  @override
  State<ScoutReportFormScreen> createState() => _ScoutReportFormScreenState();
}

class _ScoutReportFormScreenState extends State<ScoutReportFormScreen> {
  FormSpec? _spec;
  ScoutReport? _report;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final api = RoleEntityApi(context.read<Dio>());
    try {
      final players = await api.playerOptions();
      ScoutReport? report;
      if (widget.reportId != null) {
        final json = await api.getById('/scout-reports', widget.reportId!);
        report = ScoutReport.fromJson(json);
      }
      if (!mounted) return;
      setState(() {
        _report = report;
        _spec = FormSpec(
          title: report == null ? 'Новый отчёт' : 'Отчёт: ${report.playerName}',
          submitLabel: report == null ? 'Создать' : 'Сохранить',
          sections: [
            FormSectionSpec(
              title: 'Оценка игрока',
              fields: [
                SelectFieldSpec(
                  key: 'playerId',
                  label: 'Игрок',
                  options: players,
                  initial: report == null ? null : '${report.playerId}',
                  validator: (v) =>
                      Validators.required(v, message: 'Выберите игрока'),
                ),
                SelectFieldSpec(
                  key: 'rating',
                  label: 'Оценка',
                  options: _ratingOptions,
                  initial: '${report?.rating ?? 7}',
                  validator: (v) =>
                      Validators.required(v, message: 'Укажите оценку'),
                ),
                SelectFieldSpec(
                  key: 'verdict',
                  label: 'Вердикт',
                  options: _verdictOptions,
                  initial: report?.verdict ?? 'watch',
                  validator: (v) =>
                      Validators.required(v, message: 'Укажите вердикт'),
                ),
                TextFieldSpec(
                  key: 'summary',
                  label: 'Текст отчёта',
                  initial: report?.summary ?? '',
                  maxLines: 6,
                  hint: 'Сильные стороны, риски, рекомендация…',
                  validator: Validators.all([
                    (v) => Validators.required(v, message: 'Добавьте текст'),
                    (v) => Validators.maxLength(v, 2000),
                  ]),
                ),
              ],
            ),
          ],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final api = RoleEntityApi(context.read<Dio>());
    final body = {
      'player': values['playerId']!,
      'rating': int.parse(values['rating']!),
      'verdict': values['verdict']!,
      'summary': values['summary']!.trim(),
    };
    try {
      if (_report == null) {
        await api.create('/scout-reports', body);
      } else {
        await api.update('/scout-reports', _report!.id, body);
      }
      return const FormSubmitResult(true);
    } on ValidationException catch (error) {
      return FormSubmitResult.failure(error.errors);
    } on ApiException catch (error) {
      return FormSubmitResult.failure({'': error.message});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Отчёт')),
        body: ListErrorState(
          message: '$_error',
          onRetry: () {
            setState(() => _error = null);
            _prepare();
          },
        ),
      );
    }
    final spec = _spec;
    if (spec == null) {
      return const Scaffold(
        body: ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/scout-reports'),
    );
  }
}

// ─── Шортлист ───────────────────────────────────────────────────────────────

class ShortlistFormScreen extends StatefulWidget {
  const ShortlistFormScreen({super.key, this.entryId});

  final String? entryId;

  @override
  State<ShortlistFormScreen> createState() => _ShortlistFormScreenState();
}

class _ShortlistFormScreenState extends State<ShortlistFormScreen> {
  FormSpec? _spec;
  ShortlistEntry? _entry;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final api = RoleEntityApi(context.read<Dio>());
    try {
      final players = await api.playerOptions();
      ShortlistEntry? entry;
      if (widget.entryId != null) {
        final json = await api.getById('/shortlist', widget.entryId!);
        entry = ShortlistEntry.fromJson(json);
      }
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _spec = FormSpec(
          title: entry == null ? 'В шортлист' : 'Заметка: ${entry.playerName}',
          submitLabel: entry == null ? 'Добавить' : 'Сохранить',
          sections: [
            FormSectionSpec(
              title: 'Игрок',
              fields: [
                SelectFieldSpec(
                  key: 'playerId',
                  label: 'Игрок',
                  options: players,
                  initial: entry == null ? null : '${entry.playerId}',
                  helper: entry == null
                      ? 'Одного игрока нельзя добавить дважды'
                      : null,
                  validator: (v) =>
                      Validators.required(v, message: 'Выберите игрока'),
                ),
                TextFieldSpec(
                  key: 'note',
                  label: 'Заметка',
                  initial: entry?.note ?? '',
                  maxLines: 4,
                  hint: 'Почему в шортлисте, на что смотреть…',
                  validator: (v) => Validators.maxLength(v, 500),
                ),
              ],
            ),
          ],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final api = RoleEntityApi(context.read<Dio>());
    final body = {
      'player': values['playerId']!,
      'note': values['note']!.trim(),
    };
    try {
      if (_entry == null) {
        await api.create('/shortlist', body);
      } else {
        await api.update('/shortlist', _entry!.id, body);
      }
      return const FormSubmitResult(true);
    } on ConflictException catch (error) {
      return FormSubmitResult.failure({'playerId': error.message});
    } on ValidationException catch (error) {
      return FormSubmitResult.failure(error.errors);
    } on ApiException catch (error) {
      return FormSubmitResult.failure({'': error.message});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Шортлист')),
        body: ListErrorState(
          message: '$_error',
          onRetry: () {
            setState(() => _error = null);
            _prepare();
          },
        ),
      );
    }
    final spec = _spec;
    if (spec == null) {
      return const Scaffold(
        body: ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/shortlist'),
    );
  }
}

// ─── Пользователь ───────────────────────────────────────────────────────────

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.userId});

  final String? userId;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  FormSpec? _spec;
  AppUser? _user;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final api = RoleEntityApi(context.read<Dio>());
    try {
      AppUser? user;
      if (widget.userId != null) {
        final json = await api.getById('/users', widget.userId!);
        user = AppUser.fromJson(json);
      }
      if (!mounted) return;
      final isNew = user == null;
      setState(() {
        _user = user;
        _spec = FormSpec(
          title: isNew
              ? 'Новый пользователь'
              : 'Пользователь: ${user!.username}',
          submitLabel: isNew ? 'Создать' : 'Сохранить',
          sections: [
            FormSectionSpec(
              title: 'Учётная запись',
              fields: [
                TextFieldSpec(
                  key: 'username',
                  label: 'Логин',
                  initial: user?.username ?? '',
                  validator: Validators.all([
                    (v) => Validators.required(v, message: 'Укажите логин'),
                    (v) => Validators.minLength(v, 3),
                  ]),
                ),
                TextFieldSpec(
                  key: 'fullName',
                  label: 'ФИО',
                  initial: user?.fullName ?? '',
                  validator: (v) =>
                      Validators.required(v, message: 'Укажите ФИО'),
                ),
                TextFieldSpec(
                  key: 'email',
                  label: 'Email',
                  initial: user?.email ?? '',
                  email: true,
                  validator: Validators.email,
                ),
                SelectFieldSpec(
                  key: 'role',
                  label: 'Роль',
                  options: _roleOptions,
                  initial: user?.role.name ?? AppRole.scout.name,
                  validator: (v) =>
                      Validators.required(v, message: 'Выберите роль'),
                ),
                TextFieldSpec(
                  key: 'password',
                  label: isNew ? 'Пароль' : 'Новый пароль',
                  helper: isNew
                      ? '≥8 символов, цифра и спецсимвол'
                      : 'Оставьте пустым, чтобы не менять',
                  obscure: true,
                  validator: (v) => _passwordRules(v, required: isNew),
                ),
              ],
            ),
          ],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<FormSubmitResult> _submit(Map<String, String> values) async {
    final api = RoleEntityApi(context.read<Dio>());
    final body = <String, dynamic>{
      'username': values['username']!.trim(),
      'fullName': values['fullName']!.trim(),
      'email': values['email']!.trim(),
      'role': values['role']!,
    };
    final password = values['password'] ?? '';
    if (password.isNotEmpty) body['password'] = password;

    try {
      if (_user == null) {
        await api.create('/users', body);
      } else {
        await api.update('/users', _user!.id, body);
      }
      return const FormSubmitResult(true);
    } on ValidationException catch (error) {
      return FormSubmitResult.failure(error.errors);
    } on ApiException catch (error) {
      return FormSubmitResult.failure({'': error.message});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользователь')),
        body: ListErrorState(
          message: '$_error',
          onRetry: () {
            setState(() => _error = null);
            _prepare();
          },
        ),
      );
    }
    final spec = _spec;
    if (spec == null) {
      return const Scaffold(
        body: ListLoadingState(message: 'Готовим форму…'),
      );
    }
    return EntityFormScreen(
      spec: spec,
      onSubmit: _submit,
      onSaved: () => context.go('/users'),
    );
  }
}
