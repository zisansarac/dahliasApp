import 'package:flutter/material.dart';

class AppTheme {
  // Ortak yazı tipleri (hem light hem dark theme için)
  static const TextTheme _baseTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      fontFamily: 'Montserrat',
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: 'Montserrat',
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: 'Montserrat',
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
    bodyLarge: TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
    bodyMedium: TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
  );

  // Renk ve sabitler
  static const Color primaryColor = Color(0xFF8AA624);
  static const Color backgroundColor = Color(0xFFFFFFF0);
  static const Color inputBorderColor = Color(0xFFDDDDDD);
  static const Color textColor = Colors.black87;
  static const Color hintColor = Color.fromARGB(255, 117, 117, 117);
  static const double borderRadius = 8.0;

  /// Aydınlık (Light) Tema
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    textTheme: _baseTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      background: backgroundColor,
      onPrimary: Colors.white,
      onBackground: textColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: hintColor, fontFamily: 'Montserrat'),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor),
      ),
      prefixIconColor: hintColor,
      suffixIconColor: hintColor,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
    ),
  );

  /// 🌙 Karanlık (Dark) Tema
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFA4B465),
    scaffoldBackgroundColor: const Color.fromARGB(255, 28, 29, 27),
    textTheme: _baseTextTheme.copyWith(
      displayLarge: _baseTextTheme.displayLarge!.copyWith(color: Colors.white),
      displayMedium: _baseTextTheme.displayMedium!.copyWith(
        color: Colors.white,
      ),
      displaySmall: _baseTextTheme.displaySmall!.copyWith(color: Colors.white),
      headlineMedium: _baseTextTheme.headlineMedium!.copyWith(
        color: Colors.white,
      ),
      titleLarge: _baseTextTheme.titleLarge!.copyWith(color: Colors.white),
      bodyLarge: _baseTextTheme.bodyLarge!.copyWith(color: Colors.white),
      bodyMedium: _baseTextTheme.bodyMedium!.copyWith(color: Colors.white70),
      labelLarge: _baseTextTheme.labelLarge!.copyWith(color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF424242),
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: primaryColor,
      secondary: Color(0xFFFF8A80),
      surface: Color.fromARGB(255, 61, 55, 55),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryColor.withOpacity(0.1),
      hintStyle: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: primaryColor),
      ),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
    ),
    cardColor: const Color(0xFF424242),
    dividerColor: Colors.white24,
  );
}
