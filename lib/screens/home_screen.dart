import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../widgets/page_body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: const [ThemeButton()],
      ),
      body: PageBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Калькулятор и конвертер валют',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите раздел. Результат открывается на отдельной странице, '
              'его адрес можно скопировать и открыть в новой вкладке.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/calculator'),
              icon: const Icon(Icons.calculate),
              label: const Text('Калькулятор'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/converter'),
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Конвертер валют'),
            ),
          ],
        ),
      ),
    );
  }
}
