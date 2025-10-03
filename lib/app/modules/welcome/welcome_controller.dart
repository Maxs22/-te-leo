import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:te_leo/app/core/services/reading_reminder_service.dart';

import '../../../global_widgets/global_widgets.dart';
import '../../core/services/debug_console_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/services/version_service.dart';
import '../../core/services/voice_setup_service.dart';
import '../../data/models/configuracion_usuario.dart';
import '../../data/providers/configuracion_provider.dart';
import '../../data/providers/database_provider.dart';

/// Controlador para la pantalla de bienvenida
class WelcomeController extends GetxController {
  final ConfiguracionProvider _configProvider = ConfiguracionProvider();
  final DatabaseProvider _databaseProvider = DatabaseProvider();
  UserPreferencesService? _prefsService;
  VersionService? _versionService;

  // Estado reactivo
  final Rx<ConfiguracionUsuario?> _userConfig = Rx<ConfiguracionUsuario?>(null);
  final RxString _currentGreeting = ''.obs;
  final RxString _currentMotivation = ''.obs;
  final RxInt _documentsScanned = 0.obs;
  final RxInt _minutesListened = 0.obs;
  final RxInt _streakDays = 1.obs;
  final RxBool _isPremium = false.obs;
  final RxString _appVersion = '1.0.0'.obs;

  // Timer para cambiar mensajes
  Timer? _messageTimer;

  // Getters reactivos
  String get userName => _prefsService?.userName.isNotEmpty == true ? _prefsService!.userName : '';
  String get greetingMessage => _currentGreeting.value;
  String get motivationalMessage => _currentMotivation.value;
  int get documentsScanned => _documentsScanned.value;
  int get minutesListened => _minutesListened.value;
  int get streakDays => _streakDays.value;
  bool get isPremium => _isPremium.value;
  String get appVersion => _appVersion.value;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadUserData();
    _setupGreetingMessages();
    _startMessageRotation();

    // Verificar si ya vio el onboarding después de un pequeño delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_prefsService?.hasSeenOnboarding == true) {
        // Si ya vio el onboarding, ir directamente a la app
        Future.delayed(const Duration(milliseconds: 500), () {
          enterApp();
        });
      } else {
        // Si no vio el onboarding, navegar directamente al onboarding
        // La pantalla de carga real ya se mostró durante el bootstrap

        // Navegar después de un breve delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToApp();
        });
      }
    });
  }

  /// Inicializar servicios de forma segura
  void _initializeServices() {
    try {
      _prefsService = Get.find<UserPreferencesService>();
      _versionService = Get.find<VersionService>();

      DebugLog.i('Services initialized successfully', category: LogCategory.service);
      DebugLog.i('hasSeenOnboarding: ${_prefsService?.hasSeenOnboarding}', category: LogCategory.service);

      // Actualizar estadísticas desde preferencias si están disponibles
      if (_prefsService != null) {
        _documentsScanned.value = _prefsService!.documentsScanned;
        _minutesListened.value = _prefsService!.minutesListened;
        _streakDays.value = _prefsService!.consecutiveDays;
        _isPremium.value = _prefsService!.isPremiumActive();
      }

      // Actualizar versión de la app
      if (_versionService != null) {
        _appVersion.value = _versionService!.version;
      }
    } catch (e) {
      DebugLog.w('Services not available yet, using defaults: $e', category: LogCategory.ui);
    }
  }

  @override
  void onClose() {
    _messageTimer?.cancel();
    super.onClose();
  }

  /// Carga los datos del usuario
  Future<void> _loadUserData() async {
    try {
      final config = await _configProvider.obtenerConfiguracion();
      _userConfig.value = config;

      // Cargar estadísticas reales desde la base de datos
      await _loadRealStatistics();

      // También usar datos de configuración como respaldo
      if (_documentsScanned.value == 0) {
        _documentsScanned.value = config.documentosEscaneados;
      }
      if (_minutesListened.value == 0) {
        _minutesListened.value = config.minutosEscuchados;
      }
      _streakDays.value = _calculateStreakDays(config);

      // Actualizar estado premium y versión
      if (_prefsService != null) {
        _isPremium.value = _prefsService!.isPremiumActive();
      }
      if (_versionService != null) {
        _appVersion.value = _versionService!.version;
      }

      // Log después del build para evitar ciclos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i('User data loaded: ${config.nombreUsuario}', category: LogCategory.ui);
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.e('Error loading user data: $e', category: LogCategory.ui);
      });
      // Crear configuración por defecto
      _userConfig.value = ConfiguracionUsuario.nuevoUsuario('Usuario');
    }
  }

  /// Configura los mensajes de saludo
  void _setupGreetingMessages() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      _currentGreeting.value = '¡Buenos días!';
    } else if (hour >= 12 && hour < 18) {
      _currentGreeting.value = '¡Buenas tardes!';
    } else {
      _currentGreeting.value = '¡Buenas noches!';
    }

    _updateMotivationalMessage();
  }

  /// Actualiza el mensaje motivacional
  void _updateMotivationalMessage() {
    final messages = [
      'Listo para explorar nuevos textos',
      'Tu herramienta de lectura accesible',
      'Convierte cualquier texto en audio',
      'Descubre el poder de la lectura asistida',
      'Tu biblioteca personal te espera',
      'Cada palabra cuenta, cada historia importa',
      'Rompe las barreras de la lectura',
      'Tu voz digital está aquí',
    ];

    // Elegir mensaje basado en estadísticas del usuario
    if (_documentsScanned.value == 0) {
      _currentMotivation.value = 'Comienza tu primera experiencia de lectura';
    } else if (_documentsScanned.value < 5) {
      _currentMotivation.value = 'Continúa explorando nuevos textos';
    } else {
      final index = DateTime.now().millisecond % messages.length;
      _currentMotivation.value = messages[index];
    }
  }

  /// Inicia la rotación de mensajes
  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _updateMotivationalMessage();
    });
  }

  /// Calcula los días consecutivos de uso
  int _calculateStreakDays(ConfiguracionUsuario? config) {
    if (config == null) return 1;

    final lastUsed = config.fechaUltimoUso;
    final now = DateTime.now();
    final difference = now.difference(lastUsed).inDays;

    if (difference == 0) {
      return config.diasConsecutivos;
    } else if (difference == 1) {
      return config.diasConsecutivos + 1;
    } else {
      return 1; // Reiniciar racha
    }
  }

  /// Navega a la aplicación principal
  void _navigateToApp() {
    DebugLog.i('_navigateToApp called after 3 seconds', category: LogCategory.navigation);
    DebugLog.i('_prefsService available: ${_prefsService != null}', category: LogCategory.navigation);

    try {
      // Si llegamos aquí es porque main.dart determinó que debemos mostrar welcome
      // Esto significa que es la primera vez del usuario, mostrar onboarding
      DebugLog.i('First time user, showing onboarding', category: LogCategory.ui);

      // Usar un delay para asegurar que la UI esté lista
      Future.delayed(const Duration(milliseconds: 500), () {
        _showOnboardingSteps();
      });

      // Como backup, si después de 10 segundos no se ha completado el onboarding,
      // navegar directamente a home
      Future.delayed(const Duration(seconds: 10), () {
        if (Get.currentRoute == '/welcome') {
          DebugLog.w('Onboarding timeout, navigating directly to home', category: LogCategory.navigation);
          enterApp();
        }
      });
    } catch (e) {
      DebugLog.e('Error in _navigateToApp: $e', category: LogCategory.navigation);
      // En caso de error, ir directo a home
      Get.offAllNamed('/home');
    }
  }

  /// Muestra los pasos del onboarding
  void _showOnboardingSteps() {
    DebugLog.i('Showing onboarding steps', category: LogCategory.ui);

    // Verificar que las traducciones estén disponibles
    final step1Title = 'onboarding_step1_title'.tr;
    DebugLog.d('Step 1 title: $step1Title', category: LogCategory.ui);

    final steps = [
      OnboardingStep(
        title: step1Title.isNotEmpty ? step1Title : '📸 Escanea cualquier texto',
        description: 'onboarding_step1_description'.tr.isNotEmpty
            ? 'onboarding_step1_description'.tr
            : 'Toma una foto de libros, documentos, carteles o cualquier texto que quieras escuchar',
        icon: Icons.camera_alt,
        color: Get.theme.colorScheme.primary,
      ),
      OnboardingStep(
        title: 'onboarding_step2_title'.tr.isNotEmpty ? 'onboarding_step2_title'.tr : '🎧 Escucha con voz natural',
        description: 'onboarding_step2_description'.tr.isNotEmpty
            ? 'onboarding_step2_description'.tr
            : 'Te Leo convierte el texto en audio con voces naturales y configurables',
        icon: Icons.record_voice_over,
        color: Get.theme.colorScheme.secondary,
      ),
      OnboardingStep(
        title: 'onboarding_step3_title'.tr.isNotEmpty ? 'onboarding_step3_title'.tr : '📚 Guarda en tu biblioteca',
        description: 'onboarding_step3_description'.tr.isNotEmpty
            ? 'onboarding_step3_description'.tr
            : 'Todos tus documentos se guardan automáticamente para acceder cuando quieras',
        icon: Icons.library_books,
        color: Get.theme.colorScheme.tertiary,
      ),
      OnboardingStep(
        title: 'onboarding_step4_title'.tr.isNotEmpty ? 'onboarding_step4_title'.tr : '🌍 Traduce textos',
        description: 'onboarding_step4_description'.tr.isNotEmpty
            ? 'onboarding_step4_description'.tr
            : 'Convierte textos a diferentes idiomas y escúchalos en tu idioma preferido',
        icon: Icons.translate,
        color: Get.theme.colorScheme.primary,
      ),
      OnboardingStep(
        title: 'onboarding_step5_title'.tr.isNotEmpty ? 'onboarding_step5_title'.tr : '♿ Diseño accesible',
        description: 'onboarding_step5_description'.tr.isNotEmpty
            ? 'onboarding_step5_description'.tr
            : 'Optimizado para personas con baja visión y dislexia con colores y tipografía especiales',
        icon: Icons.accessibility,
        color: Get.theme.colorScheme.secondary,
      ),
    ];

    DebugLog.i('Onboarding steps prepared: ${steps.length} steps', category: LogCategory.ui);

    OnboardingOverlay.show(
      steps: steps,
      onCompleted: () {
        DebugLog.i('Onboarding completed, calling enterApp', category: LogCategory.ui);
        // Usar un pequeño delay para asegurar que el dialog se cierre correctamente
        Future.delayed(const Duration(milliseconds: 100), () {
          enterApp();
        });
      },
      canSkip: true,
    );
  }

  /// Ingresa a la aplicación principal
  Future<void> enterApp() async {
    DebugLog.i('Starting enterApp process', category: LogCategory.navigation);

    try {
      // Marcar onboarding como visto
      if (_prefsService != null) {
        await _prefsService!.markOnboardingAsSeen();
        DebugLog.i('Onboarding marked as seen', category: LogCategory.navigation);
      }

      DebugLog.i('User entering main app', category: LogCategory.navigation);

      // Actualizar fecha de último uso para notificaciones
      try {
        if (Get.isRegistered<ReadingReminderService>()) {
          final readingReminderService = Get.find<ReadingReminderService>();
          await readingReminderService.updateLastUsageDate();
        }
      } catch (e) {
        DebugLog.w('ReadingReminderService not available: $e', category: LogCategory.service);
      }

      // Verificar configuración de voces antes de continuar
      await _checkVoiceSetup();

      // Actualizar fecha de último uso y días consecutivos
      await _updateUserStats();

      // Navegar a la pantalla principal usando Get.offAllNamed para limpiar el stack
      DebugLog.i('Navigating to home screen', category: LogCategory.navigation);
      Get.offAllNamed('/home');
    } catch (e) {
      DebugLog.e('Error in enterApp: $e', category: LogCategory.navigation);
      // En caso de error, intentar navegar directamente
      Get.offAllNamed('/home');
    }
  }

  /// Verifica y configura voces TTS si es necesario
  Future<void> _checkVoiceSetup() async {
    try {
      // Verificar si el servicio está disponible
      if (!Get.isRegistered<VoiceSetupService>()) {
        DebugLog.w('VoiceSetupService not registered, skipping voice check', category: LogCategory.service);
        return;
      }

      final voiceSetupService = Get.find<VoiceSetupService>();
      final hasGoodSetup = await voiceSetupService.hasGoodVoiceSetup();

      if (!hasGoodSetup) {
        DebugLog.i('Voice setup needed, showing voice installation guide', category: LogCategory.service);
        await voiceSetupService.checkAndSetupVoices();
      } else {
        DebugLog.i('Voice setup is good, proceeding to app', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.w('VoiceSetupService error, skipping voice check: $e', category: LogCategory.service);
      // Continuar sin verificación de voces si el servicio no está disponible
    }
  }

  /// Actualiza las estadísticas del usuario
  Future<void> _updateUserStats() async {
    if (_userConfig.value != null) {
      final updatedConfig = _userConfig.value!.copyWith(
        fechaUltimoUso: DateTime.now(),
        diasConsecutivos: _streakDays.value,
      );

      try {
        await _configProvider.guardarConfiguracion(updatedConfig);
        DebugLog.d('User stats updated', category: LogCategory.database);
      } catch (e) {
        DebugLog.e('Error updating user stats: $e', category: LogCategory.database);
      }
    }
  }

  /// Navega a configuraciones
  void goToSettings() {
    DebugLog.i('Navigating to settings from welcome', category: LogCategory.navigation);
    Get.toNamed('/settings');
  }

  /// Muestra la ayuda
  void showHelp() {
    DebugLog.i('Showing help dialog', category: LogCategory.ui);

    Get.dialog(
      ModernDialog(
        titulo: '¿Cómo usar Te Leo?',
        contenido:
            'Escanear Texto: Usa la cámara para extraer texto\n\n'
            'Escuchar Texto: Convierte texto en audio natural\n\n'
            'Mi Biblioteca: Guarda y organiza documentos\n\n'
            'Personalizar: Ajusta configuraciones a tu gusto',
        textoBotonPrimario: 'Entendido',
        onBotonPrimario: () => Get.back(),
      ),
    );
  }

  /// Actualiza el saludo basado en la hora
  void updateGreeting() {
    _setupGreetingMessages();
  }

  /// Refresca los datos del usuario
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  /// Actualizar estadísticas cuando se agrega un documento
  Future<void> updateDocumentCount() async {
    await _loadRealStatistics();
  }

  /// Actualizar tiempo de escucha
  Future<void> updateListeningTime(int minutes) async {
    if (_prefsService != null) {
      await _prefsService!.addListeningTime(minutes);
      _minutesListened.value = _prefsService!.minutesListened;
    }
  }

  /// Carga las estadísticas reales desde la base de datos
  Future<void> _loadRealStatistics() async {
    try {
      // Contar documentos reales en la base de datos
      final documentos = await _databaseProvider.obtenerTodosLosDocumentos();
      _documentsScanned.value = documentos.length;

      // Obtener tiempo total de escucha desde SharedPreferences
      if (_prefsService != null) {
        _minutesListened.value = _prefsService!.minutesListened;
        _streakDays.value = _prefsService!.consecutiveDays;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i(
          'Real statistics loaded: ${documentos.length} docs, ${_minutesListened.value} min',
          category: LogCategory.ui,
        );
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.e('Error loading real statistics: $e', category: LogCategory.ui);
      });
    }
  }

  /// Verificar si es la primera vez del usuario

  /// Mostrar información de premium
  void showPremiumInfo() {
    DebugLog.i('Showing premium info', category: LogCategory.ui);

    if (isPremium) {
      Get.dialog(
        ModernDialog(
          titulo: 'Te Leo Premium',
          contenido:
              'Premium Activo\n\n'
              '∞ Escaneos ilimitados\n'
              '🚫 Sin anuncios\n'
              '🎧 Soporte prioritario\n'
              '🧪 Funciones beta',
          textoBotonPrimario: 'Genial',
          onBotonPrimario: () => Get.back(),
        ),
      );
    } else {
      Get.toNamed('/subscription');
    }
  }
}
