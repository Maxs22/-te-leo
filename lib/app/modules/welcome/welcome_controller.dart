import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/onboarding_overlay.dart';
import '../../core/services/debug_console_service.dart';
import '../../core/services/version_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/services/voice_setup_service.dart';
import '../../data/providers/configuracion_provider.dart';
import '../../data/providers/database_provider.dart';
import '../../data/models/configuracion_usuario.dart';
import '../../../global_widgets/global_widgets.dart';

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
  String get userName => _prefsService?.userName.isNotEmpty == true ? _prefsService!.userName : 'Usuario';
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
    // Mostrar onboarding automáticamente si es primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mostrarOnboarding();
    });
  }
  
  /// Inicializar servicios de forma segura
  void _initializeServices() {
    try {
      _prefsService = Get.find<UserPreferencesService>();
      _versionService = Get.find<VersionService>();
      
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
      DebugLog.w('Services not available yet, using defaults', category: LogCategory.ui);
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

  /// Muestra el onboarding directamente
  void mostrarOnboarding() {
    // Verificar si ya vio el onboarding
    if (_prefsService != null && _prefsService!.hasSeenOnboarding) {
      // Si ya lo vio, ir directo a home
      Get.offNamed('/home');
      return;
    }
    
    // Mostrar onboarding completo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLog.i('Showing onboarding overlay', category: LogCategory.ui);
      _showOnboardingSteps();
    });
  }

  /// Muestra los pasos del onboarding
  void _showOnboardingSteps() {
    final steps = [
      OnboardingStep(
        title: 'onboarding_step1_title'.tr,
        description: 'onboarding_step1_description'.tr,
        icon: Icons.camera_alt,
        color: Get.theme.colorScheme.primary,
      ),
      OnboardingStep(
        title: 'onboarding_step2_title'.tr,
        description: 'onboarding_step2_description'.tr,
        icon: Icons.record_voice_over,
        color: Get.theme.colorScheme.secondary,
      ),
      OnboardingStep(
        title: 'onboarding_step3_title'.tr,
        description: 'onboarding_step3_description'.tr,
        icon: Icons.library_books,
        color: Get.theme.colorScheme.tertiary,
      ),
      OnboardingStep(
        title: 'onboarding_step4_title'.tr,
        description: 'onboarding_step4_description'.tr,
        icon: Icons.translate,
        color: Get.theme.colorScheme.primary,
      ),
      OnboardingStep(
        title: 'onboarding_step5_title'.tr,
        description: 'onboarding_step5_description'.tr,
        icon: Icons.accessibility,
        color: Get.theme.colorScheme.secondary,
      ),
    ];

    OnboardingOverlay.show(
      steps: steps,
      onCompleted: () {
        DebugLog.i('Onboarding completed', category: LogCategory.ui);
        enterApp();
      },
      canSkip: true,
    );
  }

  /// Ingresa a la aplicación principal
  Future<void> enterApp() async {
    // Marcar onboarding como visto
    if (_prefsService != null) {
      _prefsService!.markOnboardingAsSeen();
    }
    
    DebugLog.i('User entering main app', category: LogCategory.navigation);
    
    // Verificar configuración de voces antes de continuar
    await _checkVoiceSetup();
    
    // Actualizar fecha de último uso y días consecutivos
    _updateUserStats();
    
    // Navegar a la pantalla principal
    Get.offNamed('/home');
  }

  /// Verifica y configura voces TTS si es necesario
  Future<void> _checkVoiceSetup() async {
    try {
      final voiceSetupService = Get.find<VoiceSetupService>();
      final hasGoodSetup = await voiceSetupService.hasGoodVoiceSetup();
      
      if (!hasGoodSetup) {
        DebugLog.i('Voice setup needed, showing voice installation guide', category: LogCategory.service);
        await voiceSetupService.checkAndSetupVoices();
      } else {
        DebugLog.i('Voice setup is good, proceeding to app', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.w('VoiceSetupService not available, skipping voice check: $e', category: LogCategory.service);
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
        contenido: 'Escanear Texto: Usa la cámara para extraer texto\n\n'
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
        DebugLog.i('Real statistics loaded: ${documentos.length} docs, ${_minutesListened.value} min', 
                   category: LogCategory.ui);
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.e('Error loading real statistics: $e', category: LogCategory.ui);
      });
    }
  }

  /// Verificar si es la primera vez del usuario
  void _checkFirstTime() {
    if (_prefsService == null) return;
    
    // Verificar si ya vio el onboarding
    if (!_prefsService!.hasSeenOnboarding) {
      // Log después del build para evitar ciclos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i('First time user detected, showing onboarding', category: LogCategory.ui);
      });
      
      // Onboarding se maneja en mostrarOnboarding() - eliminar duplicado
    }
    
    // Registrar uso diario
    _prefsService?.registerDailyUsage();
    
    // Marcar primera apertura si es necesario
    if (_prefsService?.isFirstLaunch == true) {
      _prefsService?.markFirstLaunch();
    }
  }

  /// Mostrar información de premium
  void showPremiumInfo() {
    DebugLog.i('Showing premium info', category: LogCategory.ui);
    
    if (isPremium) {
      Get.dialog(
        ModernDialog(
          titulo: 'Te Leo Premium',
          contenido: 'Premium Activo\n\n'
                     '• Voces premium adicionales\n'
                     '• Exportación de documentos\n'
                     '• Sincronización en la nube\n'
                     '• Soporte prioritario\n'
                     '• Sin anuncios\n'
                     '• Funciones beta',
          textoBotonPrimario: 'Genial',
          onBotonPrimario: () => Get.back(),
        ),
      );
    } else {
      Get.toNamed('/subscription');
    }
  }
}
