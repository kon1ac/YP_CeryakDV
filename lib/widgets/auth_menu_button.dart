import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';
import '../theme.dart';

/// Имя пользователя и выход в AppBar (на узком экране — только иконка).
class AuthMenuButton extends StatelessWidget {
  const AuthMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    if (user == null) return const ThemeButton();

    final compact = Breakpoints.isCompact(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeButton(),
        PopupMenuButton<_AuthMenuAction>(
          tooltip: 'Аккаунт',
          onSelected: (action) async {
            if (action == _AuthMenuAction.logout) {
              await auth.logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                '${user.displayName} · ${user.role.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _AuthMenuAction.logout,
              child: Text('Выйти'),
            ),
          ],
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      user.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _AuthMenuAction { logout }
