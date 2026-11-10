import 'package:flutter/material.dart';

class DetailRow {
  const DetailRow(this.label, this.value);

  final String label;

  final String value;
}

class DetailSection {
  const DetailSection({required this.title, required this.rows});

  final String title;

  final List<DetailRow> rows;
}

class EntityDetailsScreen extends StatelessWidget {
  const EntityDetailsScreen({
    super.key,
    required this.title,
    required this.sections,
    this.subtitle,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.isDeleted = false,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final String title;

  final String? subtitle;

  final List<DetailSection> sections;

  final VoidCallback? onEdit;

  final VoidCallback? onDelete;

  final VoidCallback? onRestore;

  final bool isDeleted;

  final bool loading;

  final String? error;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Изменить',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onRestore != null)
            IconButton(
              tooltip: 'Восстановить',
              onPressed: onRestore,
              icon: const Icon(Icons.restore),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Удалить из базы',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _body(context, theme),
    );
  }

  Widget _body(BuildContext context, ThemeData theme) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
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

    if (loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (isDeleted)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_off, size: 18, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Запись удалена и скрыта из основного списка',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (subtitle != null) ...[
          Text(subtitle!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
        ],
        for (final section in sections) ...[
          Text(section.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  for (final row in section.rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 150,
                            child: Text(
                              row.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(child: Text(row.value)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
