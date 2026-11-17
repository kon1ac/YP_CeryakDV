import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';

const double kListNavBarHeight = 56;

enum ListDestination {
  players,
  teams,
  arenas,
  achievements,
  contracts,
  offers,
  scoutReports,
  shortlist,
  users,
}

class _NavItem {
  const _NavItem({
    required this.destination,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final ListDestination destination;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _allItems = <_NavItem>[
  _NavItem(
    destination: ListDestination.players,
    path: '/players',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Игроки',
  ),
  _NavItem(
    destination: ListDestination.teams,
    path: '/teams',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    label: 'Команды',
  ),
  _NavItem(
    destination: ListDestination.arenas,
    path: '/arenas',
    icon: Icons.stadium_outlined,
    selectedIcon: Icons.stadium,
    label: 'Арены',
  ),
  _NavItem(
    destination: ListDestination.achievements,
    path: '/achievements',
    icon: Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events,
    label: 'Награды',
  ),
  _NavItem(
    destination: ListDestination.contracts,
    path: '/contracts',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
    label: 'Контракты',
  ),
  _NavItem(
    destination: ListDestination.offers,
    path: '/offers',
    icon: Icons.local_offer_outlined,
    selectedIcon: Icons.local_offer,
    label: 'Офферы',
  ),
  _NavItem(
    destination: ListDestination.scoutReports,
    path: '/scout-reports',
    icon: Icons.article_outlined,
    selectedIcon: Icons.article,
    label: 'Отчёты',
  ),
  _NavItem(
    destination: ListDestination.shortlist,
    path: '/shortlist',
    icon: Icons.playlist_add_check_outlined,
    selectedIcon: Icons.playlist_add_check,
    label: 'Шортлист',
  ),
  _NavItem(
    destination: ListDestination.users,
    path: '/users',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
    label: 'Пользователи',
  ),
];

/// Горизонтальный скролл-нав: не сжимает пункты и не даёт overflow при ресайзе.
class ListNavBar extends StatefulWidget {
  const ListNavBar({super.key, required this.active});

  final ListDestination active;

  @override
  State<ListNavBar> createState() => _ListNavBarState();
}

class _ListNavBarState extends State<ListNavBar> {
  final _controller = ScrollController();
  final Map<ListDestination, GlobalKey> _keys = {
    for (final item in _allItems) item.destination: GlobalKey(),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  void _ensureVisible() {
    final key = _keys[widget.active];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.4,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  List<_NavItem> _visibleFor(AuthNotifier auth) {
    return [
      for (final item in _allItems)
        if (_allowed(auth, item.destination)) item,
    ];
  }

  static bool _allowed(AuthNotifier auth, ListDestination destination) {
    return switch (destination) {
      ListDestination.players ||
      ListDestination.teams ||
      ListDestination.arenas ||
      ListDestination.achievements ||
      ListDestination.contracts =>
        auth.isAuthenticated,
      ListDestination.offers => auth.canAccessOffers,
      ListDestination.scoutReports || ListDestination.shortlist =>
        auth.canAccessScoutTools,
      ListDestination.users => auth.canManageUsers,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final items = _visibleFor(auth);
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final compact = Breakpoints.isCompact(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kListNavBarHeight,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 16,
              vertical: 8,
            ),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = item.destination == widget.active;
              return KeyedSubtree(
                key: _keys[item.destination],
                child: _NavChip(
                  icon: selected ? item.selectedIcon : item.icon,
                  label: item.label,
                  selected: selected,
                  compact: compact && items.length > 5,
                  onTap: () {
                    if (item.destination == widget.active) return;
                    context.go(item.path);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.secondaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact && !selected ? 10 : 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
              if (!compact || selected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
