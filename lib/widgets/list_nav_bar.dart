import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const double kListNavBarHeight = kToolbarHeight;

enum ListDestination { players, teams }

class ListNavBar extends StatelessWidget {
  const ListNavBar({super.key, required this.active});

  final ListDestination active;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: active.index,
      onDestinationSelected: (index) {
        if (index == active.index) return;
        context.go(index == ListDestination.players.index ? '/players' : '/teams');
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
      ],
    );
  }
}
