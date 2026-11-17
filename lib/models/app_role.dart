enum AppRole {
  scout(1),
  sponsor(2),
  admin(3);

  const AppRole(this.level);

  final int level;

  bool hasAtLeast(AppRole required) => level >= required.level;

  String get label => switch (this) {
        AppRole.scout => 'Скаут',
        AppRole.sponsor => 'Спонсор',
        AppRole.admin => 'Админ',
      };

  static AppRole fromJson(Object? value) {
    final raw = '$value'.trim().toLowerCase();
    return switch (raw) {
      'admin' => AppRole.admin,
      'sponsor' => AppRole.sponsor,
      'scout' => AppRole.scout,
      _ => AppRole.scout,
    };
  }
}
