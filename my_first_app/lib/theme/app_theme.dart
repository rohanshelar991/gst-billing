import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryBlue = Color(0xFF2F6FED);
const Color darkText = Color(0xFF1F2A44);
const Color lightBackground = Color(0xFFEEF4FF);
const Color whiteCard = Color(0xFFFFFFFF);
const Color greyDivider = Color(0xFFE5E7EB);
const Color lightOrange = Color(0xFFFFF3E6);

const List<Color> orangeGradient = <Color>[
  Color(0xFFFF8A3D),
  Color(0xFFFF6A00),
];
const List<Color> greenGradient = <Color>[Color(0xFF2ECC71), Color(0xFF27AE60)];
const List<Color> purpleGradient = <Color>[
  Color(0xFF8E5CF6),
  Color(0xFF6C3DF0),
];
const List<Color> blueGradient = <Color>[Color(0xFF4A90E2), Color(0xFF357ABD)];

const Color darkBackground = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color darkCardGlass = Color(0xCC1E293B);
const Color darkPrimaryBlue = Color(0xFF3B82F6);
const Color darkTextLight = Color(0xFFF1F5F9);

class AppTheme {
  AppTheme._();

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void setDarkMode(bool value) {
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData get lightTheme {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: whiteCard,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: whiteCard,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: whiteCard,
        labelStyle: const TextStyle(color: darkText),
        hintStyle: TextStyle(color: darkText.withValues(alpha: 0.45)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: greyDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: greyDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: whiteCard,
        elevation: 2,
        shadowColor: const Color(0x22000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: greyDivider,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryBlue,
        brightness: Brightness.dark,
        primary: darkPrimaryBlue,
        surface: darkCard,
      ),
      cardColor: darkCard,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: darkTextLight, displayColor: darkTextLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkTextLight,
        titleTextStyle: TextStyle(
          color: darkTextLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        labelStyle: const TextStyle(color: darkTextLight),
        hintStyle: TextStyle(color: darkTextLight.withValues(alpha: 0.45)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkTextLight.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkTextLight.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimaryBlue, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardGlass,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryBlue,
          foregroundColor: darkTextLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: darkPrimaryBlue,
        unselectedItemColor: darkTextLight.withValues(alpha: 0.55),
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkCardGlass,
      ),
      dividerColor: darkTextLight.withValues(alpha: 0.14),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
