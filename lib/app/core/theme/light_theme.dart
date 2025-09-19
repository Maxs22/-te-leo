import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuración del tema claro para la aplicación Te Leo
/// Diseñado para ser accesible con alto contraste y legibilidad óptima
class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      // Configuración básica del tema
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Esquema de colores accesible para baja visión y dislexia
      colorScheme: const ColorScheme.light(
        // Colores primarios con alto contraste (ratio 7:1 o superior)
        primary: Color(0xFF0D47A1), // Azul oscuro accesible (evita azul brillante que puede causar fatiga)
        onPrimary: Color(0xFFFFFFFF),
        
        // Colores secundarios amigables para dislexia (evita rojo/verde que pueden confundirse)
        secondary: Color(0xFF5D4037), // Marrón cálido, fácil de distinguir
        onSecondary: Color(0xFFFFFFFF),
        tertiary: Color(0xFF6A1B9A), // Púrpura para variedad sin problemas de daltonismo
        onTertiary: Color(0xFFFFFFFF),
        
        // Superficies con contraste suave para reducir fatiga visual
        surface: Color(0xFFF8F9FA), // Blanco cálido, menos brillante que blanco puro
        onSurface: Color(0xFF1A1A1A), // Negro cálido para mejor legibilidad
        surfaceContainerHighest: Color(0xFFE8EAF6), // Superficie elevada con tinte azul suave
        
        // Contenedores con gradación suave
        primaryContainer: Color(0xFFBBDEFB), // Azul muy claro para contenedores
        onPrimaryContainer: Color(0xFF0D47A1),
        secondaryContainer: Color(0xFFD7CCC8), // Marrón muy claro
        onSecondaryContainer: Color(0xFF3E2723),
        
        // Colores de estado accesibles
        error: Color(0xFFB71C1C), // Rojo oscuro en lugar de rojo brillante
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: Color(0xFFB71C1C),
        
        // Colores de éxito y advertencia amigables para daltonismo
        outline: Color(0xFF6F7579), // Gris medio para bordes
        outlineVariant: Color(0xFFBEC6CA), // Gris claro para elementos secundarios
      ),
      
      // Tipografía accesible usando Google Fonts Lato
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lato(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        displayMedium: GoogleFonts.lato(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        displaySmall: GoogleFonts.lato(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF212121),
        ),
        headlineLarge: GoogleFonts.lato(
          fontSize: 24, // Tamaño aumentado
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0.5,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.lato(
          fontSize: 22, // Tamaño aumentado
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0.5,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.lato(
          fontSize: 20, // Tamaño aumentado
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0.4,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 18, // Tamaño aumentado
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0.4,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.lato(
          fontSize: 16, // Tamaño aumentado
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0.3,
          height: 1.3,
        ),
        titleSmall: GoogleFonts.lato(
          fontSize: 14, // Tamaño aumentado
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0.3,
          height: 1.3,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 18, // Tamaño aumentado para mejor legibilidad
          fontWeight: FontWeight.normal,
          color: const Color(0xFF1A1A1A),
          height: 1.6, // Espaciado de línea aumentado para dislexia
          letterSpacing: 0.3, // Espaciado entre letras para mejor distinción
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 16, // Tamaño aumentado
          fontWeight: FontWeight.normal,
          color: const Color(0xFF1A1A1A),
          height: 1.6,
          letterSpacing: 0.3,
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 14, // Tamaño aumentado
          fontWeight: FontWeight.normal,
          color: const Color(0xFF4A4A4A), // Gris más oscuro para mejor contraste
          height: 1.6,
          letterSpacing: 0.2,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF212121),
        ),
        labelMedium: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF212121),
        ),
        labelSmall: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF757575),
        ),
      ),
      
      // Configuración de AppBar accesible
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D47A1), // Usa el nuevo color primario
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5, // Espaciado de letras para mejor legibilidad
        ),
      ),
      
      // Configuración de botones accesibles con tamaños mínimos para dislexia
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 56), // Tamaño mínimo aumentado para accesibilidad
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordes más redondeados, más amigables
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600, // Peso aumentado para mejor legibilidad
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Configuración de botones de texto con mayor contraste
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0D47A1),
          minimumSize: const Size(120, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Configuración de botones outlined con mejor visibilidad
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0D47A1),
          minimumSize: const Size(120, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: Color(0xFF0D47A1), width: 2), // Borde más grueso
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Configuración de cards
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Configuración de inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        labelStyle: GoogleFonts.lato(
          color: const Color(0xFF757575),
        ),
        hintStyle: GoogleFonts.lato(
          color: const Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}
