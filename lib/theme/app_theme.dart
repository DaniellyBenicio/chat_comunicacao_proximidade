import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    primaryColor: const Color(0xFF004E89),
    secondaryHeaderColor: const Color(0xFF000000),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF004E89),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    useMaterial3: true,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF004E89),
      unselectedItemColor: Colors.grey,
    ),
  );

  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF004E89),
    secondaryHeaderColor: const Color(0xFFFFFFFF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF004E89),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF004E89),
      unselectedItemColor: Colors.grey,
    ),
  );
}
