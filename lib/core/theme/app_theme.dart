import 'package:flutter/material.dart';

// Primary brand color - Blue
const kNeonOrange = Color(0xFF2563EB);
const kNeonOrangeLight = Color(0xFF3B82F6);
const kNeonOrangeDark = Color(0xFF1D4ED8);

// Backgrounds - Light mode
const kBgDark = Color(0xFFFFFFFF);
const kBgCard = Color(0xFFF9FAFB);
const kBgCardElevated = Color(0xFFF3F4F6);
const kBorderColor = Color(0xFFE5E7EB);

// Text colors - Dark on light
const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);
const kTextMuted = Color(0xFF9CA3AF);

// Status colors
const kSuccess = Color(0xFF22C55E);
const kError = Color(0xFFEF4444);

ThemeData buildNexusTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: kBgDark,
    colorScheme: const ColorScheme.light(
      primary: kNeonOrange,
      secondary: kNeonOrangeLight,
      surface: kBgCard,
      error: kError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
      onError: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: kBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorderColor, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kNeonOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kNeonOrange,
        side: const BorderSide(color: kNeonOrange, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kNeonOrange,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
      labelStyle: const TextStyle(color: kTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: kNeonOrange,
      thumbColor: kNeonOrange,
      inactiveTrackColor: kBorderColor,
      overlayColor: Color(0x292563EB),
    ),
    dividerTheme: const DividerThemeData(color: kBorderColor, thickness: 1),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w900, fontSize: 48),
      displayMedium: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 36),
      headlineLarge: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 28),
      headlineMedium: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 22),
      headlineSmall: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      titleMedium: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      bodyLarge: TextStyle(color: kTextPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: kTextSecondary, fontSize: 14),
      bodySmall: TextStyle(color: kTextMuted, fontSize: 12),
      labelLarge: TextStyle(
          color: kNeonOrange, fontWeight: FontWeight.w700, fontSize: 13),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kBgCardElevated,
      labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
      side: const BorderSide(color: kBorderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kBgDark,
      selectedItemColor: kNeonOrange,
      unselectedItemColor: kTextMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
