import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Core Palette ---
  // A softer, more calming and modern palette.
  static const Color primary = Color(0xFF5A95E9); // A gentler, more accessible blue
  static const Color secondary = Color(0xFF67C2A5); // A soft, muted teal/green
  static const Color accent = Color(0xFFF2C94C); // A warm, encouraging gold for accents

  // --- Neutrals ---
  // Designed for high readability and low cognitive load.
  static const Color background = Color(0xFFF9FAFB); // A very light, clean off-white
  static const Color surface = Color(0xFFFFFFFF);     // Pure white for cards and surfaces
  static const Color border = Color(0xFFE5E7EB);       // Subtle border for definition
  
  // --- Text ---
  static const Color textPrimary = Color(0xFF1F2937); // Dark, readable charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Softer gray for secondary text
  static const Color textDisabled = Color(0xFF9CA3AF);  // For disabled states

  // --- System Colors ---
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // --- Dark Mode Palette ---
  static const Color darkBackground = Color(0xFF0F1419); // Deep, calming dark blue-gray
  static const Color darkSurface = Color(0xFF1A1F2E);    // Slightly lighter surface
  static const Color darkBorder = Color(0xFF2D3748);     // Subtle border for dark mode
  static const Color darkTextPrimary = Color(0xFFE2E8F0); // Light, readable text
  static const Color darkTextSecondary = Color(0xFFA0AEC0); // Softer gray for secondary text
  static const Color darkTextDisabled = Color(0xFF718096);  // For disabled states in dark mode

  // --- Typography ---
  // Using Manrope for its modern and clean aesthetic.
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.2),
    displayMedium: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1.0),
    headlineLarge: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.8),
    headlineMedium: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.5),
    titleLarge: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3),
    bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 1.5),
    bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary, height: 1.5),
    labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // For buttons
  );

  // --- Dark Mode Typography ---
  static final TextTheme _darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800, color: darkTextPrimary, letterSpacing: -1.2),
    displayMedium: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -1.0),
    headlineLarge: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -0.8),
    headlineMedium: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary, letterSpacing: -0.5),
    titleLarge: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary, letterSpacing: -0.3),
    bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: darkTextPrimary, height: 1.5),
    bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: darkTextSecondary, height: 1.5),
    labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // For buttons
  );

  // --- Light Theme Definition ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // --- Colors ---
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: Colors.white,
    ),
    
    // --- Components ---
    scaffoldBackgroundColor: background,
    
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: _textTheme.headlineMedium,
      iconTheme: const IconThemeData(color: textSecondary),
    ),
    
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: border, width: 1.5),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: _textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: _textTheme.bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: textDisabled,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: _textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: _textTheme.bodyMedium,
    ),
    
    // Pass in the text theme.
    textTheme: _textTheme,
  );

  // --- Dark Theme Definition ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // --- Colors ---
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      background: darkBackground,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onBackground: darkTextPrimary,
      onError: Colors.white,
    ),
    
    // --- Components ---
    scaffoldBackgroundColor: darkBackground,
    
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: _darkTextTheme.headlineMedium,
      iconTheme: const IconThemeData(color: darkTextSecondary),
    ),
    
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: darkBorder, width: 1.5),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: _darkTextTheme.labelLarge,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: _darkTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: _darkTextTheme.bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: darkTextDisabled,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: _darkTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: _darkTextTheme.bodyMedium,
    ),
    
    // Pass in the text theme.
    textTheme: _darkTextTheme,
  );
}

// Spacing constants for consistent layout
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

// Border radius constants
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
} 