import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:flutter/foundation.dart'; 
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; 


import '../models/message.dart';
import '../models/user.dart';

class DatabaseChat {
  static const String _databaseName = 'chat_proximidade.db';
  static const int _databaseVersion = 1;

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;

  }

  DatabaseFactory get _databaseFactory {

    if (kIsWeb) {
      debugPrint('Usando factory Web (IndexedDB) para persistência.');
      return databaseFactoryFfiWeb;
    }
    debugPrint('Usando factory FFI (Nativo) para persistência.');
    return databaseFactoryFfi;

  }

  Future<Database> _initDb() async {

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    final db = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          debugPrint('Criando tabelas...');


          await db.execute('''
            CREATE TABLE messages(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender TEXT NOT NULL,
              content TEXT NOT NULL,
              timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL,
              name TEXT NOT NULL,
              bluetoothName TEXT,
              bluetoothIdentifier TEXT NOT NULL UNIQUE
            )
          ''');
          debugPrint('Tabelas criadas com sucesso!');
        },
      )
    );
    return db;
  }

  Future<int> insertUser(User user) async {

    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  }
  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });

  }

}