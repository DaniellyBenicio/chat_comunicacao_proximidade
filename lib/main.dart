import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_de_conversa/services/database_chat.dart';
import 'package:chat_de_conversa/services/bluetooth_service.dart';
import 'package:chat_de_conversa/views/home_screen.dart';
import 'package:chat_de_conversa/views/login.dart';
import 'package:chat_de_conversa/controllers/auth_controller.dart';
// Importação do seu menu inferior
import 'package:chat_de_conversa/widgets/nav_bar.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseChat();
  await dbHelper.database;

  runApp(const ChatProximidadeApp());
}

class ChatProximidadeApp extends StatefulWidget {
  const ChatProximidadeApp({super.key});

  @override
  State<ChatProximidadeApp> createState() => _ChatProximidadeAppState();
}

class _ChatProximidadeAppState extends State<ChatProximidadeApp> {
  // Variável de estado para a tela inicial
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFF004E89))),
  );

  @override
  void initState() {
    super.initState();
    _checkInitialFlow();
  }

  Future<void> _checkInitialFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasCompletedOnboarding =
          prefs.getBool('onboarding_completed') ?? false;

      if (!hasCompletedOnboarding) {
        setState(() {
          _initialScreen = const HomeScreen();
        });
        return;
      }

      final authController = AuthController();
      final savedCredentials = await authController.getSavedCredentials();

      if (savedCredentials != null) {
        final email = savedCredentials['email']!;
        final password = savedCredentials['password']!;

        final result = await authController.loginUser(
          email: email,
          password: password,
          rememberMe: true,
        );

        if (result['success']) {
          final userName = result['name'] ?? 'Usuário';
          setState(() {
            // CORRIGIDO: Usando '_initialScreen' e 'BottomNavBar'
            _initialScreen = BottomNavBar(userName: userName); 
          });
          return;
        }
      }

      setState(() {
        _initialScreen = const Login();
      });
    } catch (e) {
      print('Erro ao verificar fluxo inicial: $e');
      setState(() {
        _initialScreen = const Login();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BluetoothService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GeoTalk',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF7F9FC),
          primaryColor: const Color(0xFF004E89),
          secondaryHeaderColor: const Color(0xFF000000),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004E89)),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: _initialScreen,
      ),
    );
  }
}