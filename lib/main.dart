import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importações de Vistas e Serviços
import 'views/tela_inicial.dart';
import 'views/login.dart';
import 'services/databaseChat.dart';

// -------------------------------------------------------------
// IMPORTAÇÕES PARA INICIALIZAÇÃO UNIVERSAL DO SQLITE (CORREÇÃO)
// -------------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqflite.dart'; // Para databaseFactory
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
// -------------------------------------------------------------

void setupDatabaseFactory() {
  if (kIsWeb) {
    // Para Flutter Web (Chrome), define o factory para usar IndexedDB
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('Database Factory configurado para WEB (IndexedDB).');
  } else {
    // Para Nativo (Android, iOS, Desktop), inicializa e define o factory FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('Database Factory configurado para NATIVO (FFI).');
  }
}

void main() async {
  // Garante que o binding do Flutter esteja inicializado antes de qualquer chamada assíncrona.
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // CORREÇÃO: Chama a configuração do motor SQLite antes de qualquer operação assíncrona.
  setupDatabaseFactory();

  // 1. Inicializa o serviço de banco de dados universal. 
  // O getter .database irá chamar o _initDb, que agora encontra o motor SQLite configurado.
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
    final bool hasCompletedOnboarding =
        prefs.getBool('onboarding_completed') ?? false;

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
        secondaryHeaderColor: const Color(0xFF000000),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004E89)),

        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: _initialScreen,
    );
  }
}
