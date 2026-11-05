import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/currency.dart';
import '../logic/numbers.dart';
import '../logic/validators.dart';
import '../prefs.dart';
import '../theme.dart';
import '../widgets/page_body.dart';

const _fromKey = 'converter_from';
const _toKey = 'converter_to';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    final prefs = AppPrefs.instance;
    _from = currencyByCode(prefs.getString(_fromKey)) != null
        ? prefs.getString(_fromKey)!
        : currencies.first.code;
    _to = currencyByCode(prefs.getString(_toKey)) != null
        ? prefs.getString(_toKey)!
        : currencies[1].code;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseNumber(_amountController.text)!;

    context.go('/converter/result?amount=$amount&from=$_from&to=$_to');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертер валют'),
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
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                ),
                validator: V.number(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _from,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Из валюты',
                  border: OutlineInputBorder(),
                ),
                items: _items(),
                onChanged: (value) => setState(() {
                  _from = value ?? currencies.first.code;
                  AppPrefs.instance.setString(_fromKey, _from);
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _to,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'В валюту',
                  border: OutlineInputBorder(),
                ),
                items: _items(),
                onChanged: (value) => setState(() {
                  _to = value ?? currencies[1].code;
                  AppPrefs.instance.setString(_toKey, _to);
                }),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Text('Перевести'),
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

  List<DropdownMenuItem<String>> _items() {
    return currencies
        .map(
          (c) => DropdownMenuItem(
            value: c.code,
            child: Text(
              '${c.code} — ${c.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }
}
