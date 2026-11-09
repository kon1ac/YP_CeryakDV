import 'package:flutter/material.dart';

import '../models/list_query.dart';

class TableColumnSpec<T> {
  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
    this.width,
  });

  final String label;

  final String? sortField;

  final bool numeric;

  final Widget Function(T item) build;

  final double? width;
}

class EntityTable<T extends Identifiable> extends StatelessWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onToggleSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  final List<TableColumnSpec<T>> columns;

  final List<T> items;

  final int Function(T item) idOf;

  final Set<int> selected;

  final ValueChanged<int>? onToggleSelect;

  final VoidCallback? onToggleSelectAll;

  final String? sortField;

  final bool sortAscending;

  final ValueChanged<String>? onSort;

  final List<Widget> Function(T item)? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: sortAscending,
          headingRowHeight: 48,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 64,
          horizontalMargin: 16,
          columnSpacing: 24,
          showCheckboxColumn: onToggleSelect != null,
          onSelectAll: onToggleSelectAll == null
              ? null
              : (_) => onToggleSelectAll!(),
          columns: [
            for (final column in columns) _buildColumn(context, column),
            if (actions != null)
              const DataColumn(label: SizedBox.shrink()),
          ],
          rows: [
            for (final item in items)
              DataRow(
                key: ValueKey<int>(idOf(item)),
                selected: selected.contains(idOf(item)),
                onSelectChanged: onToggleSelect == null
                    ? null
                    : (_) => onToggleSelect!(idOf(item)),
                color: item.isDeleted
                    ? WidgetStatePropertyAll(
                        theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                      )
                    : null,
                cells: [
                  for (final column in columns)
                    DataCell(
                      DefaultTextStyle.merge(
                        style: item.isDeleted
                            ? TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                        child: column.build(item),
                      ),
                    ),
                  if (actions != null)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!(item),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  int? get _sortColumnIndex {
    if (sortField == null) return null;
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].sortField == sortField) return i;
    }
    return null;
  }

  DataColumn _buildColumn(BuildContext context, TableColumnSpec<T> column) {
    final sortable = column.sortField != null && onSort != null;
    return DataColumn(
      label: SizedBox(
        width: column.width,
        child: Text(
          column.label,
          textAlign: column.numeric ? TextAlign.right : TextAlign.left,
        ),
      ),
      numeric: column.numeric,
      onSort: sortable ? (_, _) => onSort!(column.sortField!) : null,
    );
  }
}
