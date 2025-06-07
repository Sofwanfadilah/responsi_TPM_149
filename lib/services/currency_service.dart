import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_model.dart';

class CurrencyService {
  static const String _baseUrl = 'https://api.frankfurter.app';

  Future<List<String>> getSupportedCurrencies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/currencies'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.keys.toList();
      } else {
        throw Exception('Gagal memuat daftar mata uang');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  Future<CurrencyRate> getLatestRates({String base = 'IDR'}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/latest?from=$base'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CurrencyRate.fromJson(data);
      } else {
        throw Exception('Gagal memuat kurs terbaru');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  Future<CurrencyRate> convertCurrency(
    double amount,
    String from,
    String to,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest?amount=$amount&from=$from&to=$to'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CurrencyRate.fromJson(data);
      } else {
        throw Exception('Gagal melakukan konversi mata uang');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  Future<Map<String, double>> getHistoricalRates(
    String date, {
    String base = 'EUR',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$date?base=$base'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, double>.from(data['rates']);
      } else {
        throw Exception('Failed to load historical rates');
      }
    } catch (e) {
      throw Exception('Error fetching historical rates: $e');
    }
  }
}
