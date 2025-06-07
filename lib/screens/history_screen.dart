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
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
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
              padding: const EdgeInsets.all(8),
              itemCount: provider.exchangeHistory.length,
              itemBuilder: (context, index) {
                final history = provider.exchangeHistory[index];
                final date = DateTime.parse(history['date']);
                final amount = history['amount'] as double;
                final result = history['result'] as double;
                final fromCurrency = history['from_currency'];
                final toCurrency = history['to_currency'];

                return Card(
                  child: ListTile(
                    title: Text(
                      '${NumberFormat.currency(locale: 'id_ID', symbol: fromCurrency).format(amount)} → ${NumberFormat.currency(locale: 'id_ID', symbol: toCurrency).format(result)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy HH:mm').format(date),
                    ),
                    trailing: Text(
                      'Rate: ${(result / amount).toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
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
