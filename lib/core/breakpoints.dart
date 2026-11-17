import 'package:flutter/material.dart';

/// Точки перелома вёрстки (Material-подобные).
abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;

  /// Таблица ↔ карточки в списках каталога.
  static const double table = compact;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isCompact(BuildContext context) =>
      sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) {
    final width = sizeOf(context).width;
    return width >= compact && width < medium;
  }

  static bool isExpanded(BuildContext context) =>
      sizeOf(context).width >= medium;

  /// Ширина поля фильтра: на узком — почти на весь экран, иначе preferred.
  static double filterFieldWidth(
    BuildContext context, {
    double preferred = 190,
    double horizontalInset = 32,
  }) {
    if (isCompact(context)) {
      return (sizeOf(context).width - horizontalInset).clamp(120.0, 600.0);
    }
    return preferred;
  }
}
