import 'package:flutter/material.dart';

/// Tema aplikasi yang konsisten dengan website Laravel
/// Menggunakan warna cyan sebagai warna utama sesuai dengan branding
class AppTheme {
  // Warna utama - Cyan (sesuai dengan website)
  static const Color primaryCyan = Color(0xFF06b6d4); // cyan-500
  static const Color primaryCyanDark = Color(0xFF0891b2); // cyan-600
  static const Color primaryCyanLight = Color(0xFF67e8f9); // cyan-300
  
  // Warna sekunder - Blue
  static const Color secondaryBlue = Color(0xFF2563eb); // blue-600
  static const Color secondaryBlueLight = Color(0xFF3b82f6); // blue-500
  
  // Warna background
  static const Color backgroundCyan50 = Color(0xFFecfeff); // cyan-50
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  
  // Warna text
  static const Color textGray900 = Color(0xFF111827); // gray-900
  static const Color textGray600 = Color(0xFF4b5563); // gray-600
  static const Color textCyan800 = Color(0xFF155e75); // cyan-800
  
  // Warna border
  static const Color borderCyan100 = Color(0xFFcffafe); // cyan-100
  static const Color borderCyan200 = Color(0xFFa5f3fc); // cyan-200
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0891b2), Color(0xFF2563eb)], // cyan-600 to blue-600
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFecfeff), Color(0xFFFFFFFF), Color(0xFFecfeff)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Theme Data untuk Material App
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryCyan,
        primary: primaryCyanDark,
        secondary: secondaryBlue,
        surface: backgroundWhite,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textGray900,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textGray900,
        titleTextStyle: TextStyle(
          color: textGray900,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: backgroundWhite,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderCyan200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderCyan200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyanDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: primaryCyanDark,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCyanDark,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryCyanDark, width: 2),
          foregroundColor: primaryCyanDark,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryCyanDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundWhite,
        selectedItemColor: primaryCyanDark,
        unselectedItemColor: textGray600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textGray900,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textGray900,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textGray900,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textGray900,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textGray900,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textGray900,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textGray900,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textGray900,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textGray900,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textGray600,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textGray600,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textGray600,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textGray900,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryCyanDark,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderCyan100,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  // Helper untuk membuat gradient button
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: [
          BoxShadow(
            color: primaryCyan.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper untuk membuat card dengan shadow cyan
  static BoxDecoration cardDecoration({
    Color? color,
    double? borderRadius,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? backgroundWhite,
      borderRadius: BorderRadius.circular(borderRadius ?? 16),
      border: Border.all(color: borderCyan100),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: primaryCyan.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }
}

