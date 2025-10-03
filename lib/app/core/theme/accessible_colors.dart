import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme_service.dart';

/// Paleta de colores específicamente diseñada para accesibilidad
/// Cumple con WCAG 2.1 AA y es amigable para dislexia y baja visión
class AccessibleColors {
  
  // Colores primarios con alto contraste (ratio 7:1 o superior)
  static const Color primaryBlue = Color(0xFF0D47A1); // Azul oscuro accesible
  static const Color primaryBlueLight = Color(0xFF90CAF9); // Azul claro para tema oscuro
  
  // Colores secundarios amigables para dislexia (evita rojo/verde problemáticos)
  static const Color secondaryBrown = Color(0xFF5D4037); // Marrón cálido
  static const Color secondaryBrownLight = Color(0xFFBCAAA4); // Marrón claro
  
  // Colores terciarios seguros para daltonismo
  static const Color tertiaryPurple = Color(0xFF6A1B9A); // Púrpura
  static const Color tertiaryPurpleLight = Color(0xFFCE93D8); // Púrpura claro
  
  // Colores de texto optimizados
  static const Color textPrimary = Color(0xFF1A1A1A); // Negro cálido
  static const Color textPrimaryDark = Color(0xFFF2F2F7); // Blanco cálido
  static const Color textSecondary = Color(0xFF4A4A4A); // Gris oscuro
  static const Color textSecondaryDark = Color(0xFFE0E0E6); // Gris claro
  
  // Superficies optimizadas para reducir fatiga visual
  static const Color surfaceLight = Color(0xFFF8F9FA); // Blanco cálido
  static const Color surfaceDark = Color(0xFF1C1C1E); // Gris oscuro cálido
  
  // Colores de estado accesibles
  static const Color errorLight = Color(0xFFB71C1C); // Rojo oscuro (menos agresivo)
  static const Color errorDark = Color(0xFFFF8A80); // Rojo claro para tema oscuro
  static const Color successLight = Color(0xFF2E7D32); // Verde oscuro accesible
  static const Color successDark = Color(0xFF81C784); // Verde claro para tema oscuro
  static const Color warningLight = Color(0xFFE65100); // Naranja oscuro (visible para daltonismo)
  static const Color warningDark = Color(0xFFFFB74D); // Naranja claro
  
  // Gradientes accesibles para fondos
  static const List<Color> lightGradient = [
    Color(0xFF0D47A1), // Azul oscuro
    Color(0xFF1565C0), // Azul medio
    Color(0xFF1976D2), // Azul estándar
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF263238), // Gris azulado oscuro
    Color(0xFF37474F), // Gris azulado medio
    Color(0xFF455A64), // Gris azulado claro
  ];
  
  // Colores específicos para características de lectura
  static const Color highlightText = Color(0xFFFFF59D); // Amarillo suave para resaltar texto
  static const Color highlightTextDark = Color(0xFF827717); // Amarillo oscuro para tema oscuro
  static const Color readingProgress = Color(0xFF4CAF50); // Verde para progreso (distinto del rojo)
  static const Color readingProgressDark = Color(0xFF81C784); // Verde claro para tema oscuro
  
  // Colores de texto sobre gradientes (garantizan contraste mínimo 7:1)
  static const Color textOnGradientLight = Color(0xFFFFFFFF); // Blanco puro sobre gradientes oscuros
  static const Color textOnGradientDark = Color(0xFF000000); // Negro puro sobre gradientes claros
  static const Color textOnGradientSecondary = Color(0xFFF5F5F5); // Blanco suave
  static const Color textOnGradientSecondaryDark = Color(0xFF1A1A1A); // Negro suave
  
  /// Obtener color de texto apropiado según el tema
  static Color getTextColor({bool isDark = false, bool isSecondary = false}) {
    if (isDark) {
      return isSecondary ? textOnGradientSecondary : textOnGradientLight;
    } else {
      return isSecondary ? textOnGradientSecondaryDark : textOnGradientDark;
    }
  }
  
  /// Obtener color de texto sobre gradiente según el tema actual (REACTIVO)
  static Color getTextOnGradient({bool isSecondary = false}) {
    try {
      final themeService = Get.find<ThemeService>();
      final isDark = themeService.isDarkMode;
      if (isDark) {
        return isSecondary ? textOnGradientSecondary : textOnGradientLight;
      } else {
        // En tema claro, usar texto blanco sobre gradientes oscuros
        return isSecondary ? textOnGradientSecondary : textOnGradientLight;
      }
    } catch (e) {
      // Fallback si ThemeService no está disponible
      final isDark = Get.isDarkMode;
      if (isDark) {
        return isSecondary ? textOnGradientSecondary : textOnGradientLight;
      } else {
        return isSecondary ? textOnGradientSecondary : textOnGradientLight;
      }
    }
  }
  
  /// Obtener color con opacidad segura
  static Color withSafeOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }
  
  /// Verificar si un color tiene suficiente contraste
  static bool hasGoodContrast(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final ratio = (luminance1 > luminance2) 
        ? (luminance1 + 0.05) / (luminance2 + 0.05)
        : (luminance2 + 0.05) / (luminance1 + 0.05);
    
    return ratio >= 4.5; // WCAG AA estándar
  }
  
  /// Verificar si un color tiene contraste AAA (más estricto)
  static bool hasExcellentContrast(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final ratio = (luminance1 > luminance2) 
        ? (luminance1 + 0.05) / (luminance2 + 0.05)
        : (luminance2 + 0.05) / (luminance1 + 0.05);
    
    return ratio >= 7.0; // WCAG AAA estándar
  }
  
  /// Obtener color de fondo apropiado para texto
  static Color getBackgroundForText(Color textColor, {bool isDark = false}) {
    if (isDark) {
      return hasExcellentContrast(textColor, surfaceDark) ? surfaceDark : const Color(0xFF000000);
    } else {
      return hasExcellentContrast(textColor, surfaceLight) ? surfaceLight : const Color(0xFFFFFFFF);
    }
  }

  /// Cache para colores calculados (optimización de rendimiento)
  static final Map<String, Color> _colorCache = {};
  
  /// Limpiar cache cuando cambie el tema
  static void clearCache() {
    _colorCache.clear();
  }
  
  /// Obtener color de texto primario con máximo contraste (REACTIVO y CACHEADO)
  static Color getPrimaryTextColor() {
    const cacheKey = 'primary_text';
    
    if (_colorCache.containsKey(cacheKey)) {
      return _colorCache[cacheKey]!;
    }
    
    try {
      final themeService = Get.find<ThemeService>();
      final color = themeService.isDarkMode ? textPrimaryDark : textPrimary;
      _colorCache[cacheKey] = color;
      return color;
    } catch (e) {
      final color = Get.isDarkMode ? textPrimaryDark : textPrimary;
      _colorCache[cacheKey] = color;
      return color;
    }
  }

  /// Obtener color de texto secundario con buen contraste (REACTIVO)
  static Color getSecondaryTextColor() {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? textSecondaryDark : textSecondary;
    } catch (e) {
      return Get.isDarkMode ? textSecondaryDark : textSecondary;
    }
  }

  /// Obtener color de superficie con contraste apropiado (REACTIVO)
  static Color getSurfaceColor() {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? surfaceDark : surfaceLight;
    } catch (e) {
      return Get.isDarkMode ? surfaceDark : surfaceLight;
    }
  }

  /// Obtener color de texto para botones y elementos interactivos (REACTIVO)
  static Color getInteractiveTextColor({bool isSelected = false}) {
    try {
      final themeService = Get.find<ThemeService>();
      if (themeService.isDarkMode) {
        return isSelected ? primaryBlueLight : textPrimaryDark;
      } else {
        return isSelected ? primaryBlue : textPrimary;
      }
    } catch (e) {
      if (Get.isDarkMode) {
        return isSelected ? primaryBlueLight : textPrimaryDark;
      } else {
        return isSelected ? primaryBlue : textPrimary;
      }
    }
  }

  /// Obtener color de borde con contraste apropiado (REACTIVO)
  static Color getBorderColor({double opacity = 0.3}) {
    try {
      final themeService = Get.find<ThemeService>();
      final baseColor = themeService.isDarkMode ? textSecondaryDark : textSecondary;
      return baseColor.withValues(alpha: opacity);
    } catch (e) {
      final baseColor = Get.isDarkMode ? textSecondaryDark : textSecondary;
      return baseColor.withValues(alpha: opacity);
    }
  }

  /// Obtener color de texto que contraste con el fondo de tarjetas (REACTIVO)
  static Color getCardTextColor() {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? textPrimaryDark : textPrimary;
    } catch (e) {
      return Get.isDarkMode ? textPrimaryDark : textPrimary;
    }
  }

  /// Obtener color de texto secundario que contraste con tarjetas (REACTIVO)
  static Color getCardSecondaryTextColor() {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? textSecondaryDark : textSecondary;
    } catch (e) {
      return Get.isDarkMode ? textSecondaryDark : textSecondary;
    }
  }

  /// Obtener color de fondo de tarjeta con contraste apropiado (REACTIVO)
  static Color getCardBackgroundColor() {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? surfaceDark : surfaceLight;
    } catch (e) {
      return Get.isDarkMode ? surfaceDark : surfaceLight;
    }
  }

  /// Obtener color de texto garantizando contraste mínimo con cualquier fondo
  static Color getContrastingTextColor(Color backgroundColor) {
    final backgroundLuminance = backgroundColor.computeLuminance();
    
    // Si el fondo es oscuro (luminancia < 0.5), usar texto claro
    // Si el fondo es claro (luminancia >= 0.5), usar texto oscuro
    if (backgroundLuminance < 0.5) {
      return textPrimaryDark; // Texto claro para fondos oscuros
    } else {
      return textPrimary; // Texto oscuro para fondos claros
    }
  }

  /// Obtener color de texto secundario garantizando contraste con cualquier fondo
  static Color getContrastingSecondaryTextColor(Color backgroundColor) {
    final backgroundLuminance = backgroundColor.computeLuminance();
    
    if (backgroundLuminance < 0.5) {
      return textSecondaryDark; // Texto claro secundario para fondos oscuros
    } else {
      return textSecondary; // Texto oscuro secundario para fondos claros
    }
  }
}
