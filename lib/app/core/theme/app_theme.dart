import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// Clase principal para gestionar los temas de la aplicación Te Leo
/// Proporciona acceso a los temas claro y oscuro configurados para accesibilidad
class AppTheme {
  /// Tema claro de la aplicación
  /// Optimizado para uso diurno con colores de alto contraste
  static ThemeData get light => LightTheme.theme;

  /// Tema oscuro de la aplicación
  /// Optimizado para uso nocturno y reducción de fatiga visual
  static ThemeData get dark => DarkTheme.theme;
}
