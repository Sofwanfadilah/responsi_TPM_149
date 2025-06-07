import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/database_helper.dart';

class CurrencyProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic>? _currentRates;
  List<Map<String, dynamic>> _exchangeHistory = [];

  // Daftar mata uang yang didukung (tidak bisa diubah karena final)
  final List<String> _supportedCurrencies = [
    'IDR', // Rupiah Indonesia
    'USD', // Dollar Amerika
    'EUR', // Euro
    'GBP', // Poundsterling Inggris
    'JPY', // Yen Jepang
    'AUD', // Dollar Australia
    'CAD', // Dollar Kanada
    'CHF', // Franc Swiss
    'CNY', // Yuan China
  ];

  // Getter untuk mengakses data
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, dynamic>? get currentRates => _currentRates;
  List<Map<String, dynamic>> get exchangeHistory => _exchangeHistory;
  List<String> get supportedCurrencies => _supportedCurrencies;

  // Inisialisasi data
  Future<void> init() async {
    await loadLatestRates();
  }

  // Memuat kurs mata uang terbaru
  Future<void> loadLatestRates() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );

      if (response.statusCode == 200) {
        _currentRates = json.decode(response.body);
        _error = '';
      } else {
        _error = 'Gagal memuat kurs mata uang: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan saat memuat kurs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Melakukan konversi mata uang
  Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (_currentRates == null) {
      throw Exception('Data kurs belum tersedia, silakan coba lagi');
    }

    final rates = _currentRates!['rates'] as Map<String, dynamic>;

    if (!rates.containsKey(fromCurrency) || !rates.containsKey(toCurrency)) {
      throw Exception(
          'Mata uang $fromCurrency atau $toCurrency tidak didukung');
    }

    final fromRate = rates[fromCurrency] as num;
    final toRate = rates[toCurrency] as num;

    final result = (amount / fromRate) * toRate;
    return double.parse(result.toStringAsFixed(2));
  }

  // Memuat riwayat konversi pengguna
  Future<void> loadUserExchangeHistory(String userId) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _exchangeHistory = await _db.getUserExchangeHistory(userId);
      _error = '';
    } catch (e) {
      _error = 'Gagal memuat riwayat konversi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menambah riwayat konversi baru
  Future<bool> addToHistory(
    String userId,
    String fromCurrency,
    String toCurrency,
    double amount,
    double result,
  ) async {
    try {
      final history = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'amount': amount,
        'result': result,
        'date': DateTime.now().toIso8601String(),
      };

      final success = await _db.addExchangeHistory(userId, history);
      if (success) {
        await loadUserExchangeHistory(userId);
      }
      return success;
    } catch (e) {
      _error = 'Gagal menyimpan riwayat konversi: $e';
      notifyListeners();
      return false;
    }
  }

  // Mengupdate mata uang pilihan pengguna
  Future<void> updateUserPreferredCurrency(
      String userId, String currency) async {
    try {
      await _db.updateUserPreferredCurrency(userId, currency);
      await loadLatestRates();
    } catch (e) {
      _error = 'Gagal mengubah mata uang utama: $e';
      notifyListeners();
    }
  }

  // Mendapatkan nilai tukar antara dua mata uang
  double? getExchangeRate(String from, String to) {
    try {
      if (_currentRates == null) return null;
      if (from == to) return 1.0;

      final rates = _currentRates!['rates'] as Map<String, dynamic>;

      if (from == _currentRates!['base']) {
        return (rates[to] as num).toDouble();
      } else if (to == _currentRates!['base']) {
        return 1 / ((rates[from] as num?) ?? 0).toDouble();
      } else {
        final fromRate = rates[from] as num?;
        final toRate = rates[to] as num?;
        if (fromRate == null || toRate == null) return null;
        return (toRate / fromRate).toDouble();
      }
    } catch (e) {
      _error = 'Gagal mendapatkan nilai tukar: $e';
      return null;
    }
  }

  // Membersihkan pesan error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
