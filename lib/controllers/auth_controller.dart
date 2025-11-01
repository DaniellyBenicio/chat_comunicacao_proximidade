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
    await prefs.setBool('remember_me', true);
    log('Credenciais salvas + remember_me = true');
  }

  Future<void> _setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', value);
  }

  Future<void> logout() async {
    await _setLoggedIn(false);
    log('Logout: sessão encerrada, credenciais mantidas');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
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
      final user = await _userController.getUserByEmailAndPassword(email, password);

      if (user != null) {
        if (rememberMe) {
          await _saveCredentials(email, password);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }

        await _setLoggedIn(true); 

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