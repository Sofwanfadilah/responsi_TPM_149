import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  Position? _currentPosition;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
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
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Penukaran Uang'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Form Penukaran Uang',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                            if (value != null) setState(() => _fromCurrency = value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                final temp = _fromCurrency;
                                _fromCurrency = _toCurrency;
                                _toCurrency = temp;
                              });
                            },
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
                            if (value != null) setState(() => _toCurrency = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : _submitExchange,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Tukar Sekarang', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Lokasi Anda Saat Ini:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 250,
                      child: _currentPosition == null
                          ? const Center(child: CircularProgressIndicator())
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('currentLocation'),
                                  position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                                ),
                              },
                              onMapCreated: (controller) => _mapController = controller,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: false,
                              mapType: MapType.normal,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
