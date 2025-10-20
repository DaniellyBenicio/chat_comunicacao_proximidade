import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class DatabaseChat {
  static const String _databaseName = 'chat_proximidade.db';
  static const int _databaseVersion = 1;

  static Database? _db;

  static final DatabaseChat _instance = DatabaseChat._internal();
  factory DatabaseChat() => _instance;
  DatabaseChat._internal();

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, _databaseName);
      logger.i('Inicializando banco de dados em: $path');

      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: (db, version) async {
          logger.i('Criando tabelas...');
          await db.execute('''
            CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender TEXT NOT NULL,
              content TEXT NOT NULL,
              timestamp TEXT DEFAULT (datetime('now'))
            )
          ''');

          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL,
              name TEXT NOT NULL,
              bluetoothName TEXT,
              bluetoothIdentifier TEXT NOT NULL UNIQUE
            )
          ''');
          logger.i('Tabelas criadas com sucesso!');
        },
        onOpen: (db) {
          logger.i('Banco de dados aberto com sucesso.');
        },
      );
      return db;
    } catch (e) {
      logger.e('Erro ao inicializar o banco de dados: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      logger.i('Banco de dados fechado.');
    }
  }
}
