import 'package:flutter/material.dart';

class CheckedMenuItem extends PopupMenuItem<String> {
  CheckedMenuItem({
    super.key,
    required super.value,
    required String text,
    required bool checked,
  }) : super(
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        );
}
