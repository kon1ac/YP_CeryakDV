import '../models/achievement.dart';
import '../models/arena.dart';
import '../models/contract.dart';
import '../models/hockey_player.dart';
import '../models/player_query.dart';
import '../models/team.dart';
import '../utils/format.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';

class PlayerFormData {
  const PlayerFormData({
    this.name = '',
    this.description = '',
    this.category = '',
    this.price = '',
    this.jerseyNumber = '',
    this.teamId = '',
    this.achievementIds = const [],
    this.contractNumber = '',
    this.contractEmail = '',
    this.contractSalary = '',
    this.contractSignedAt = '',
    this.contractExpiresAt = '',
  });

  final String name;

  final String description;

  final String category;

  final String price;

  final String jerseyNumber;

  final String teamId;

  final List<String> achievementIds;

  final String contractNumber;

  final String contractEmail;

  final String contractSalary;

  final String contractSignedAt;

  final String contractExpiresAt;

  factory PlayerFormData.fromPlayer(HockeyPlayer player) {
    final contract = player.contract;
    return PlayerFormData(
      name: player.name,
      description: player.description,
      category: player.category,
      price: Format.plain(player.price),
      jerseyNumber: player.jerseyNumber?.toString() ?? '',
      teamId: player.teamId == 0 ? '' : '${player.teamId}',
      achievementIds: [for (final id in player.achievementIds) '$id'],
      contractNumber: contract == null ? '' : '${contract.number}',
      contractEmail: contract?.email ?? '',
      contractSalary:
          contract == null ? '' : Format.plain(contract.salary),
      contractSignedAt:
          contract == null ? '' : Format.isoDate(contract.signedAt),
      contractExpiresAt: contract?.expiresAt == null
          ? ''
          : Format.isoDate(contract!.expiresAt!),
    );
  }

  Map<String, String> toValues() => {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'jerseyNumber': jerseyNumber,
        'teamId': teamId,
        'achievementIds': achievementIds.join(','),
        'contractNumber': contractNumber,
        'contractEmail': contractEmail,
        'contractSalary': contractSalary,
        'contractSignedAt': contractSignedAt,
        'contractExpiresAt': contractExpiresAt,
      };
}

FormSpec playerFormSpec({
  required PlayerFormData data,
  required List<Team> teams,
  required List<Achievement> achievements,
  required Set<int> Function(int teamId) achievementsOfTeam,
  required bool editing,
  required bool Function(int number, {int? exceptId}) jerseyTaken,
  required bool Function(String email, {int? exceptId}) emailTaken,
  int? playerId,
}) {
  return FormSpec(
    title: editing ? 'Игрок' : 'Новый игрок',
    submitLabel: editing ? 'Сохранить' : 'Создать',
    sections: [
      FormSectionSpec(
        title: 'Основное',
        fields: [
          TextFieldSpec(
            key: 'name',
            label: 'Имя и фамилия',
            initial: data.name,
            hint: 'Артём Костров',
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите имя'),
              (value) => Validators.minLength(value, 3),
              (value) => Validators.maxLength(value, 60),
            ]),
          ),
          TextFieldSpec(
            key: 'description',
            label: 'Описание',
            initial: data.description,
            maxLines: 3,
            validator: (value) => Validators.maxLength(value, 240),
          ),
          SelectFieldSpec(
            key: 'category',
            label: 'Амплуа',
            initial: data.category.isEmpty ? null : data.category,
            options: [
              for (final category in PlayerQuery.categories)
                FormOption(category, category),
            ],
            validator: (value) =>
                Validators.required(value, message: 'Выберите амплуа'),
          ),
          SelectFieldSpec(
            key: 'teamId',
            label: 'Команда',
            helper: 'Список заполнен из репозитория команд',
            initial: data.teamId.isEmpty ? null : data.teamId,
            options: [
              for (final team in teams) FormOption('${team.id}', team.name),
            ],
            validator: (value) =>
                Validators.required(value, message: 'Выберите команду'),
          ),
          TextFieldSpec(
            key: 'jerseyNumber',
            label: 'Игровой номер',
            initial: data.jerseyNumber,
            numeric: true,
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите номер'),
              (value) => Validators.integer(
                    value,
                    min: 1,
                    max: 99,
                    rangeMessage: 'Номер от 1 до 99',
                  ),
              (value) => Validators.unique(
                    value,
                    exists: (candidate) => jerseyTaken(
                      int.parse(candidate),
                      exceptId: playerId,
                    ),
                    message: 'Этот номер уже занят в лиге',
                  ),
            ]),
          ),
          TextFieldSpec(
            key: 'price',
            label: 'Стоимость, ₽',
            initial: data.price,
            numeric: true,
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите цену'),
              (value) => Validators.positive(value, message: 'Цена больше нуля'),
              (value) => Validators.decimal(
                    value,
                    max: 10000000,
                    rangeMessage: 'Слишком большая сумма',
                  ),
            ]),
          ),
        ],
      ),
      FormSectionSpec(
        title: 'Награды',
        fields: [
          MultiSelectFieldSpec(
            key: 'achievementIds',
            label: 'Награды игрока',
            helper: 'Множественный выбор из справочника наград',
            initial: data.achievementIds.toSet(),
            options: [
              for (final achievement in achievements)
                FormOption('${achievement.id}', achievement.name),
            ],
            cascade: (values) {
              final teamId = Validators.parseInt(values['teamId']);
              final current = <String>{
                for (final raw in (values['achievementIds'] ?? '').split(','))
                  if (Validators.parseInt(raw) != null) raw.trim(),
              };
              final available = teamId == null
                  ? <int>{}
                  : achievementsOfTeam(teamId);
              return [
                for (final achievement in achievements)
                  if (teamId == null ||
                      available.contains(achievement.id) ||
                      current.contains('${achievement.id}'))
                    FormOption('${achievement.id}', achievement.name),
              ];
            },
            validator: (value) {
              final text = value?.trim() ?? '';
              final count = text.isEmpty ? 0 : text.split(',').length;
              if (count > 5) return 'Не больше пяти наград';
              return null;
            },
          ),
        ],
      ),
      FormSectionSpec(
        title: 'Контракт',
        fields: [
          TextFieldSpec(
            key: 'contractNumber',
            label: 'Номер контракта',
            initial: data.contractNumber,
            numeric: true,
            helper: 'Пустое поле — контракта нет',
            validator: (value) => Validators.integer(
              value,
              min: 1,
              max: 999999,
              rangeMessage: 'Номер от 1 до 999999',
            ),
          ),
          TextFieldSpec(
            key: 'contractEmail',
            label: 'Почта агента',
            initial: data.contractEmail,
            email: true,
            validator: Validators.all([
              (value) => Validators.email(value),
              (value) => Validators.unique(
                    value,
                    exists: (candidate) =>
                        emailTaken(candidate, exceptId: playerId),
                    message: 'Этот адрес уже указан у другого игрока',
                  ),
            ]),
          ),
          TextFieldSpec(
            key: 'contractSalary',
            label: 'Зарплата, ₽',
            initial: data.contractSalary,
            numeric: true,
            validator: (value) => Validators.positive(
              value,
              message: 'Зарплата больше нуля',
            ),
          ),
          TextFieldSpec(
            key: 'contractSignedAt',
            label: 'Дата подписания',
            initial: data.contractSignedAt,
            hint: '2025-08-01',
            validator: (value) => Validators.date(value),
          ),
          TextFieldSpec(
            key: 'contractExpiresAt',
            label: 'Действует до',
            initial: data.contractExpiresAt,
            hint: '2027-06-30',
            validator: (value) => Validators.date(value),
          ),
        ],
      ),
    ],
  );
}

FormSpec teamFormSpec({
  required Team? team,
  required List<Arena> arenas,
  required bool nameTaken,
}) {
  return FormSpec(
    title: team == null ? 'Новая команда' : 'Команда',
    submitLabel: team == null ? 'Создать' : 'Сохранить',
    sections: [
      FormSectionSpec(
        title: 'Основное',
        fields: [
          TextFieldSpec(
            key: 'name',
            label: 'Название',
            initial: team?.name ?? '',
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите название'),
              (value) => Validators.minLength(value, 2),
              (value) => Validators.maxLength(value, 40),
              (value) => Validators.unique(
                    value,
                    exists: (_) => nameTaken,
                    message: 'Команда с таким названием уже есть',
                  ),
            ]),
          ),
          TextFieldSpec(
            key: 'city',
            label: 'Город',
            initial: team?.city ?? '',
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите город'),
              (value) => Validators.maxLength(value, 40),
            ]),
          ),
          TextFieldSpec(
            key: 'foundedYear',
            label: 'Год основания',
            initial: team == null ? '' : '${team.foundedYear}',
            numeric: true,
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите год'),
              (value) => Validators.year(value),
            ]),
          ),
          SelectFieldSpec(
            key: 'arenaId',
            label: 'Домашняя арена',
            helper: 'Список заполнен из репозитория арен',
            initial: team == null || team.arenaId == 0 ? null : '${team.arenaId}',
            options: [
              for (final arena in arenas) FormOption('${arena.id}', arena.name),
            ],
            validator: (value) =>
                Validators.required(value, message: 'Выберите арену'),
          ),
        ],
      ),
    ],
  );
}

FormSpec arenaFormSpec({required Arena? arena, required bool nameTaken}) {
  return FormSpec(
    title: arena == null ? 'Новая арена' : 'Арена',
    submitLabel: arena == null ? 'Создать' : 'Сохранить',
    sections: [
      FormSectionSpec(
        title: 'Основное',
        fields: [
          TextFieldSpec(
            key: 'name',
            label: 'Название',
            initial: arena?.name ?? '',
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите название'),
              (value) => Validators.maxLength(value, 50),
              (value) => Validators.unique(
                    value,
                    exists: (_) => nameTaken,
                    message: 'Арена с таким названием уже есть',
                  ),
            ]),
          ),
          TextFieldSpec(
            key: 'city',
            label: 'Город',
            initial: arena?.city ?? '',
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите город'),
              (value) => Validators.maxLength(value, 40),
            ]),
          ),
          TextFieldSpec(
            key: 'capacity',
            label: 'Вместимость',
            initial: arena == null ? '' : '${arena.capacity}',
            numeric: true,
            validator: Validators.all([
              (value) =>
                  Validators.required(value, message: 'Укажите вместимость'),
              (value) => Validators.integer(
                    value,
                    min: 500,
                    max: 100000,
                    rangeMessage: 'Вместимость от 500 до 100 000',
                  ),
            ]),
          ),
        ],
      ),
    ],
  );
}

FormSpec achievementFormSpec({
  required Achievement? achievement,
  required bool nameTaken,
}) {
  return FormSpec(
    title: achievement == null ? 'Новая награда' : 'Награда',
    submitLabel: achievement == null ? 'Создать' : 'Сохранить',
    sections: [
      FormSectionSpec(
        title: 'Основное',
        fields: [
          TextFieldSpec(
            key: 'name',
            label: 'Название',
            initial: achievement?.name ?? '',
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите название'),
              (value) => Validators.maxLength(value, 60),
              (value) => Validators.unique(
                    value,
                    exists: (_) => nameTaken,
                    message: 'Награда с таким названием уже есть',
                  ),
            ]),
          ),
          TextFieldSpec(
            key: 'description',
            label: 'Описание',
            initial: achievement?.description ?? '',
            maxLines: 3,
            validator: (value) => Validators.maxLength(value, 240),
          ),
          TextFieldSpec(
            key: 'year',
            label: 'Год учреждения',
            initial: achievement == null ? '' : '${achievement.year}',
            numeric: true,
            validator: Validators.all([
              (value) => Validators.required(value, message: 'Укажите год'),
              (value) => Validators.year(value),
            ]),
          ),
        ],
      ),
    ],
  );
}

Contract? contractFromValues(Map<String, String> values) {
  final number = Validators.parseInt(values['contractNumber']);
  final email = (values['contractEmail'] ?? '').trim();
  final salary = Format.parseAmount(values['contractSalary'] ?? '');
  final signedAt = Validators.parseDate(values['contractSignedAt']);

  final empty = number == null &&
      email.isEmpty &&
      salary == null &&
      signedAt == null &&
      (values['contractExpiresAt'] ?? '').trim().isEmpty;
  if (empty) return null;

  return Contract(
    id: 0,
    number: number ?? 0,
    email: email,
    salary: salary ?? 0,
    signedAt: signedAt ?? DateTime.now(),
    expiresAt: Validators.parseDate(values['contractExpiresAt']),
  );
}
