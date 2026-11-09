import 'package:flutter/material.dart';

class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onDelete,
    this.deletedMode = false,
  });

  final int count;

  final VoidCallback onClear;

  final VoidCallback onDelete;

  final bool deletedMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Выбрано: $count',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: const Text('Снять выделение'),
            ),
            FilledButton.tonalIcon(
              onPressed: onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
              icon: const Icon(Icons.delete_outline),
              label: Text(deletedMode ? 'Списать насовсем' : 'Удалить выбранные'),
            ),
          ],
        ),
      ),
    );
  }
}
