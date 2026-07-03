import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0x00c11e3b);
  static const Color secondaryColor = Color(0x0026397f);
  static const Color fontPrimary = Color(0x00362E42);
  static const Color fontSecondary = Color(0x00797979);
  static const Color lightBackground = Color(0x00F0F1F5);
  static const Color darkBackground = Color(0x00302621);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lato(
          fontSize: 72,
          fontWeight: FontWeight.bold,
          color: fontPrimary,
        ),
        displayMedium: GoogleFonts.lato(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: fontPrimary,
        ),
        titleLarge: GoogleFonts.oswald(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.2,
        ),
        titleMedium: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 16,
          color: fontSecondary,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          color: fontSecondary,
        ),
      ),
      //cardTheme: CardTheme(
        //color: Colors.grey[900],
        //elevation: 6,
        //shape: RoundedRectangleBorder(
          //borderRadius: BorderRadius.circular(16),
        //),
      //),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}