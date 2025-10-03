import 'package:get/get.dart';

import 'ads_service.dart';
import 'ads_strategy_service.dart';
import 'app_install_service.dart';
import 'app_update_service.dart';
import 'camera_service.dart';
import 'debug_console_service.dart';
import 'device_security_service.dart';
import 'enhanced_tts_service.dart';
import 'error_service.dart';
import 'language_service.dart';
import 'notification_service.dart';
import 'ocr_service.dart';
import 'premium_manager_service.dart';
import 'reading_progress_service.dart';
import 'reading_reminder_service.dart';
import 'route_service.dart';
import 'subscription_service.dart';
import 'theme_service.dart';
import 'tts_service.dart';
import 'usage_limits_service.dart';
import 'user_preferences_service.dart';
import 'version_service.dart';
import 'voice_setup_service.dart';

/// Servicio responsable de la inicialización completa de la aplicación
/// Sigue el patrón Bootstrap y principios SOLID
class AppBootstrapService extends GetxService {
  final RxBool _isInitialized = false.obs;
  final RxString _initializationStatus = 'Iniciando...'.obs;
  final RxDouble _initializationProgress = 0.0.obs;

  bool get isInitialized => _isInitialized.value;
  String get initializationStatus => _initializationStatus.value;
  double get initializationProgress => _initializationProgress.value;

  /// Inicializa todos los servicios críticos de la aplicación
  Future<void> initializeApp() async {
    try {
      print('🚀 Starting application bootstrap process');

      await _initializeCriticalServices();
      await _initializeAppServices();
      await _initializeHeavyServices();

      _isInitialized.value = true;
      _initializationStatus.value = 'Aplicación inicializada correctamente';
      _initializationProgress.value = 1.0;

      print('✅ Application bootstrap completed successfully');
    } catch (e) {
      print('❌ Error during application bootstrap: $e');
      _initializationStatus.value = 'Error en inicialización: $e';
      rethrow;
    }
  }

  /// Inicializa servicios críticos que deben estar disponibles inmediatamente
  Future<void> _initializeCriticalServices() async {
    _updateStatus('Inicializando servicios críticos...', 0.05);

    // 1. DebugConsoleService - PRIMERO para logging
    await _initializeService<DebugConsoleService>(() => DebugConsoleService(), 'DebugConsoleService', 0.08);

    // 2. AppInstallService
    await _initializeService<AppInstallService>(() => AppInstallService(), 'AppInstallService', 0.12);

    // 3. ErrorService
    await _initializeService<ErrorService>(() => ErrorService(), 'ErrorService', 0.15);

    // 4. UserPreferencesService
    await _initializeService<UserPreferencesService>(() => UserPreferencesService(), 'UserPreferencesService', 0.20);

    // 5. ThemeService
    await _initializeService<ThemeService>(() => ThemeService(), 'ThemeService', 0.25);

    // 6. LanguageService
    await _initializeService<LanguageService>(() => LanguageService(), 'LanguageService', 0.30);

    // 7. RouteService
    await _initializeService<RouteService>(() => RouteService(), 'RouteService', 0.35);

    print('✅ Critical services initialized');
  }

  /// Inicializa servicios de la aplicación
  Future<void> _initializeAppServices() async {
    _updateStatus('Inicializando servicios de aplicación...', 0.40);

    // 8. AppUpdateService
    await _initializeService<AppUpdateService>(() => AppUpdateService(), 'AppUpdateService', 0.42);

    // 9. VersionService
    await _initializeService<VersionService>(() => VersionService(), 'VersionService', 0.44);

    // 10. SubscriptionService (necesario para PremiumBadge)
    await _initializeService<SubscriptionService>(() => SubscriptionService(), 'SubscriptionService', 0.48);

    // 11. DeviceSecurityService
    await _initializeService<DeviceSecurityService>(() => DeviceSecurityService(), 'DeviceSecurityService', 0.52);

    // 12. ReadingReminderService
    await _initializeService<ReadingReminderService>(() => ReadingReminderService(), 'ReadingReminderService', 0.55);

    // 13. NotificationService
    await _initializeService<NotificationService>(() => NotificationService(), 'NotificationService', 0.58);

    // 14. TTSService
    await _initializeService<TTSService>(() => TTSService(), 'TTSService', 0.62);

    // 15. VoiceSetupService
    await _initializeService<VoiceSetupService>(() => VoiceSetupService(), 'VoiceSetupService', 0.66);

    // 16. PremiumManagerService
    await _initializeService<PremiumManagerService>(() => PremiumManagerService(), 'PremiumManagerService', 0.70);

    // 17. UsageLimitsService
    await _initializeService<UsageLimitsService>(() => UsageLimitsService(), 'UsageLimitsService', 0.74);

    // 18. ReadingProgressService
    await _initializeService<ReadingProgressService>(() => ReadingProgressService(), 'ReadingProgressService', 0.78);

    // 19. AdsService - Sistema de anuncios
    await _initializeService<AdsService>(() => AdsService(), 'AdsService', 0.85);

    // 20. AdsStrategyService - Estrategia de anuncios
    await _initializeService<AdsStrategyService>(() => AdsStrategyService(), 'AdsStrategyService', 0.90);

    print('✅ App services initialized');
  }

  /// Inicializa servicios pesados de forma lazy
  Future<void> _initializeHeavyServices() async {
    _updateStatus('Preparando servicios pesados...', 0.95);

    // Servicios pesados se inicializan de forma lazy cuando se necesiten
    Get.lazyPut<CameraService>(() => CameraService(), fenix: true);
    Get.lazyPut<OCRService>(() => OCRService(), fenix: true);
    Get.lazyPut<EnhancedTTSService>(() => EnhancedTTSService(), fenix: true);

    print('✅ Heavy services registered (lazy)');
  }

  /// Helper para inicializar un servicio individual
  Future<T> _initializeService<T>(T Function() serviceFactory, String serviceName, double progress) async {
    try {
      // Solo registrar si no existe
      if (!Get.isRegistered<T>()) {
        _updateStatus('Inicializando $serviceName...', progress);
        final service = serviceFactory();
        Get.put(service, permanent: true);
        print('✅ $serviceName initialized');
      } else {
        print('ℹ️  $serviceName already registered');
      }

      return Get.find<T>();
    } catch (e) {
      print('❌ Error initializing $serviceName: $e');
      rethrow;
    }
  }

  /// Actualiza el estado de inicialización
  void _updateStatus(String status, double progress) {
    _initializationStatus.value = status;
    _initializationProgress.value = progress;
  }

  /// Verifica si todos los servicios críticos están disponibles
  bool areCriticalServicesAvailable() {
    return Get.isRegistered<UserPreferencesService>() &&
        Get.isRegistered<ThemeService>() &&
        Get.isRegistered<LanguageService>() &&
        Get.isRegistered<SubscriptionService>();
  }

  /// Verifica si el usuario ya vio el onboarding
  bool hasUserSeenOnboarding() {
    try {
      if (Get.isRegistered<UserPreferencesService>()) {
        final userPrefs = Get.find<UserPreferencesService>();
        return userPrefs.hasSeenOnboarding;
      }
      return false;
    } catch (e) {
      print('❌ Error checking onboarding status: $e');
      return false;
    }
  }

  /// Obtiene información de debug sobre el estado de inicialización
  Map<String, dynamic> getBootstrapInfo() {
    return {
      'isInitialized': _isInitialized.value,
      'initializationStatus': _initializationStatus.value,
      'initializationProgress': _initializationProgress.value,
      'criticalServicesAvailable': areCriticalServicesAvailable(),
      'registeredServices': _getRegisteredServices(),
    };
  }

  /// Obtiene lista de servicios registrados
  List<String> _getRegisteredServices() {
    final services = <String>[];

    if (Get.isRegistered<DebugConsoleService>()) services.add('DebugConsoleService');
    if (Get.isRegistered<UserPreferencesService>()) services.add('UserPreferencesService');
    if (Get.isRegistered<ThemeService>()) services.add('ThemeService');
    if (Get.isRegistered<LanguageService>()) services.add('LanguageService');
    if (Get.isRegistered<RouteService>()) services.add('RouteService');
    if (Get.isRegistered<AppUpdateService>()) services.add('AppUpdateService');
    if (Get.isRegistered<SubscriptionService>()) services.add('SubscriptionService');
    if (Get.isRegistered<AdsService>()) services.add('AdsService');
    if (Get.isRegistered<TTSService>()) services.add('TTSService');

    return services;
  }

  /// Reinicializa la aplicación (útil para testing)
  Future<void> reinitializeApp() async {
    print('🔄 Reinitializing application...');

    _isInitialized.value = false;
    _initializationStatus.value = 'Reinicializando...';
    _initializationProgress.value = 0.0;

    // Limpiar servicios existentes
    Get.reset();

    // Reinicializar
    await initializeApp();
  }
}
