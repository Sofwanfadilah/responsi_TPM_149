import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String dbName = 'money_changer.db';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      final String path = join(await getDatabasesPath(), dbName);

      // Hapus database lama jika ada
      await deleteDatabase(path);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
  CREATE TABLE users(
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT DEFAULT '',
    age INTEGER DEFAULT 0,
    country TEXT DEFAULT '',
    preferred_currency TEXT DEFAULT 'IDR',
    photo_url TEXT DEFAULT ''
  )
''');

    await db.execute('''
      CREATE TABLE exchange_history(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        from_currency TEXT NOT NULL,
        to_currency TEXT NOT NULL,
        amount REAL NOT NULL,
        result REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<User?> getUser(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return User.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (maps.isEmpty) return null;
      return User.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  Future<bool> createUser(User user) async {
    try {
      final db = await database;

      // Cek apakah username sudah ada
      final existingUser = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [user.username],
      );

      if (existingUser.isNotEmpty) {
        throw Exception('Username sudah digunakan');
      }

      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final db = await database;
      final count = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return count > 0;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final db = await database;
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserExchangeHistory(
      String userId) async {
    try {
      final db = await database;
      return await db.query(
        'exchange_history',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
    } catch (e) {
      debugPrint('Error getting exchange history: $e');
      return [];
    }
  }

  Future<bool> addExchangeHistory(
      String userId, Map<String, dynamic> history) async {
    try {
      final db = await database;
      history['user_id'] = userId;
      await db.insert(
        'exchange_history',
        history,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Error adding exchange history: $e');
      return false;
    }
  }

  Future<bool> updateUserPreferredCurrency(
      String userId, String currency) async {
    try {
      final db = await database;
      final count = await db.update(
        'users',
        {'preferred_currency': currency},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      debugPrint('Error updating preferred currency: $e');
      return false;
    }
  }

  Future<String?> getUserPreferredCurrency(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        columns: ['preferred_currency'],
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isNotEmpty) {
        return result.first['preferred_currency'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting preferred currency: $e');
      return null;
    }
  }
}
