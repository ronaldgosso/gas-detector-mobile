import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final lightTheme = ThemeData(
  // Core Colors
  brightness: Brightness.light,
  primaryColor: const Color(0xFF38BDF8), // Cyan Tech
  scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Light gray background
  cardColor: Colors.white,
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),

  // Text Themes
  textTheme: TextTheme(
    displayLarge: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: const TextStyle(color: Color(0xFF212529), fontSize: 16),
    bodyMedium: const TextStyle(
      color: Color(0xFF6C757D),
      fontSize: 14,
    ), // Gray Steel equivalent
    labelLarge: const TextStyle(
      color: Color(0xFF212529),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),

  // App Bar
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF212529),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Color(0xFF212529),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Color(0xFF212529)),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  ),

  // Card Theme
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.all(8),
  ),

  // Button Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF38BDF8), // Cyan Tech
      foregroundColor: const Color(0xFF0F172A), // Deep Space for text
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 2,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF38BDF8),
      side: const BorderSide(color: Color(0xFF38BDF8), width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),

  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF1F5F9).withValues(alpha: 0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF6C757D)),
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: Color(0xFFDEE2E6),
    thickness: 1,
    space: 1,
  ),

  // Switch
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF38BDF8);
      }
      return const Color(0xFF94A3B8);
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF38BDF8).withValues(alpha: 0.2);
      }
      return const Color(0xFFDEE2E6);
    }),
  ),

  // Progress Indicator
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF38BDF8),
  ),

  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFE2E8F0),
    labelStyle: const TextStyle(color: Color(0xFF212529)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    selectedColor: const Color(0xFF38BDF8),
  ),

  // Status Colors (using your scheme)
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF38BDF8), // Cyan Tech
    secondary: const Color(0xFF94A3B8), // Gray Steel
    error: const Color(0xFFEF4444), // Crimson Red
    onPrimary: const Color(0xFF0F172A), // Deep Space
    onSecondary: const Color(0xFF212529),
    onError: Colors.white,
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: const Color(0xFF212529),
  ),
);
