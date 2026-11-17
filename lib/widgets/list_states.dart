import 'package:flutter/material.dart';


class ListLoadingState extends StatelessWidget {
  const ListLoadingState({super.key, this.message = 'Загрузка…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ListEmptyState extends StatelessWidget {
  const ListEmptyState({
    super.key,
    this.title = 'Ничего не найдено',
    this.message = 'Попробуйте изменить условия отбора или сбросить фильтры.',
    this.onReset,
    this.resetLabel = 'Сбросить фильтры',
    this.resetIcon = Icons.filter_alt_off,
    this.action,
  });

  final String title;
  final String message;
  final VoidCallback? onReset;
  final String resetLabel;
  final IconData resetIcon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ] else if (onReset != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: Icon(resetIcon),
                label: Text(resetLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ListErrorState extends StatelessWidget {
  const ListErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Не удалось загрузить данные',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
