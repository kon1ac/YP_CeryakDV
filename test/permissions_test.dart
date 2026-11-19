import 'package:flutter_test/flutter_test.dart';
import 'package:yp_ceryak/core/permissions.dart';
import 'package:yp_ceryak/models/app_role.dart';

void main() {
  group('Permissions matrix', () {
    test('scout: каталог читать, писать нельзя; есть отчёты; нет офферов и users', () {
      const p = Permissions(AppRole.scout);
      expect(p.canReadCatalog, isTrue);
      expect(p.canWriteCatalog, isFalse);
      expect(p.canAccessOffers, isFalse);
      expect(p.canAccessScoutTools, isTrue);
      expect(p.canManageUsers, isFalse);
      expect(p.canHardDelete, isFalse);
      expect(p.canOpenPath('/scout-reports'), isTrue);
      expect(p.canOpenPath('/offers'), isFalse);
      expect(p.canOpenPath('/users'), isFalse);
    });

    test('sponsor: игроки/команды + офферы; нет арен/наград на запись и users', () {
      const p = Permissions(AppRole.sponsor);
      expect(p.canWriteCatalog, isTrue);
      expect(p.canManageDictionaries, isFalse);
      expect(p.canAccessOffers, isTrue);
      expect(p.canAccessScoutTools, isFalse);
      expect(p.canManageUsers, isFalse);
      expect(p.canOpenPath('/offers'), isTrue);
      expect(p.canOpenPath('/arenas/new'), isFalse);
      expect(p.canOpenPath('/achievements/new'), isFalse);
      expect(p.canOpenPath('/shortlist'), isFalse);
      expect(p.canOpenPath('/users'), isFalse);
    });

    test('admin: всё, включая справочники, users и hard-delete', () {
      const p = Permissions(AppRole.admin);
      expect(p.canWriteCatalog, isTrue);
      expect(p.canManageDictionaries, isTrue);
      expect(p.canAccessOffers, isTrue);
      expect(p.canAccessDashboard, isTrue);
      expect(p.canAccessScoutTools, isTrue);
      expect(p.canManageUsers, isTrue);
      expect(p.canHardDelete, isTrue);
      expect(p.canRestore, isTrue);
      expect(p.canOpenPath('/users'), isTrue);
      expect(p.canOpenPath('/dashboard'), isTrue);
      expect(p.canOpenPath('/arenas/new'), isTrue);
      expect(p.canOpenPath('/scout-reports'), isTrue);
    });

    test('dashboard: admin/sponsor да, scout нет', () {
      expect(const Permissions(AppRole.scout).canAccessDashboard, isFalse);
      expect(const Permissions(AppRole.sponsor).canAccessDashboard, isTrue);
      expect(const Permissions(AppRole.admin).canAccessDashboard, isTrue);
    });

    test('AppRole.hasAtLeast: иерархия scout < sponsor < admin', () {
      expect(AppRole.admin.hasAtLeast(AppRole.sponsor), isTrue);
      expect(AppRole.sponsor.hasAtLeast(AppRole.scout), isTrue);
      expect(AppRole.scout.hasAtLeast(AppRole.sponsor), isFalse);
      expect(AppRole.sponsor.hasAtLeast(AppRole.admin), isFalse);
    });

    test('уникальные разделы ролей не пересекаются как «просто меньше прав»', () {
      const scout = Permissions(AppRole.scout);
      const sponsor = Permissions(AppRole.sponsor);
      // У скаута есть раздел, которого нет у спонсора
      expect(scout.canAccessScoutTools && !sponsor.canAccessScoutTools, isTrue);
      // У спонсора есть раздел, которого нет у скаута
      expect(sponsor.canAccessOffers && !scout.canAccessOffers, isTrue);
      // У админа есть users, которого нет у остальных
      expect(Permissions(AppRole.admin).canManageUsers, isTrue);
      expect(scout.canManageUsers, isFalse);
      expect(sponsor.canManageUsers, isFalse);
    });
  });
}
