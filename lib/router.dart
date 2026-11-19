import 'package:go_router/go_router.dart';

import 'screens/achievement_detail_screen.dart';
import 'screens/achievement_form_screen.dart';
import 'screens/achievements_list_screen.dart';
import 'screens/arena_detail_screen.dart';
import 'screens/arena_form_screen.dart';
import 'screens/arenas_list_screen.dart';
import 'screens/contracts_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/player_detail_screen.dart';
import 'screens/player_form_screen.dart';
import 'screens/players_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_entity_forms.dart';
import 'screens/role_entity_list_screen.dart';
import 'screens/team_detail_screen.dart';
import 'screens/team_form_screen.dart';
import 'screens/teams_list_screen.dart';
import 'state/auth_notifier.dart';

String? _idOf(GoRouterState state) {
  final raw = state.pathParameters['id'];
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

bool _isPublic(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  return path == '/login' || path == '/register';
}

String? _roleRedirect(AuthNotifier auth, String path) {
  if (path.startsWith('/dashboard')) {
    return auth.canAccessDashboard ? null : '/forbidden';
  }
  if (path.startsWith('/users')) {
    return auth.canManageUsers ? null : '/forbidden';
  }
  if (path.startsWith('/offers')) {
    return auth.canAccessOffers ? null : '/forbidden';
  }
  if (path.startsWith('/scout-reports') || path.startsWith('/shortlist')) {
    return auth.canAccessScoutTools ? null : '/forbidden';
  }
  // Создание/редактирование справочников — только админ.
  final dictionaryWrite = path == '/arenas/new' ||
      path == '/achievements/new' ||
      (path.startsWith('/arenas/') && path.endsWith('/edit')) ||
      (path.startsWith('/achievements/') && path.endsWith('/edit'));
  if (dictionaryWrite && !auth.canManageDictionaries) {
    return '/forbidden';
  }
  // Создание/редактирование игроков и команд — спонсор+.
  final catalogWrite = path == '/players/new' ||
      path == '/teams/new' ||
      (path.startsWith('/players/') && path.endsWith('/edit')) ||
      (path.startsWith('/teams/') && path.endsWith('/edit'));
  if (catalogWrite && !auth.canWriteCatalog) {
    return '/forbidden';
  }
  return null;
}

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/players',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final goingPublic = _isPublic(loc);

      if (!loggedIn && !goingPublic) {
        final from = state.uri.toString();
        return Uri(
          path: '/login',
          queryParameters: from == '/login' ? null : {'from': from},
        ).toString();
      }

      if (loggedIn && goingPublic) {
        return '/players';
      }

      if (loggedIn) {
        return _roleRedirect(auth, loc);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/players',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => PlayersListScreen(uri: state.uri),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const PlayerFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                PlayerDetailScreen(playerId: _idOf(state) ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    PlayerFormScreen(playerId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => TeamsListScreen(uri: state.uri),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TeamFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                TeamDetailScreen(teamId: _idOf(state) ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    TeamFormScreen(teamId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/arenas',
        builder: (context, state) => ArenasListScreen(uri: state.uri),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ArenaFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ArenaDetailScreen(arenaId: _idOf(state) ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    ArenaFormScreen(arenaId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/contracts',
        builder: (context, state) => ContractsListScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => AchievementsListScreen(uri: state.uri),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const AchievementFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AchievementDetailScreen(achievementId: _idOf(state) ?? ''),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    AchievementFormScreen(achievementId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/offers',
        builder: (context, state) => const OffersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const OfferFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                OfferFormScreen(offerId: _idOf(state)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    OfferFormScreen(offerId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/scout-reports',
        builder: (context, state) => const ScoutReportsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ScoutReportFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ScoutReportFormScreen(reportId: _idOf(state)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    ScoutReportFormScreen(reportId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/shortlist',
        builder: (context, state) => const ShortlistScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ShortlistFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ShortlistFormScreen(entryId: _idOf(state)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    ShortlistFormScreen(entryId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const UserFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => UserFormScreen(userId: _idOf(state)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    UserFormScreen(userId: _idOf(state)),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
