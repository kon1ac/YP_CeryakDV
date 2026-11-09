import 'package:go_router/go_router.dart';

import 'screens/not_found_screen.dart';
import 'screens/players_list_screen.dart';
import 'screens/teams_list_screen.dart';

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
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => TeamsListScreen(uri: state.uri),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

final appRouter = buildRouter();
