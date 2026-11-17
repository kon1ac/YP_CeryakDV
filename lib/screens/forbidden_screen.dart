import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_menu_button.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступ запрещён'),
        actions: const [AuthMenuButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                '403',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'У вашей роли недостаточно прав для этого раздела.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/players'),
                child: const Text('К списку хоккеистов'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
