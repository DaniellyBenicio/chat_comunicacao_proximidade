import '../models/user.dart';
import 'user_controller.dart'; 
import 'dart:developer';

class AuthController {
  final UserController _userController = UserController();

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    
    final String bluetoothIdentifier = 'DEV_ID_${DateTime.now().microsecondsSinceEpoch}';

    if (password != confirmPassword) {
      return {'success': false, 'message': 'As senhas não coincidem.'};
    }
  
    if (password.length < 6) {
      return {'success': false, 'message': 'A senha deve ter pelo menos 6 caracteres.'};
    }
  
    final existingUser = await _userController.getUserByEmail(email);
    if (existingUser != null) {
      return {'success': false, 'message': 'Este e-mail já está em uso.'};
    }
    

    final newUser = User(
      email: email,
      password: password, 
      name: name,
      bluetoothIdentifier: bluetoothIdentifier, 
      bluetoothName: null, 
    );

    try {
      final id = await _userController.insertUser(newUser);

      if (id > 0) {
        final users = await _userController.getAllUsers();
        log('--- USUÁRIOS NO DB APÓS CADASTRO (DEBUG) ---');
        for (var user in users) {
          log('ID: ${user.id}, Nome: ${user.name}, Email: ${user.email}, BT ID: ${user.bluetoothIdentifier}');
        }
        log('-------------------------------------------');
       
        return {
          'success': true, 
          'message': 'Usuário cadastrado com sucesso!',
        };
      } else {
        return {'success': false, 'message': 'Falha ao salvar o usuário no banco de dados.'};
      }
    } catch (e) {
      log("Erro durante o registro: $e");
      return {'success': false, 'message': 'Ocorreu um erro inesperado durante o registro.'};
    }
  }

}
