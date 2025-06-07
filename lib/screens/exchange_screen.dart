import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitExchange() async {
    final provider = Provider.of<CurrencyProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await provider.convertCurrency(amount, _fromCurrency, _toCurrency);
      // Simpan ke history jika user login
      if (authService.currentUser != null) {
        await provider.addToHistory(
          authService.currentUser!.id,
          _fromCurrency,
          _toCurrency,
          amount,
          result,
        );
      }
      // Generate PDF invoice
      final pdf = pw.Document();
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE PENUKARAN UANG', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Tanggal: ${formatter.format(now)}'),
              if (authService.currentUser != null)
                pw.Text('User: ${authService.currentUser!.username}'),
              pw.SizedBox(height: 16),
              pw.Text('Dari: $_fromCurrency'),
              pw.Text('Ke: $_toCurrency'),
              pw.Text('Jumlah: $amount'),
              pw.Text('Hasil: $result $_toCurrency'),
            ],
          ),
        ),
      );
      // Tampilkan dialog print/share PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'invoice_penukaran_uang.pdf',
      );
      // Notifikasi sukses
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sukses'),
            content: const Text('Penukaran berhasil dan invoice PDF telah dibuat!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CurrencyProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penukaran Uang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Dari',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.supportedCurrencies
                        .map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _fromCurrency = value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    setState(() {
                      final temp = _fromCurrency;
                      _fromCurrency = _toCurrency;
                      _toCurrency = temp;
                    });
                  },
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Ke',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.supportedCurrencies
                        .map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _toCurrency = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitExchange,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Tukar Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
