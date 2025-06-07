import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);

    if (authService.currentUser != null) {
      await currencyProvider
          .loadUserExchangeHistory(authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Konversi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CurrencyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error,
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    onPressed: _loadHistory,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (provider.exchangeHistory.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat konversi'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.exchangeHistory.length,
              itemBuilder: (context, index) {
                final history = provider.exchangeHistory[index];
                final date = DateTime.parse(history['date']);
                final amount = history['amount'] as double;
                final result = history['result'] as double;
                final fromCurrency = history['from_currency'];
                final toCurrency = history['to_currency'];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    title: Text(
                      '${NumberFormat.currency(locale: 'id_ID', symbol: fromCurrency).format(amount)} → ${NumberFormat.currency(locale: 'id_ID', symbol: toCurrency).format(result)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy HH:mm').format(date),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rate: ${(result / amount).toStringAsFixed(4)}',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
