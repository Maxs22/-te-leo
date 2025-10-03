import 'package:get/get.dart';
import 'package:te_leo/app/routes/app_routes.dart';
import 'user_preferences_service.dart';
import 'app_bootstrap_service.dart';
import 'debug_console_service.dart';

/// Servicio responsable de la gestión de rutas y navegación inicial
/// Sigue principios SOLID y separación de responsabilidades
class RouteService extends GetxService {
  bool _onboardingResetApplied = false;
  
  /// Determina la ruta inicial basada en el estado de la aplicación
  String getInitialRoute() {
    try {
      DebugLog.i('Determining initial route...', category: LogCategory.navigation);
      
      // TEMPORAL: Forzar reseteo del onboarding antes de determinar la ruta (solo una vez)
      if (!_onboardingResetApplied && Get.isRegistered<UserPreferencesService>()) {
        final userPrefs = Get.find<UserPreferencesService>();
        userPrefs.forceResetOnboarding();
        _onboardingResetApplied = true;
        DebugLog.i('Onboarding reset applied before route determination', category: LogCategory.navigation);
      }
      
      // Verificar si los servicios críticos están disponibles
      if (!_areCriticalServicesAvailable()) {
        DebugLog.w('Critical services not available, defaulting to welcome', category: LogCategory.navigation);
        return AppRoutes.welcome;
      }
      
      // Verificar si el usuario ya vio el onboarding
      if (_hasUserSeenOnboarding()) {
        DebugLog.i('User has seen onboarding, navigating to home', category: LogCategory.navigation);
        return AppRoutes.home;
      } else {
        DebugLog.i('User has not seen onboarding, going directly to home with onboarding overlay', category: LogCategory.navigation);
        return AppRoutes.home;
      }
      
    } catch (e) {
      DebugLog.e('Error determining initial route: $e', category: LogCategory.navigation);
      // En caso de error, ir a home por seguridad
      return AppRoutes.home;
    }
  }

  /// Verifica si los servicios críticos están disponibles
  bool _areCriticalServicesAvailable() {
    try {
      // Verificar si el bootstrap service está disponible y completado
      if (Get.isRegistered<AppBootstrapService>()) {
        final bootstrapService = Get.find<AppBootstrapService>();
        if (!bootstrapService.isInitialized) {
          DebugLog.w('Bootstrap service not fully initialized', category: LogCategory.navigation);
          return false;
        }
      }
      
      // Verificar servicios críticos individuales
      return Get.isRegistered<UserPreferencesService>() &&
             Get.isRegistered<AppBootstrapService>();
             
    } catch (e) {
      DebugLog.e('Error checking critical services availability: $e', category: LogCategory.navigation);
      return false;
    }
  }

  /// Verifica si el usuario ya vio el onboarding
  bool _hasUserSeenOnboarding() {
    try {
      if (Get.isRegistered<UserPreferencesService>()) {
        final userPrefs = Get.find<UserPreferencesService>();
        final hasSeen = userPrefs.hasSeenOnboarding;
        DebugLog.d('User onboarding status: $hasSeen', category: LogCategory.navigation);
        return hasSeen;
      }
      return false;
    } catch (e) {
      DebugLog.e('Error checking onboarding status: $e', category: LogCategory.navigation);
      return false;
    }
  }

  /// Obtiene información de debug sobre el estado de las rutas
  Map<String, dynamic> getRouteDebugInfo() {
    return {
      'criticalServicesAvailable': _areCriticalServicesAvailable(),
      'userPreferencesRegistered': Get.isRegistered<UserPreferencesService>(),
      'bootstrapServiceRegistered': Get.isRegistered<AppBootstrapService>(),
      'bootstrapInitialized': Get.isRegistered<AppBootstrapService>() 
          ? Get.find<AppBootstrapService>().isInitialized 
          : false,
      'hasSeenOnboarding': _hasUserSeenOnboarding(),
      'initialRoute': getInitialRoute(),
    };
  }

  /// Fuerza una ruta específica (útil para testing)
  void forceRoute(String route) {
    DebugLog.w('Forcing route to: $route', category: LogCategory.navigation);
    Get.offAllNamed(route);
  }

  /// Navega a la pantalla de onboarding
  void navigateToOnboarding() {
    DebugLog.i('Navigating to onboarding', category: LogCategory.navigation);
    Get.offAllNamed(AppRoutes.welcome);
  }

  /// Navega a la pantalla principal
  void navigateToHome() {
    DebugLog.i('Navigating to home', category: LogCategory.navigation);
    Get.offAllNamed(AppRoutes.home);
  }

  /// Verifica si la aplicación está lista para mostrar la pantalla principal
  bool isAppReadyForMainScreen() {
    return _areCriticalServicesAvailable() && _hasUserSeenOnboarding();
  }

  /// Verifica si debe mostrar la pantalla de carga
  bool shouldShowLoadingScreen() {
    return Get.isRegistered<AppBootstrapService>() && 
           !Get.find<AppBootstrapService>().isInitialized;
  }
}
