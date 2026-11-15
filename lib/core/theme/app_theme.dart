import 'package:flutter/material.dart';

const kPrimary = Color(0xFF2563EB);
const kPrimaryLight = Color(0xFF3B82F6);

const kBackground = Color(0xFFFFFFFF);
const kBackdrop = Color(0xFFF1F5F9);
const kSurface = Color(0xFFF9FAFB);
const kSurfaceAlt = Color(0xFFF3F4F6);
const kBorder = Color(0xFFE5E7EB);

const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);
const kTextMuted = Color(0xFF9CA3AF);

const kSuccess = Color(0xFF22C55E);
const kError = Color(0xFFEF4444);

const kFontFamily = 'Poppins';

ThemeData buildNexusTheme() {
  final radius12 = BorderRadius.circular(12);

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.light(
      primary: kPrimary,
      secondary: kPrimaryLight,
      surface: kSurface,
      error: kError,
      onSurface: kTextPrimary,
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        color: kTextPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: const BorderSide(color: kPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
      labelStyle: const TextStyle(color: kTextSecondary),
      border: inputBorder(kBorder),
      enabledBorder: inputBorder(kBorder),
      focusedBorder: inputBorder(const Color(0xFFD1D5DB), 1.5),
      errorBorder: inputBorder(kError),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: kPrimary,
      thumbColor: kPrimary,
      inactiveTrackColor: kBorder,
      overlayColor: Color(0x292563EB),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    textTheme: const TextTheme(
      displayMedium: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 32),
      headlineSmall: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(
          color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: TextStyle(color: kTextPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: kTextSecondary, fontSize: 14),
      bodySmall: TextStyle(color: kTextMuted, fontSize: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurfaceAlt,
      labelStyle: const TextStyle(color: kTextPrimary, fontSize: 12),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kSurface,
      selectedItemColor: kPrimary,
      unselectedItemColor: kTextMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
