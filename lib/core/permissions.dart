import '../models/app_role.dart';

/// Матрица прав для UI и unit-тестов (сервер — источник истины).
class Permissions {
  const Permissions(this.role);

  final AppRole role;

  bool get canReadCatalog => true;

  /// Игроки и команды (не справочники арен/наград).
  bool get canWriteCatalog => role.hasAtLeast(AppRole.sponsor);

  /// Арены и награды — только админ.
  bool get canManageDictionaries => role == AppRole.admin;

  bool get canAccessOffers => role.hasAtLeast(AppRole.sponsor);

  bool get canAccessScoutTools =>
      role == AppRole.scout || role == AppRole.admin;

  bool get canManageUsers => role == AppRole.admin;

  bool get canHardDelete => role == AppRole.admin;

  bool get canRestore => role == AppRole.admin;

  bool canOpenPath(String path) {
    if (path.startsWith('/users')) return canManageUsers;
    if (path.startsWith('/offers')) return canAccessOffers;
    if (path.startsWith('/scout-reports') || path.startsWith('/shortlist')) {
      return canAccessScoutTools;
    }
    if (path.contains('/arenas/new') ||
        path.contains('/arenas/') && path.endsWith('/edit') ||
        path.contains('/achievements/new') ||
        path.contains('/achievements/') && path.endsWith('/edit')) {
      return canManageDictionaries;
    }
    return canReadCatalog;
  }
}
