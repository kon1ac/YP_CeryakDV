import 'package:flutter/material.dart';

import '../widgets/auth_menu_button.dart';
import '../widgets/list_nav_bar.dart';

/// Заглушка списка до появления полного CRUD.
class PlaceholderListScreen extends StatelessWidget {
  const PlaceholderListScreen({
    super.key,
    required this.title,
    required this.active,
    this.bodyText,
  });

  final String title;
  final ListDestination active;
  final String? bodyText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [AuthMenuButton()],
      ),
      bottomNavigationBar: ListNavBar(active: active),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            bodyText ?? 'Раздел «$title» будет доступен в следующих итерациях.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
