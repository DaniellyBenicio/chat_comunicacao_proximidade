import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'tela_inicial.dart'; 
import 'login.dart'; 

void main() {
  runApp(const ChatProximidadeApp());
}

class ChatProximidadeApp extends StatefulWidget {
  const ChatProximidadeApp({super.key});

  @override
  State<ChatProximidadeApp> createState() => _ChatProximidadeAppState();
}

class _ChatProximidadeAppState extends State<ChatProximidadeApp> {
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFF004E89))),
  );

  @override
  void initState() {
    super.initState();
    _checkInitialFlow();
  }

  Future<void> _checkInitialFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

    setState(() {
      if (hasCompletedOnboarding) {
        _initialScreen = const Login();
      } else {
        _initialScreen = const TelaInicialApp();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeoTalk',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        primaryColor: const Color(0xFF004E89), 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004E89)), // Boa prática
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: _initialScreen,
    );
  }
}