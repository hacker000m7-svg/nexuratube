import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F13), // أسود مطفي مريح للعين
      primaryColor: const Color(0xFF00FFCC),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FFCC),
        secondary: Color(0xFF8A2BE2), // لون ثانوي (Purple) ليعطي طابعاً قوياً
        surface: Color(0xFF1C1C23),
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1C23),
        selectedItemColor: Color(0xFF00FFCC),
        unselectedItemColor: Colors.grey,
        elevation: 10,
      ),
    );
  }
}