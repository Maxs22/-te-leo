import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'user_preferences_service.dart';
import 'debug_console_service.dart';
import '../theme/accessible_colors.dart';

/// Servicio para gestión dinámica de temas
class ThemeService extends GetxController {
  UserPreferencesService? _prefsService;
  
  // Estado reactivo del tema
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  
  /// Getter para el modo de tema actual (reactivo)
  ThemeMode get themeMode => _themeMode.value;
  
  /// Getter reactivo para el modo de tema (para GetX)
  Rx<ThemeMode> get themeModeRx => _themeMode;
  
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
  
  /// Cambiar el tema con reinicio completo de la aplicación
  Future<void> changeTheme(ThemeMode newTheme) async {
    try {
      // Verificar que el ThemeService esté registrado antes de proceder
      if (!Get.isRegistered<ThemeService>()) {
        DebugLog.e('ThemeService not registered, cannot change theme', category: LogCategory.app);
        return;
      }
      
      // Guardar el nuevo tema en preferencias primero
      if (_prefsService != null) {
        await _prefsService!.saveThemeMode(_getStringFromThemeMode(newTheme));
      }
      
      // Mostrar pantalla de carga
      _showThemeChangeLoading();
      
      // Esperar un poco para que se vea la pantalla de carga
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Reiniciar completamente la aplicación
      await _restartAppWithNewTheme(newTheme);
      
      DebugLog.i('Theme changed to: ${_getStringFromThemeMode(newTheme)}', category: LogCategory.app);
    } catch (e) {
      DebugLog.e('Error changing theme: $e', category: LogCategory.app);
      // Ocultar pantalla de carga en caso de error
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }
  
  /// Mostrar pantalla de carga durante el cambio de tema
  void _showThemeChangeLoading() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevenir que se cierre
        child: Material(
          color: Colors.black.withValues(alpha: 0.8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Get.theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cambiando tema...',
                    style: Get.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Actualizando interfaz',
                    style: Get.theme.textTheme.bodyMedium?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// Reiniciar controladores y servicios con el nuevo tema (SIN cerrar la app)
  Future<void> _restartAppWithNewTheme(ThemeMode newTheme) async {
    try {
      // Actualizar el tema en GetX
      _themeMode.value = newTheme;
      Get.changeThemeMode(newTheme);
      
      // Limpiar cache de colores para forzar recálculo
      AccessibleColors.clearCache();
      
      // Esperar un poco para que se vea la pantalla de carga
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Paso 1: Limpiar todos los controladores registrados
      await _resetAllControllers();
      
      // Paso 2: Forzar reconstrucción completa de la UI
      Get.forceAppUpdate();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Paso 3: Reinicializar servicios críticos
      await _reinitializeServices();
      
      // Paso 4: Navegar a home limpiando la pila de navegación
      Get.offAllNamed('/home');
      
      // Esperar un poco más para que se complete la navegación
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Ocultar la pantalla de carga
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
      DebugLog.i('Theme restart completed successfully', category: LogCategory.app);
      
    } catch (e) {
      DebugLog.e('Error restarting controllers: $e', category: LogCategory.app);
      // En caso de error, al menos ocultar la pantalla de carga
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }
  
  /// Limpiar todos los controladores registrados (EXCEPTO servicios críticos)
  Future<void> _resetAllControllers() async {
    try {
      DebugLog.i('Resetting controllers', category: LogCategory.app);
      
      // Limpiar controladores específicos si están registrados (NO servicios)
      final controllersToReset = [
        'HomeController',
        'SettingsController', 
        'WelcomeController',
        'ScanController',
        'LibraryController',
        'DocumentReaderController',
      ];
      
      for (final controllerName in controllersToReset) {
        try {
          if (Get.isRegistered(tag: controllerName)) {
            Get.delete(tag: controllerName);
            DebugLog.i('Reset controller: $controllerName', category: LogCategory.app);
          }
        } catch (e) {
          DebugLog.w('Could not reset controller $controllerName: $e', category: LogCategory.app);
        }
      }
      
      // NO usar Get.reset() porque elimina TODOS los controladores incluyendo servicios
      // En su lugar, solo limpiar controladores específicos
      DebugLog.i('Controllers reset completed (services preserved)', category: LogCategory.app);
      
    } catch (e) {
      DebugLog.e('Error resetting controllers: $e', category: LogCategory.app);
    }
  }
  
  /// Reinicializar servicios críticos (asegurar que permanezcan registrados)
  Future<void> _reinitializeServices() async {
    try {
      // Verificar que servicios críticos estén registrados
      final criticalServices = [
        'UserPreferencesService',
        'ThemeService',
        'DebugConsoleService',
      ];
      
      for (final serviceName in criticalServices) {
        try {
          if (!Get.isRegistered(tag: serviceName)) {
            DebugLog.w('Critical service $serviceName not registered, attempting to register', category: LogCategory.app);
            
            // Intentar registrar servicios críticos si no están registrados
            switch (serviceName) {
              case 'ThemeService':
                if (!Get.isRegistered<ThemeService>()) {
                  Get.put(ThemeService(), permanent: true);
                  DebugLog.i('Re-registered ThemeService', category: LogCategory.app);
                }
                break;
              case 'UserPreferencesService':
                if (!Get.isRegistered<UserPreferencesService>()) {
                  Get.put(UserPreferencesService(), permanent: true);
                  DebugLog.i('Re-registered UserPreferencesService', category: LogCategory.app);
                }
                break;
              case 'DebugConsoleService':
                if (!Get.isRegistered<DebugConsoleService>()) {
                  Get.put(DebugConsoleService(), permanent: true);
                  DebugLog.i('Re-registered DebugConsoleService', category: LogCategory.app);
                }
                break;
            }
          } else {
            // Servicio está registrado, solo actualizar
            final service = Get.find(tag: serviceName);
            if (service is GetxController) {
              service.update();
              DebugLog.i('Updated service: $serviceName', category: LogCategory.app);
            }
          }
        } catch (e) {
          DebugLog.w('Could not handle service $serviceName: $e', category: LogCategory.app);
        }
      }
      
    } catch (e) {
      DebugLog.e('Error reinitializing services: $e', category: LogCategory.app);
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
  
  /// Forzar actualización completa del tema en toda la aplicación
  Future<void> forceThemeUpdate() async {
    try {
      // Notificar a todos los listeners
      update();
      
      // Forzar reconstrucción de la aplicación
      Get.forceAppUpdate();
      
      // Esperar un poco y forzar otra vez
      await Future.delayed(const Duration(milliseconds: 50));
      Get.forceAppUpdate();
      
      DebugLog.i('Theme force update completed', category: LogCategory.app);
    } catch (e) {
      DebugLog.e('Error forcing theme update: $e', category: LogCategory.app);
    }
  }
  
  /// Obtener información del tema actual para debugging
  Map<String, dynamic> getThemeInfo() {
    return {
      'currentTheme': _getStringFromThemeMode(_themeMode.value),
      'isDarkMode': isDarkMode,
      'systemDarkMode': Get.isPlatformDarkMode,
      'themeModeValue': _themeMode.value.toString(),
    };
  }
}