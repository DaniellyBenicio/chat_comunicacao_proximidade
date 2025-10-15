import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tela_inicial.dart';

void main() {
  runApp(const ChatProximidadeApp());
}

class ChatProximidadeApp extends StatelessWidget {
  const ChatProximidadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeoTalk',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        primaryColor: const Color(0xFF004E89),
        textTheme: GoogleFonts.poppinsTextTheme(), 
      ),
      home: const TelaInicialApp(),
    );
  }
}
