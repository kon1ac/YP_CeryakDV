import 'package:go_router/go_router.dart';

import 'screens/achievement_detail_screen.dart';
import 'screens/achievement_form_screen.dart';
import 'screens/achievements_list_screen.dart';
import 'screens/arena_detail_screen.dart';
import 'screens/arena_form_screen.dart';
import 'screens/arenas_list_screen.dart';
import 'screens/contracts_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/player_detail_screen.dart';
import 'screens/player_form_screen.dart';
import 'screens/players_list_screen.dart';
import 'screens/team_detail_screen.dart';
import 'screens/team_form_screen.dart';
import 'screens/teams_list_screen.dart';

int? _idOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/players',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/players',
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
                PlayerDetailScreen(playerId: _idOf(state) ?? 0),
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
                TeamDetailScreen(teamId: _idOf(state) ?? 0),
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
                ArenaDetailScreen(arenaId: _idOf(state) ?? 0),
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
                AchievementDetailScreen(achievementId: _idOf(state) ?? 0),
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
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

final appRouter = buildRouter();
