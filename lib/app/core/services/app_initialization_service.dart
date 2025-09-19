import 'package:get/get.dart';
import 'debug_console_service.dart';
import 'error_service.dart';
import 'tts_service.dart';
import 'ocr_service.dart';
import 'camera_service.dart';
import 'reading_progress_service.dart';
import 'app_update_service.dart';
import 'version_service.dart';
import 'enhanced_tts_service.dart';
import 'subscription_service.dart';
import 'device_security_service.dart';
import 'reading_reminder_service.dart';
import 'translation_service.dart';
import 'voice_setup_service.dart';

/// Estados de inicialización de la aplicación
enum InitializationState {
  notStarted,
  initializing,
  completed,
  failed,
}

/// Servicio de inicialización optimizada de la aplicación
/// Maneja la carga asíncrona de servicios pesados para evitar bloquear la UI
class AppInitializationService extends GetxService {
  /// Estado actual de la inicialización
  final Rx<InitializationState> _state = InitializationState.notStarted.obs;
  InitializationState get state => _state.value;

  /// Progreso de inicialización (0.0 - 1.0)
  final RxDouble _progress = 0.0.obs;
  double get progress => _progress.value;

  /// Mensaje de estado actual
  final RxString _statusMessage = ''.obs;
  String get statusMessage => _statusMessage.value;

  /// Lista de servicios inicializados
  final RxList<String> _initializedServices = <String>[].obs;
  List<String> get initializedServices => _initializedServices;

  /// Indica si la inicialización está completa
  bool get isCompleted => _state.value == InitializationState.completed;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  /// Inicializa la aplicación de forma optimizada
  Future<void> _initializeApp() async {
    _state.value = InitializationState.initializing;
    _progress.value = 0.0;
    
    try {
      // Servicios críticos primero (síncronos y rápidos)
      await _initializeCriticalServices();
      
      // Servicios pesados en background (asíncronos)
      _initializeHeavyServicesInBackground();
      
      _state.value = InitializationState.completed;
      DebugLog.service('App initialization completed', serviceName: 'AppInit');
      
    } catch (e) {
      _state.value = InitializationState.failed;
      DebugLog.e('App initialization failed: $e', 
                 category: LogCategory.app, 
                 stackTrace: e.toString());
    }
  }

  /// Inicializa servicios críticos que deben estar listos inmediatamente
  Future<void> _initializeCriticalServices() async {
    final criticalServices = [
      () async {
        _updateStatus('Inicializando sistema de debug...', 0.1);
        Get.put(DebugConsoleService(), permanent: true);
        _initializedServices.add('DebugConsole');
      },
      
      () async {
        _updateStatus('Inicializando manejo de errores...', 0.2);
        Get.put(ErrorService(), permanent: true);
        _initializedServices.add('ErrorService');
      },
      
      () async {
        _updateStatus('Inicializando progreso de lectura...', 0.3);
        Get.put(ReadingProgressService(), permanent: true);
        _initializedServices.add('ReadingProgress');
      },
      
      () async {
        _updateStatus('Inicializando servicio de actualizaciones...', 0.45);
        Get.put(AppUpdateService(), permanent: true);
        _initializedServices.add('AppUpdateService');
      },
      
      () async {
        _updateStatus('Inicializando servicio de versión...', 0.47);
        Get.put(VersionService(), permanent: true);
        _initializedServices.add('VersionService');
      },
      
      () async {
        _updateStatus('Inicializando servicio de suscripciones...', 0.49);
        Get.put(SubscriptionService(), permanent: true);
        _initializedServices.add('SubscriptionService');
      },
      
      () async {
        _updateStatus('Inicializando seguridad del dispositivo...', 0.51);
        Get.put(DeviceSecurityService(), permanent: true);
        _initializedServices.add('DeviceSecurityService');
      },
      
      () async {
        _updateStatus('Inicializando recordatorios de lectura...', 0.55);
        Get.put(ReadingReminderService(), permanent: true);
        _initializedServices.add('ReadingReminderService');
      },
      
      () async {
        _updateStatus('Configurando sistema de voces...', 0.60);
        Get.put(VoiceSetupService(), permanent: true);
        _initializedServices.add('VoiceSetupService');
      },
    ];

    for (int i = 0; i < criticalServices.length; i++) {
      await criticalServices[i]();
      await Future.delayed(const Duration(milliseconds: 50)); // Permitir que la UI respire
    }
    
    _progress.value = 0.5;
  }

  /// Inicializa servicios pesados en background
  void _initializeHeavyServicesInBackground() {
    // Estos servicios se inicializan de forma lazy cuando se necesiten
    // pero preparamos su registro para evitar delays posteriores
    
    Future.microtask(() async {
      try {
        _updateStatus('Preparando servicios de cámara...', 0.6);
        // Pre-registrar pero no inicializar inmediatamente
        Get.lazyPut<CameraService>(() => CameraService(), fenix: true);
        _initializedServices.add('CameraService (lazy)');
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        _updateStatus('Preparando reconocimiento de texto...', 0.7);
        Get.lazyPut<OCRService>(() => OCRService(), fenix: true);
        _initializedServices.add('OCRService (lazy)');
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        _updateStatus('Preparando síntesis de voz...', 0.8);
        Get.lazyPut<TTSService>(() => TTSService(), fenix: true);
        _initializedServices.add('TTSService (lazy)');
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        _updateStatus('Preparando TTS avanzado...', 0.85);
        Get.lazyPut<EnhancedTTSService>(() => EnhancedTTSService(), fenix: true);
        _initializedServices.add('EnhancedTTSService (lazy)');
        
        // Servicio de traducción
        Get.lazyPut<TranslationService>(() => TranslationService(), fenix: true);
        _initializedServices.add('TranslationService (lazy)');
        
        _updateStatus('Inicialización completa', 1.0);
        
        DebugLog.service('Heavy services registered for lazy loading', serviceName: 'AppInit');
        
      } catch (e) {
        DebugLog.e('Error in background initialization: $e', category: LogCategory.service);
      }
    });
  }

  /// Actualiza el estado y progreso
  void _updateStatus(String message, double progress) {
    _statusMessage.value = message;
    _progress.value = progress;
    DebugLog.d('Init: $message (${(progress * 100).round()}%)', category: LogCategory.app);
  }

  /// Fuerza la inicialización de un servicio específico
  Future<T> ensureServiceInitialized<T>() async {
    if (!Get.isRegistered<T>()) {
      DebugLog.w('Service ${T.toString()} not registered, initializing...', category: LogCategory.service);
      
      // Registrar servicios según el tipo
      if (T == CameraService) {
        Get.put<CameraService>(CameraService());
      } else if (T == OCRService) {
        Get.put<OCRService>(OCRService());
      } else if (T == TTSService) {
        Get.put<TTSService>(TTSService());
      }
    }
    
    return Get.find<T>();
  }

  /// Pre-carga servicios que se usarán pronto
  Future<void> preloadServices(List<Type> serviceTypes) async {
    for (final type in serviceTypes) {
      try {
        if (type == CameraService) {
          await ensureServiceInitialized<CameraService>();
        } else if (type == OCRService) {
          await ensureServiceInitialized<OCRService>();
        } else if (type == TTSService) {
          await ensureServiceInitialized<TTSService>();
        }
        
        DebugLog.d('Preloaded service: ${type.toString()}', category: LogCategory.service);
      } catch (e) {
        DebugLog.e('Failed to preload service ${type.toString()}: $e', category: LogCategory.service);
      }
    }
  }

  /// Obtiene estadísticas de inicialización
  Map<String, dynamic> getInitializationStats() {
    return {
      'state': _state.value.toString().split('.').last,
      'progress': _progress.value,
      'status_message': _statusMessage.value,
      'initialized_services': _initializedServices.length,
      'services_list': _initializedServices.toList(),
    };
  }

  /// Reinicia la inicialización (útil para debugging)
  Future<void> reinitialize() async {
    DebugLog.w('Reinitializing app services...', category: LogCategory.service);
    _state.value = InitializationState.notStarted;
    _initializedServices.clear();
    await _initializeApp();
  }
}
