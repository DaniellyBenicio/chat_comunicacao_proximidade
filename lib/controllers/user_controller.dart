import 'package:sqflite_common/sqflite.dart'; 
import '../models/user.dart';
import '../services/database_chat.dart'; 

class UserController {
  final DatabaseChat _dbProvider = DatabaseChat();
  

  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await _dbProvider.database;
    
    
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?', // Busca por email E senha
      whereArgs: [email, password],
      limit: 1, // Limita a busca 
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    final db = await _dbProvider.database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByBluetoothId(String identifier) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'users',
      where: 'bluetoothIdentifier = ?',
      whereArgs: [identifier],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<int> updateUser(User user) async {
    if (user.id == null) {
      throw Exception("O ID do utilizador é obrigatório para a atualização.");
    }
    
    final db = await _dbProvider.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await _dbProvider.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
