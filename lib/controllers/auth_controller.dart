import '../models/user.dart';
import 'user_controller.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final UserController _userController = UserController();

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'E-mail ou senha não podem estar vazios.',
      };
    }

    try {
      final user = await _userController.getUserByEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        if (rememberMe) {
          await _saveCredentials(email, password);
          log('Credenciais salvas com sucesso.');
        } else {
          await _clearCredentials();
          log('Credenciais removidas (Lembrar-me desativado).');
        }

        log('Usuário logado com sucesso: ${user.email}');
        return {
          'success': true,
          'message': 'Login realizado com sucesso!',
          'name': user.name,
        };
      } else {
        return {'success': false, 'message': 'E-mail ou senha inválidos.'};
      }
    } catch (e) {
      log("Erro durante o login: $e");
      return {
        'success': false,
        'message': 'Ocorreu um erro inesperado durante o login.',
      };
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final String bluetoothIdentifier =
        'DEV_ID_${DateTime.now().microsecondsSinceEpoch}';

    if (password != confirmPassword) {
      return {'success': false, 'message': 'As senhas não coincidem.'};
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'A senha deve ter pelo menos 6 caracteres.',
      };
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
          log(
            'ID: ${user.id}, Nome: ${user.name}, Email: ${user.email}, BT ID: ${user.bluetoothIdentifier}',
          );
        }
        log('-------------------------------------------');

        return {'success': true, 'message': 'Usuário cadastrado com sucesso!'};
      } else {
        return {
          'success': false,
          'message': 'Falha ao salvar o usuário no banco de dados.',
        };
      }
    } catch (e) {
      log("Erro durante o registro: $e");
      return {
        'success': false,
        'message': 'Ocorreu um erro inesperado durante o registro.',
      };
    }
  }
}
