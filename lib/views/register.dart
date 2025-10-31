import 'package:flutter/material.dart';
import 'package:chat_de_conversa/views/login.dart';
import '../controllers/auth_controller.dart'; 

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthController _authController = AuthController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10.0, 
          ),
          child: Material(
            elevation: 6.0, 
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                minWidth: 200.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red[700]
                    : Colors.green[700]!.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('As senhas não coincidem.', isError: true);
      return;
    }
    

    setState(() {
      _isLoading = true;
    });

    final result = await _authController.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      _showSnackBar(result['message']);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    } else {
      _showSnackBar(result['message'] ?? 'Erro desconhecido ao cadastrar.', isError: true);
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).secondaryHeaderColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Criar Conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Crie sua conta para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    _validateRequired(value, 'Nome');
                    if (value!.trim().length < 3) {
                      return 'O nome deve ter no mínimo 3 caracteres.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    _validateRequired(value, 'E-mail');
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value!)) {
                      return 'O e-mail fornecido não é válido.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Senha é obrigatória.';
                    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres.';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value != _passwordController.text) return 'As senhas não coincidem.';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: Icon(Icons.lock_reset, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement( 
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: Text(
                    'Já tenho uma conta',
                    style: TextStyle(
                      color: Theme.of(context).secondaryHeaderColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}