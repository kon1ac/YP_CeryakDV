import 'package:go_router/go_router.dart';

import 'logic/calculator.dart';
import 'logic/currency.dart';
import 'logic/numbers.dart';
import 'screens/calculator_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/result_screen.dart';


GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final result = calculate(q['a'], q['op'], q['b']);
              return ResultScreen(
                title: 'Результат вычисления',
                expression: '${q['a'] ?? '—'} ${q['op'] ?? '?'} '
                    '${q['b'] ?? '—'} =',
                uri: state.uri,
                backPath: '/calculator',
                backLabel: 'Изменить числа',
                value: switch (result) {
                  CalcSuccess(:final value) => formatNumber(value),
                  CalcFailure() => null,
                },
                error: switch (result) {
                  CalcSuccess() => null,
                  CalcFailure(:final message) => message,
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/converter',
        builder: (context, state) => const ConverterScreen(),
        routes: [
          GoRoute(
            path: 'result',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final result = convert(q['amount'], q['from'], q['to']);
              final from = currencyByCode(q['from']);
              final to = currencyByCode(q['to']);
              return ResultScreen(
                title: 'Результат конвертации',
                expression: '${q['amount'] ?? '—'} '
                    '${from?.code ?? q['from'] ?? '?'} → '
                    '${to?.code ?? q['to'] ?? '?'}',
                uri: state.uri,
                backPath: '/converter',
                backLabel: 'Изменить сумму',
                value: switch (result) {
                  ConversionSuccess(:final value) => formatNumber(value),
                  ConversionFailure() => null,
                },
                error: switch (result) {
                  ConversionSuccess() => null,
                  ConversionFailure(:final message) => message,
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

final appRouter = buildRouter();
