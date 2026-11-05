import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/calculator.dart';
import '../logic/numbers.dart';
import '../logic/validators.dart';
import '../theme.dart';
import '../widgets/page_body.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  String _operation = operations.first;

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final a = parseNumber(_aController.text)!;
    final b = parseNumber(_bController.text)!;

    context.go(
      '/calculator/result'
      '?a=$a'
      '&op=${Uri.encodeComponent(_operation)}'
      '&b=$b',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        actions: const [ThemeButton()],
      ),
      body: PageBody(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _aController,
                decoration: const InputDecoration(
                  labelText: 'Первое число',
                  border: OutlineInputBorder(),
                ),
                validator: V.number(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _operation,
                decoration: const InputDecoration(
                  labelText: 'Операция',
                  border: OutlineInputBorder(),
                ),
                items: operations
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _operation = value ?? operations.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bController,
                decoration: const InputDecoration(
                  labelText: 'Второе число',
                  border: OutlineInputBorder(),
                ),
                validator: V.number(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Text('Вычислить'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
