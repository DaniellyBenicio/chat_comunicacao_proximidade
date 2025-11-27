import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_de_conversa/providers/theme_provider.dart';
import 'package:chat_de_conversa/views/login.dart';
import 'package:chat_de_conversa/controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final authController = AuthController();
    await authController.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        centerTitle: true,
        elevation: 2,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF004E89),
        foregroundColor: Colors.white,
        toolbarHeight: 90,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Modo Escuro'),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Ativado' : 'Desativado',
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versão do App'),
            subtitle: const Text('1.0.0'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
