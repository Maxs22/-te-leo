import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_preferences_service.dart';
import 'debug_console_service.dart';

/// Servicio para gestión dinámica de temas
class ThemeService extends GetxController {
  UserPreferencesService? _prefsService;
  
  // Estado reactivo del tema
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  
  /// Getter para el modo de tema actual (reactivo)
  ThemeMode get themeMode => _themeMode.value;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeTheme();
  }
  
  /// Inicializar el tema desde las preferencias
  Future<void> _initializeTheme() async {
    try {
      _prefsService = Get.find<UserPreferencesService>();
      
      final savedTheme = _prefsService?.savedThemeMode ?? 'system';
      _themeMode.value = _getThemeModeFromString(savedTheme);
      
      // Aplicar el tema inmediatamente
      Get.changeThemeMode(_themeMode.value);
      
      DebugLog.i('Theme initialized: $savedTheme', category: LogCategory.app);
    } catch (e) {
      DebugLog.w('Could not initialize theme service, using system default', category: LogCategory.app);
      _themeMode.value = ThemeMode.system;
    }
  }
  
  /// Cambiar el tema
  Future<void> changeTheme(ThemeMode newTheme) async {
    try {
      _themeMode.value = newTheme;
      
      // Aplicar el tema
      Get.changeThemeMode(newTheme);
      
      // Guardar en preferencias
      if (_prefsService != null) {
        await _prefsService!.saveThemeMode(_getStringFromThemeMode(newTheme));
      }
      
      DebugLog.i('Theme changed to: ${_getStringFromThemeMode(newTheme)}', category: LogCategory.app);
    } catch (e) {
      DebugLog.e('Error changing theme: $e', category: LogCategory.app);
    }
  }
  
  /// Cambiar al siguiente tema (system -> light -> dark -> system)
  Future<void> toggleTheme() async {
    switch (_themeMode.value) {
      case ThemeMode.system:
        await changeTheme(ThemeMode.light);
        break;
      case ThemeMode.light:
        await changeTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await changeTheme(ThemeMode.system);
        break;
    }
  }
  
  /// Obtener ThemeMode desde string
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  /// Obtener string desde ThemeMode
  String _getStringFromThemeMode(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  /// Obtener nombre legible del tema actual
  String get currentThemeName {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
  
  /// Verificar si el tema actual es oscuro
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.dark) return true;
    if (_themeMode.value == ThemeMode.light) return false;
    
    // Si es system, verificar el tema del sistema
    return Get.isPlatformDarkMode;
  }
}