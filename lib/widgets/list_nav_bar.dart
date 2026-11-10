import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const double kListNavBarHeight = kToolbarHeight;

enum ListDestination { players, teams, arenas, achievements, contracts }

class ListNavBar extends StatelessWidget {
  const ListNavBar({super.key, required this.active});

  final ListDestination active;

  static const List<String> _paths = [
    '/players',
    '/teams',
    '/arenas',
    '/achievements',
    '/contracts',
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: active.index,
      onDestinationSelected: (index) {
        if (index == active.index) return;
        context.go(_paths[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Игроки',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Команды',
        ),
        NavigationDestination(
          icon: Icon(Icons.stadium_outlined),
          selectedIcon: Icon(Icons.stadium),
          label: 'Арены',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: 'Награды',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Контракты',
        ),
      ],
    );
  }
}
