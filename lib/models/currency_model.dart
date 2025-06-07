import 'dart:convert';

class CurrencyRate {
  final String base;
  final String date;
  final Map<String, double> rates;

  CurrencyRate({
    required this.base,
    required this.date,
    required this.rates,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      base: json['base'] as String,
      date: json['date'] as String,
      rates: Map<String, double>.from(json['rates'] as Map),
    );
  }

  double? getRate(String currency) {
    if (currency == base) return 1.0;
    return rates[currency];
  }

  double convert(double amount, String from, String to) {
    if (from == base && rates.containsKey(to)) {
      return amount * rates[to]!;
    } else if (rates.containsKey(from) && rates.containsKey(to)) {
      // Convert through base currency
      double amountInBase = amount / rates[from]!;
      return amountInBase * rates[to]!;
    }
    throw Exception('Invalid currency pair');
  }
}

class ExchangeHistory {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double result;
  final String date;

  ExchangeHistory({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.result,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'amount': amount,
      'result': result,
      'date': date,
    };
  }

  factory ExchangeHistory.fromMap(Map<String, dynamic> map) {
    return ExchangeHistory(
      id: map['id'] as String,
      fromCurrency: map['from_currency'] as String,
      toCurrency: map['to_currency'] as String,
      amount: map['amount'] as double,
      result: map['result'] as double,
      date: map['date'] as String,
    );
  }
}
