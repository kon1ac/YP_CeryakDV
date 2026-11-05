import 'numbers.dart';

class Currency {
  final String code;
  final String name;
  final double rateToRub;

  const Currency(this.code, this.name, this.rateToRub);
}

const currencies = <Currency>[
  Currency('RUB', 'Российский рубль', 1),
  Currency('USD', 'Доллар США', 92.5),
  Currency('EUR', 'Евро', 100.2),
  Currency('CNY', 'Китайский юань', 12.8),
  Currency('KZT', 'Казахстанский тенге', 0.19),
  Currency('BYN', 'Белорусский рубль', 28.4),
];

Currency? currencyByCode(String? code) {
  for (final currency in currencies) {
    if (currency.code == code) return currency;
  }
  return null;
}

sealed class ConversionResult {
  const ConversionResult();
}

class ConversionSuccess extends ConversionResult {
  final double value;
  const ConversionSuccess(this.value);
}

class ConversionFailure extends ConversionResult {
  final String message;
  const ConversionFailure(this.message);
}

ConversionResult convert(String? rawAmount, String? fromCode, String? toCode) {
  final amount = parseNumber(rawAmount);
  if (amount == null) {
    return const ConversionFailure('В адресе передана не сумма');
  }

  final from = currencyByCode(fromCode);
  final to = currencyByCode(toCode);
  if (from == null || to == null) {
    return const ConversionFailure('Неизвестная валюта');
  }

  return ConversionSuccess(amount * from.rateToRub / to.rateToRub);
}
