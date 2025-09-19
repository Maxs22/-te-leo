import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuración del tema oscuro para la aplicación Te Leo
/// Diseñado para reducir la fatiga visual con colores suaves y buen contraste
class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      // Configuración básica del tema
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Esquema de colores oscuro accesible para baja visión y dislexia
      colorScheme: const ColorScheme.dark(
        // Colores primarios con alto contraste para tema oscuro
        primary: Color(0xFF90CAF9), // Azul claro accesible en fondo oscuro (ratio 7:1+)
        onPrimary: Color(0xFF0D47A1), // Azul oscuro para texto en elementos primarios
        
        // Colores secundarios amigables para dislexia
        secondary: Color(0xFFBCAAA4), // Marrón claro cálido, evita confusión rojo/verde
        onSecondary: Color(0xFF3E2723),
        tertiary: Color(0xFFCE93D8), // Púrpura claro para variedad
        onTertiary: Color(0xFF4A148C),
        
        // Superficies optimizadas para reducir fatiga visual nocturna
        surface: Color(0xFF1C1C1E), // Gris oscuro cálido, evita negro puro que puede causar halos
        onSurface: Color(0xFFF2F2F7), // Blanco cálido para máxima legibilidad
        surfaceContainerHighest: Color(0xFF2C2C2E), // Superficie elevada sutil
        
        // Contenedores con gradación accesible
        primaryContainer: Color(0xFF1565C0), // Azul medio para contenedores
        onPrimaryContainer: Color(0xFFE3F2FD),
        secondaryContainer: Color(0xFF5D4037), // Marrón medio
        onSecondaryContainer: Color(0xFFEFEBE9),
        
        // Colores de estado optimizados para accesibilidad
        error: Color(0xFFFF8A80), // Rojo claro en lugar de rojo brillante (menos agresivo)
        onError: Color(0xFFB71C1C),
        errorContainer: Color(0xFF5F2120),
        onErrorContainer: Color(0xFFFFDAD6),
        
        // Bordes y elementos de interfaz
        outline: Color(0xFF8E918F), // Gris medio cálido para bordes visibles
        outlineVariant: Color(0xFF48464C), // Gris oscuro para elementos sutiles
      ),
      
      // Tipografía accesible usando Google Fonts Lato para tema oscuro
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lato(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE0E0E0),
        ),
        displayMedium: GoogleFonts.lato(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE0E0E0),
        ),
        displaySmall: GoogleFonts.lato(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE0E0E0),
        ),
        headlineLarge: GoogleFonts.lato(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE0E0E0),
        ),
        headlineMedium: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE0E0E0),
        ),
        headlineSmall: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE0E0E0),
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE0E0E0),
        ),
        titleMedium: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE0E0E0),
        ),
        titleSmall: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE0E0E0),
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 18, // Tamaño aumentado para mejor legibilidad
          fontWeight: FontWeight.normal,
          color: const Color(0xFFF2F2F7), // Color más cálido y legible
          height: 1.6, // Espaciado de línea aumentado para dislexia
          letterSpacing: 0.3, // Espaciado entre letras para mejor distinción
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 16, // Tamaño aumentado
          fontWeight: FontWeight.normal,
          color: const Color(0xFFF2F2F7),
          height: 1.6,
          letterSpacing: 0.3,
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 14, // Tamaño aumentado
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE0E0E6), // Gris más claro para mejor contraste
          height: 1.6,
          letterSpacing: 0.2,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE0E0E0),
        ),
        labelMedium: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE0E0E0),
        ),
        labelSmall: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFBDBDBD),
        ),
      ),
      
      // Configuración de AppBar para tema oscuro
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFE0E0E0),
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE0E0E0),
        ),
      ),
      
      // Configuración de botones accesibles para tema oscuro
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64B5F6),
          foregroundColor: const Color(0xFF000000),
          minimumSize: const Size(88, 48), // Tamaño mínimo para accesibilidad
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Configuración de botones de texto para tema oscuro
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64B5F6),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Configuración de botones outlined para tema oscuro
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF64B5F6),
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: Color(0xFF64B5F6), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Configuración de cards para tema oscuro
      cardTheme: const CardThemeData(
        color: Color(0xFF2C2C2C),
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Configuración de inputs para tema oscuro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
        ),
        labelStyle: GoogleFonts.lato(
          color: const Color(0xFFBDBDBD),
        ),
        hintStyle: GoogleFonts.lato(
          color: const Color(0xFF757575),
        ),
      ),
    );
  }
}
