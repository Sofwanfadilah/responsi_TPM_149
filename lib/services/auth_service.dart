import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';

class AuthService extends ChangeNotifier {
  final DatabaseHelper _db;
  User? _currentUser;
  static SharedPreferences? _prefs;
  String _error = '';

  User? get currentUser => _currentUser;
  String get error => _error;

  AuthService(this._db);

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await checkAuthStatus();
    } catch (e) {
      _error = 'Gagal menginisialisasi aplikasi: $e';
      debugPrint(_error);
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final userId = _prefs?.getString('userId');
      if (userId != null) {
        final user = await _db.getUser(userId);
        if (user != null) {
          _currentUser = user;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Gagal memeriksa status login: $e';
      debugPrint(_error);
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username dan password harus diisi');
      }

      if (username.length < 3) {
        throw Exception('Username minimal 3 karakter');
      }

      if (password.length < 6) {
        throw Exception('Password minimal 6 karakter');
      }

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username.trim(),
        password: password,
        name: '',
        age: 0,
        country: '',
      );

      final success = await _db.createUser(user);
      if (success) {
        _currentUser = user;
        await _prefs?.setString('userId', user.id);
        _error = '';
        notifyListeners();
        return true;
      }
      throw Exception('Gagal membuat akun');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error during registration: $_error');
      rethrow;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username dan password harus diisi');
      }

      final users = await _db.database;
      final result = await users.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username.trim(), password],
      );

      if (result.isNotEmpty) {
        _currentUser = User.fromMap(result.first);
        await _prefs?.setString('userId', _currentUser!.id);
        _error = '';
        notifyListeners();
        return true;
      }
      throw Exception('Username atau password salah');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error during login: $_error');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _prefs?.remove('userId');
      _currentUser = null;
      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Gagal logout: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    int? age,
    String? country,
    String? preferredCurrency,
    String? photoUrl,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('Tidak ada user yang login');
      }

      final updatedUser = _currentUser!.copyWith(
        name: name,
        age: age,
        country: country,
        preferredCurrency: preferredCurrency,
         photoUrl: photoUrl,
      );

      final success = await _db.updateUser(updatedUser);
      if (success) {
        _currentUser = updatedUser;
        _error = '';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Gagal memperbarui profil: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
