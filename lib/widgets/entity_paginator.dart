import 'package:flutter/material.dart';

import '../models/list_query.dart';
import '../models/page_result.dart';

class EntityPaginator<T> extends StatelessWidget {
  const EntityPaginator({
    super.key,
    required this.page,
    required this.onPageSizeChanged,
    required this.onPageSelected,
    this.enabled = true,
  });

  final PageResult<T> page;

  final ValueChanged<int> onPageSizeChanged;

  final ValueChanged<int> onPageSelected;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            page.total == 0
                ? 'Нет записей'
                : 'Записи ${page.firstIndex}–${page.lastIndex} из ${page.total}',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('На странице:', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: page.size,
                underline: const SizedBox.shrink(),
                onChanged: enabled
                    ? (value) {
                        if (value != null) onPageSizeChanged(value);
                      }
                    : null,
                items: [
                  for (final size in pageSizes)
                    DropdownMenuItem<int>(value: size, child: Text('$size')),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Первая страница',
                onPressed: enabled && page.hasPrevious
                    ? () => onPageSelected(1)
                    : null,
                icon: const Icon(Icons.first_page),
              ),
              IconButton(
                tooltip: 'Предыдущая страница',
                onPressed: enabled && page.hasPrevious
                    ? () => onPageSelected(page.page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Стр. ${page.page} из ${page.totalPages}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: 'Следующая страница',
                onPressed: enabled && page.hasNext
                    ? () => onPageSelected(page.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Последняя страница',
                onPressed: enabled && page.hasNext
                    ? () => onPageSelected(page.totalPages)
                    : null,
                icon: const Icon(Icons.last_page),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
