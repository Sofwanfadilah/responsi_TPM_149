import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/currency_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/exchange_screen.dart';
import 'services/auth_service.dart';
import 'services/database_helper.dart';
import 'services/notification_helper.dart';
import 'screens/feedback_screen.dart';

void main() async {
  // Pastikan binding Flutter diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  await _requestNotificationPermission();
  await NotificationHelper.init();
  // Inisialisasi SQLite untuk Windows
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    // Inisialisasi sqflite_common_ffi
    sqfliteFfiInit();
    // Set databaseFactory global
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database and auth service
  final dbHelper = DatabaseHelper();
  await dbHelper.initDatabase(); // Pastikan database diinisialisasi
  final authService = AuthService(dbHelper);
  await authService.init();

  runApp(MyApp(authService: authService));
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(),
        ),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: MaterialApp(
        title: 'Money Changer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            primary: Colors.green,
            secondary: Colors.greenAccent,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => authService.currentUser != null
              ? const HomeScreen()
              : const LoginScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/history': (context) => const HistoryScreen(),
          '/exchange': (context) => const ExchangeScreen(),
          '/feedback': (context) => const FeedbackScreen(), // route baru
        },
      ),
    );
  }
}
