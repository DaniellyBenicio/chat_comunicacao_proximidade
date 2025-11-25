import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_de_conversa/services/database_chat.dart';
import 'package:chat_de_conversa/services/nearby_service.dart';     
import 'package:chat_de_conversa/views/home_screen.dart';
import 'package:chat_de_conversa/views/login.dart';
import 'package:chat_de_conversa/controllers/auth_controller.dart';
import 'package:chat_de_conversa/components/nav_bar.dart';
import 'package:chat_de_conversa/providers/theme_provider.dart';
import 'package:chat_de_conversa/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseChat().database;

  runApp(const ChatProximidadeApp());
}

class ChatProximidadeApp extends StatefulWidget {
  const ChatProximidadeApp({super.key});

  @override
  State<ChatProximidadeApp> createState() => _ChatProximidadeAppState();
}

class _ChatProximidadeAppState extends State<ChatProximidadeApp> {
  Widget _initialScreen = const Scaffold(
    body: Center(
      child: CircularProgressIndicator(color: Color(0xFF004E89)),
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkInitialFlow();
  }

  Future<void> _checkInitialFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

      if (!hasCompletedOnboarding) {
        setState(() {
          _initialScreen = const HomeScreen();
        });
        return;
      }

      final authController = AuthController();
      final bool isLoggedIn = await authController.isLoggedIn();

      if (isLoggedIn) {
        final savedCredentials = await authController.getSavedCredentials();
        if (savedCredentials != null) {
          final result = await authController.loginUser(
            email: savedCredentials['email']!,
            password: savedCredentials['password']!,
            rememberMe: true,
          );

          if (result['success']) {
            final userName = result['name'] ?? 'Usuário';
            setState(() {
              _initialScreen = BottomNavBar(userName: userName);
            });
            return;
          }
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NearbyService()),  
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'GeoTalk',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _initialScreen,
          );
        },
      ),
    );
  }
}