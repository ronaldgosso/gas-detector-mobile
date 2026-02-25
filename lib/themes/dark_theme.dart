import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final darkTheme = ThemeData(
  // Core Colors (using your Deep Space theme)
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF38BDF8), // Cyan Tech
  scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Space
  cardColor: const Color(0xFF1E293B), // Slate Card
  // Text Themes
  textTheme: TextTheme(
    displayLarge: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 16),
    bodyMedium: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
    ), // Gray Steel
    labelLarge: const TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),

  // App Bar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F172A), // Deep Space
    foregroundColor: Color(0xFFF1F5F9), // Cloud White
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Color(0xFFF1F5F9),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),

  // Card Theme
  cardTheme: CardThemeData(
    color: const Color(0xFF1E293B), // Slate Card
    elevation: 4,
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
      elevation: 4,
      shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.3),
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
    fillColor: Color(0xFF0F172A).withValues(alpha: 0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)), // Darker border
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
    hintStyle: const TextStyle(color: Color(0xFF64748B)),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: Color(0xFF334155),
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
      return const Color(0xFF64748B);
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF38BDF8).withValues(alpha: 0.2);
      }
      return const Color(0xFF334155);
    }),
  ),

  // Progress Indicator
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF38BDF8),
  ),

  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF334155),
    labelStyle: const TextStyle(color: Color(0xFFF1F5F9)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    selectedColor: const Color(0xFF38BDF8),
  ),

  // Status Colors (using your exact color scheme)
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF38BDF8), // Cyan Tech
    secondary: const Color(0xFF94A3B8), // Gray Steel
    error: const Color(0xFFEF4444), // Crimson Red
    onPrimary: const Color(0xFF0F172A), // Deep Space
    onSecondary: const Color(0xFFF1F5F9),
    onError: Colors.white,
    brightness: Brightness.dark,
    surface: const Color(0xFF1E293B), // Slate Card
    onSurface: const Color(0xFFF1F5F9), // Cloud White
  ),

  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: Color(0xFF1E293B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Popup Menu Theme
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF1E293B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(color: Color(0xFFF1F5F9)),
  ),

  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
    textStyle: const TextStyle(color: Color(0xFFF1F5F9)),
  ),
);
