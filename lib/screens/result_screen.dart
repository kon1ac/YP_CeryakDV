import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../widgets/page_body.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.title,
    required this.expression,
    required this.uri,
    required this.backPath,
    required this.backLabel,
    this.value,
    this.error,
  });

  final String title;
  final String expression;
  final Uri uri;
  final String backPath;
  final String backLabel;
  final String? value;
  final String? error;

  bool get isError => error != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [ThemeButton()],
      ),
      body: PageBody(
        maxWidth: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expression, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(
                      isError ? error! : value!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Параметры из адреса', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(
              uri.toString(),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(backPath),
              child: Text(backLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
