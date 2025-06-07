import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../services/notification_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  AccelerometerEvent? _lastEvent;
  DateTime _lastShakeTime = DateTime.now();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double _result = 0;
  bool _hasConverted = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startAccelerometerListener();
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<CurrencyProvider>(context, listen: false);
    await provider.init();
  }

  void _startAccelerometerListener() {
    const double shakeThreshold = 15.0; // sensitivitas
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final now = DateTime.now();

      // Hitung perubahan (delta) gerakan
      if (_lastEvent != null) {
        double deltaX = event.x - _lastEvent!.x;
        double deltaY = event.y - _lastEvent!.y;
        double deltaZ = event.z - _lastEvent!.z;

        double delta =
            sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);

        if (delta > shakeThreshold &&
            now.difference(_lastShakeTime) > const Duration(seconds: 2)) {
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }

      _lastEvent = event;
    });
  }

  void _onShakeDetected() {
    setState(() {
      _amountController.clear();
      _hasConverted = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Input dikosongkan karena perangkat digerakkan')),
    );
  }

  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang ingin dikonversi')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid')),
      );
      return;
    }

    final provider = Provider.of<CurrencyProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final result = await provider.convertCurrency(
        amount,
        _fromCurrency,
        _toCurrency,
      );

      setState(() {
        _result = result;
        _hasConverted = true;
      });

      await NotificationHelper.showNotification(
        title: 'Konversi Berhasil',
        body: 'Jangan lupa lihat hasilnya',
      );

      if (authService.currentUser != null) {
        await provider.addToHistory(
          authService.currentUser!.id,
          _fromCurrency,
          _toCurrency,
          amount,
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _getFormattedTimes() {
    final now = DateTime.now().toUtc();

    final wib = now.add(const Duration(hours: 7));
    final wita = now.add(const Duration(hours: 8));
    final wit = now.add(const Duration(hours: 9));

    final formatter = DateFormat('HH:mm:ss');

    return '''
UTC : ${formatter.format(now)}\n
WIB : ${formatter.format(wib)}\n
WITA: ${formatter.format(wita)}\n
WIT : ${formatter.format(wit)}
''';
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _hasConverted = false;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Changer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<CurrencyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadLatestRates(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.currentRates != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Kurs Saat Ini',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Update: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(provider.currentRates!['date']))}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Base: ${provider.currentRates!['base']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Konversi Mata Uang',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.attach_money),
                              filled: true,
                              fillColor: Colors.green.withOpacity(0.05),
                            ),
                            onChanged: (_) => setState(() => _hasConverted = false),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _fromCurrency,
                                  decoration: InputDecoration(
                                    labelText: 'Dari',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.green.withOpacity(0.05),
                                  ),
                                  items: provider.supportedCurrencies
                                      .map((currency) => DropdownMenuItem(
                                            value: currency,
                                            child: Text(currency),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _fromCurrency = value;
                                        _hasConverted = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: IconButton(
                                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                                    onPressed: _swapCurrencies,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _toCurrency,
                                  decoration: InputDecoration(
                                    labelText: 'Ke',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.green.withOpacity(0.05),
                                  ),
                                  items: provider.supportedCurrencies
                                      .map((currency) => DropdownMenuItem(
                                            value: currency,
                                            child: Text(currency),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _toCurrency = value;
                                        _hasConverted = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _convertCurrency,
                              child: const Text('Konversi', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          if (_hasConverted) ...[
                            const SizedBox(height: 28),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Hasil Konversi:',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${NumberFormat.currency(locale: 'id_ID', symbol: _toCurrency).format(_result)}',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Waktu Saat Ini (Berbagai Zona):',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getFormattedTimes(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (provider.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        provider.error,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Penukaran Uang', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/exchange');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.feedback),
                      label: const Text('Kesan & Pesan', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/feedback');
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
