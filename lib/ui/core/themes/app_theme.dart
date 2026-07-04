import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color.fromRGBO(193,30,59,1);
  static const Color secondaryColor = Color(0x26397f00);
  static const Color fontPrimaryColor = Color(0xFF101828);
  static const Color fontSecondaryColor = Color(0xFF475467);
  static const Color fontVeryLightColor = Color(0xFF667085);
  static const Color fontUnderlineColor = Color(0xFF344054);
  static const Color lightBackground = Color.fromRGBO(240,241,245,1);
  static const Color darkBackground = Color.fromRGBO(48,38,33,1);
  static const Color lightTextColor = Color(0xFF475467);
  static const Color lightBtBorderColor = Color(0xFFD0D5DD);

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
          color: fontPrimaryColor,
        ),
        displayMedium: GoogleFonts.lato(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: fontPrimaryColor,
        ),
        titleLarge: GoogleFonts.oswald(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.2,
        ),
        titleMedium: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: fontPrimaryColor
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14.0,
          height: 1.4,
          color: AppTheme.fontSecondaryColor,
        ),
        bodySmall: GoogleFonts.roboto(
          color: fontVeryLightColor,
          fontSize: 12.0,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
          ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: GoogleFonts.oswald(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            elevation: 1.0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
          OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: lightBtBorderColor),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
      )
      //cardTheme: CardTheme(
        //color: Colors.grey[900],
        //elevation: 6,
        //shape: RoundedRectangleBorder(
          //borderRadius: BorderRadius.circular(16),
        //),
      //),
      //elevatedButtonTheme: ElevatedButtonThemeData(
        //style: ElevatedButton.styleFrom(
          //minimumSize: const Size(120, 48),
          //shape: RoundedRectangleBorder(
            //borderRadius: BorderRadius.circular(24),
          //),
          //textStyle: GoogleFonts.oswald(
            //fontSize: 18,
            //fontWeight: FontWeight.bold,
            //letterSpacing: 1.0,
          //),
        //),
      //),
    );
  }
}