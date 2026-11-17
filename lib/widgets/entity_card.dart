import 'package:flutter/material.dart';

import '../core/breakpoints.dart';
import '../models/list_query.dart';

class EntityCard<T extends Identifiable> extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.item,
    required this.title,
    this.subtitle,
    this.fields = const [],
    this.selected = false,
    this.onSelectChanged,
    this.actions = const [],
  });

  final T item;
  final Widget title;
  final Widget? subtitle;

  final List<(String, Widget)> fields;

  final bool selected;
  final ValueChanged<bool>? onSelectChanged;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deleted = item.isDeleted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: deleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onSelectChanged != null)
                  Checkbox(
                    value: selected,
                    onChanged: (value) => onSelectChanged!(value ?? false),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                        style: deleted
                            ? TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              )
                            : theme.textTheme.titleMedium,
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle.merge(
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                  ),
              ],
            ),
            if (fields.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final (label, value) in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _CardField(label: label, value: value),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final compact = Breakpoints.isCompact(context);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          value,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: labelStyle)),
        Expanded(child: value),
      ],
    );
  }
}
