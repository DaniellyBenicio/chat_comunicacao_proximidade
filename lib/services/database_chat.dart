import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/message.dart';
import '../models/user.dart';

class DatabaseChat {
  static const String _dbName = 'chat_proximidade.db';
  static const int _dbVersion = 4;

  static Database? _database;
  static final DatabaseChat _instance = DatabaseChat._internal();
  factory DatabaseChat() => _instance;
  DatabaseChat._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpointId TEXT NOT NULL,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_endpoint ON messages(endpointId)');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        bluetoothName TEXT,
        bluetoothIdentifier TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS messages');
      await db.execute('DROP TABLE IF EXISTS users');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> insertMessage(Message message, String endpointId) async {
    final db = await database;

    await db.insert('messages', {
      'endpointId': endpointId,
      'sender': message.sender,
      'content': message.content,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Message>> getMessagesByEndpoint(String endpointId) async {
    final db = await database;

    final maps = await db.query(
      'messages',
      where: 'endpointId = ?',
      whereArgs: [endpointId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((m) => Message.fromMap(m)).toList();
  }

  Future<int> insertUser(User user) async {
    final db = await database;

    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);

    if (res.isNotEmpty) return User.fromMap(res.first);
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final res = await db.query('users');
    return res.map((m) => User.fromMap(m)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
