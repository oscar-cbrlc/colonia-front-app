import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color.fromRGBO(253, 203, 52,1);
  //static const Color secondaryColor = Color.fromRGBO(245, 138, 7, 1);
  static const Color secondaryColor = Color.fromRGBO(246, 83, 20, 1);
  static const Color tertiaryColor = Color.fromRGBO(242, 187, 5, 1);
  static const Color walkColor = Color.fromRGBO(247, 237, 240, 1);
  static const Color runColor = Color.fromRGBO(244, 91, 105, 1);
  static const Color bikeColor = Color.fromRGBO(58, 110, 165, 1);

  static const Color fontPrimaryColor = Color(0xFF101828);
  static const Color fontSecondaryColor = Color(0xFF475467);
  static const Color fontVeryLightColor = Color(0xFF667085);
  static const Color fontUnderlineColor = Color(0xFF344054);
  static const Color lightBackground = Color.fromRGBO(240,241,245,1);
  static const Color darkBackground = Color.fromRGBO(48,38,33,1);
  static const Color lightTextColor = Color(0xFF475467);
  static const Color lightBtBorderColor = Color(0xFFD0D5DD);
  static const Color lightInputColor = Color(0xFFF2F4F7);
  static const Color errorColor = Color(0xffff0000);
  static const Color h3GridLineColor = Color(0x98393939);
  static const Color trackingPolygonColor = Color(0xEA121111);

  static InputDecorationTheme get inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.lightInputColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppTheme.fontSecondaryColor, width: 1.0),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.0),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 2.0),
      ),

      hintStyle: const TextStyle(
        color: AppTheme.lightTextColor,
        fontSize: 16.0,
      ),
      labelStyle: TextStyle(
          color: Color(0xFF1B1817),
          fontWeight: FontWeight.w600
      ),
    );
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
      ),
      inputDecorationTheme: inputDecorationTheme,
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
            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: GoogleFonts.oswald(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            elevation: 0.5,
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