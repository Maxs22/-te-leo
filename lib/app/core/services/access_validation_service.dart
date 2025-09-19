import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'debug_console_service.dart';
import 'device_security_service.dart';
import 'subscription_service.dart';
import '../../../global_widgets/global_widgets.dart';

/// Estados de validación de acceso
enum AccessValidationState {
  validating,
  granted,
  denied,
  expired,
  deviceNotSupported,
  networkRequired,
  maintenanceMode
}

/// Razones de denegación de acceso
enum AccessDeniedReason {
  expiredLicense,
  unsupportedDevice,
  rootedDevice,
  debuggerDetected,
  tampered,
  networkUnavailable,
  maintenanceMode,
  bannedDevice,
  invalidSignature,
  unknown
}

/// Resultado de validación de acceso
class AccessValidationResult {
  final AccessValidationState state;
  final AccessDeniedReason? deniedReason;
  final String message;
  final bool allowRetry;
  final DateTime? retryAfter;
  final Map<String, dynamic>? additionalData;

  const AccessValidationResult({
    required this.state,
    this.deniedReason,
    required this.message,
    this.allowRetry = false,
    this.retryAfter,
    this.additionalData,
  });

  bool get isGranted => state == AccessValidationState.granted;
  bool get isDenied => state == AccessValidationState.denied;
  bool get isValidating => state == AccessValidationState.validating;
}

/// Servicio de validación de acceso a la aplicación
class AccessValidationService extends GetxService {
  static AccessValidationService get to => Get.find();

  // Estado reactivo
  final Rx<AccessValidationState> _state = AccessValidationState.validating.obs;
  final RxString _message = 'Verificando acceso...'.obs;
  final RxBool _allowRetry = false.obs;
  final Rx<DateTime?> _retryAfter = Rx<DateTime?>(null);

  // Getters reactivos
  AccessValidationState get state => _state.value;
  String get message => _message.value;
  bool get allowRetry => _allowRetry.value;
  DateTime? get retryAfter => _retryAfter.value;

  // Configuración
  bool _enableDeviceValidation = true;
  bool _enableLicenseValidation = true;
  bool _enableSecurityValidation = true;
  bool _enableMaintenanceCheck = false;
  Duration _validationTimeout = const Duration(seconds: 10);

  @override
  void onInit() {
    super.onInit();
    DebugLog.i('AccessValidationService initialized', category: LogCategory.security);
  }

  /// Configurar validaciones habilitadas
  void configure({
    bool? enableDeviceValidation,
    bool? enableLicenseValidation,
    bool? enableSecurityValidation,
    bool? enableMaintenanceCheck,
    Duration? validationTimeout,
  }) {
    _enableDeviceValidation = enableDeviceValidation ?? _enableDeviceValidation;
    _enableLicenseValidation = enableLicenseValidation ?? _enableLicenseValidation;
    _enableSecurityValidation = enableSecurityValidation ?? _enableSecurityValidation;
    _enableMaintenanceCheck = enableMaintenanceCheck ?? _enableMaintenanceCheck;
    _validationTimeout = validationTimeout ?? _validationTimeout;

    DebugLog.d('AccessValidation configured: device=$_enableDeviceValidation, '
               'license=$_enableLicenseValidation, security=$_enableSecurityValidation',
               category: LogCategory.security);
  }

  /// Validar acceso completo
  Future<AccessValidationResult> validateAccess() async {
    try {
      _updateState(AccessValidationState.validating, 'Verificando acceso...');
      
      DebugLog.i('Starting access validation', category: LogCategory.security);

      // Timeout para toda la validación
      final result = await Future.any([
        _performValidation(),
        Future.delayed(_validationTimeout, () => const AccessValidationResult(
          state: AccessValidationState.denied,
          deniedReason: AccessDeniedReason.networkUnavailable,
          message: 'Tiempo de validación agotado',
          allowRetry: true,
        )),
      ]);

      // Actualizar estado según resultado
      _updateState(
        result.state,
        result.message,
        allowRetry: result.allowRetry,
        retryAfter: result.retryAfter,
      );

      DebugLog.i('Access validation completed: ${result.state}', 
                 category: LogCategory.security);

      return result;

    } catch (e) {
      DebugLog.e('Error in access validation: $e', category: LogCategory.security);
      
      const result = AccessValidationResult(
        state: AccessValidationState.denied,
        deniedReason: AccessDeniedReason.unknown,
        message: 'Error inesperado durante la validación',
        allowRetry: true,
      );

      _updateState(result.state, result.message, allowRetry: result.allowRetry);
      return result;
    }
  }

  /// Realizar todas las validaciones
  Future<AccessValidationResult> _performValidation() async {
    // 1. Validación de modo mantenimiento
    if (_enableMaintenanceCheck) {
      final maintenanceResult = await _checkMaintenanceMode();
      if (!maintenanceResult.isGranted) return maintenanceResult;
    }

    // 2. Validación de dispositivo
    if (_enableDeviceValidation) {
      final deviceResult = await _validateDevice();
      if (!deviceResult.isGranted) return deviceResult;
    }

    // 3. Validación de seguridad
    if (_enableSecurityValidation) {
      final securityResult = await _validateSecurity();
      if (!securityResult.isGranted) return securityResult;
    }

    // 4. Validación de licencia
    if (_enableLicenseValidation) {
      final licenseResult = await _validateLicense();
      if (!licenseResult.isGranted) return licenseResult;
    }

    // Todas las validaciones pasaron
    return const AccessValidationResult(
      state: AccessValidationState.granted,
      message: 'Acceso autorizado',
    );
  }

  /// Verificar modo mantenimiento
  Future<AccessValidationResult> _checkMaintenanceMode() async {
    _updateState(AccessValidationState.validating, 'Verificando estado del servicio...');
    
    await Future.delayed(const Duration(milliseconds: 500)); // Simular verificación

    // En producción, esto consultaría un servicio remoto
    const isMaintenanceMode = false; // Configurar según necesidad
    
    if (isMaintenanceMode) {
      return AccessValidationResult(
        state: AccessValidationState.denied,
        deniedReason: AccessDeniedReason.maintenanceMode,
        message: 'Te Leo está en mantenimiento.\nIntenta nuevamente en unos minutos.',
        allowRetry: true,
        retryAfter: DateTime.now().add(const Duration(minutes: 10)),
      );
    }

    DebugLog.d('Maintenance check passed', category: LogCategory.security);
    return const AccessValidationResult(
      state: AccessValidationState.granted,
      message: 'Servicio disponible',
    );
  }

  /// Validar dispositivo
  Future<AccessValidationResult> _validateDevice() async {
    _updateState(AccessValidationState.validating, 'Verificando dispositivo...');
    
    try {
      // Usar el servicio de seguridad del dispositivo
      final securityService = Get.find<DeviceSecurityService>();
      final securityResult = await securityService.performSecurityCheck();

      if (!securityResult.allowAccess) {
        String message = 'Dispositivo no seguro detectado.';
        AccessDeniedReason reason = AccessDeniedReason.unknown;

        if (securityResult.issues.contains('Dispositivo rooteado/jailbreakeado detectado')) {
          reason = AccessDeniedReason.rootedDevice;
          message = 'Te Leo no puede ejecutarse en dispositivos rooteados\npor razones de seguridad.';
        } else if (securityResult.issues.contains('Debugger externo detectado')) {
          reason = AccessDeniedReason.debuggerDetected;
          message = 'Debugger detectado. Acceso denegado.';
        } else if (securityResult.issues.contains('Integridad de la aplicación comprometida')) {
          reason = AccessDeniedReason.tampered;
          message = 'La aplicación ha sido modificada.\nReinstala desde la tienda oficial.';
        }

        return AccessValidationResult(
          state: AccessValidationState.denied,
          deniedReason: reason,
          message: message,
          allowRetry: false,
          additionalData: securityResult.details,
        );
      }

      // Verificar compatibilidad básica
      if (!_isDeviceSupported()) {
        return const AccessValidationResult(
          state: AccessValidationState.deviceNotSupported,
          deniedReason: AccessDeniedReason.unsupportedDevice,
          message: 'Tu dispositivo no es compatible con Te Leo.\n'
                   'Requiere Android 5.0+ o iOS 12.0+',
          allowRetry: false,
        );
      }

      DebugLog.d('Device validation passed', category: LogCategory.security);
      return const AccessValidationResult(
        state: AccessValidationState.granted,
        message: 'Dispositivo válido',
      );

    } catch (e) {
      DebugLog.w('Device validation failed: $e', category: LogCategory.security);
      return const AccessValidationResult(
        state: AccessValidationState.denied,
        deniedReason: AccessDeniedReason.unknown,
        message: 'No se pudo verificar el dispositivo',
        allowRetry: true,
      );
    }
  }

  /// Validar seguridad
  Future<AccessValidationResult> _validateSecurity() async {
    _updateState(AccessValidationState.validating, 'Verificando seguridad...');
    
    await Future.delayed(const Duration(milliseconds: 600)); // Simular verificación

    try {
      // Solo en release mode
      if (!kDebugMode) {
        // Verificar si hay debugger conectado
        if (_isDebuggerAttached()) {
          return const AccessValidationResult(
            state: AccessValidationState.denied,
            deniedReason: AccessDeniedReason.debuggerDetected,
            message: 'Debugger detectado. Acceso denegado.',
            allowRetry: false,
          );
        }

        // Verificar integridad de la aplicación
        if (!await _verifyAppIntegrity()) {
          return const AccessValidationResult(
            state: AccessValidationState.denied,
            deniedReason: AccessDeniedReason.tampered,
            message: 'La aplicación ha sido modificada.\n'
                     'Reinstala desde la tienda oficial.',
            allowRetry: false,
          );
        }
      }

      DebugLog.d('Security validation passed', category: LogCategory.security);
      return const AccessValidationResult(
        state: AccessValidationState.granted,
        message: 'Verificación de seguridad completada',
      );

    } catch (e) {
      DebugLog.w('Security validation failed: $e', category: LogCategory.security);
      return const AccessValidationResult(
        state: AccessValidationState.denied,
        deniedReason: AccessDeniedReason.unknown,
        message: 'Error en verificación de seguridad',
        allowRetry: true,
      );
    }
  }

  /// Validar licencia/suscripción
  Future<AccessValidationResult> _validateLicense() async {
    _updateState(AccessValidationState.validating, 'Verificando licencia...');
    
    try {
      final subscriptionService = Get.find<SubscriptionService>();
      final currentLicense = subscriptionService.currentLicense;
      
      if (currentLicense == null) {
        // No hay licencia, usar gratuita por defecto
        DebugLog.i('No license found, allowing free access', category: LogCategory.security);
        return const AccessValidationResult(
          state: AccessValidationState.granted,
          message: 'Acceso gratuito autorizado',
        );
      }

      if (!currentLicense.esActiva) {
        if (currentLicense.haExpirado) {
          return AccessValidationResult(
            state: AccessValidationState.expired,
            deniedReason: AccessDeniedReason.expiredLicense,
            message: 'Tu licencia ha expirado.\n'
                     'Renueva tu suscripción para continuar.',
            allowRetry: true,
            retryAfter: DateTime.now().add(const Duration(hours: 1)),
          );
        }
        
        return const AccessValidationResult(
          state: AccessValidationState.denied,
          deniedReason: AccessDeniedReason.expiredLicense,
          message: 'Licencia inactiva',
          allowRetry: true,
        );
      }

      // Licencia válida
      String message = 'Licencia válida';
      if (currentLicense.esDemo) {
        message = 'Modo demo activo (${currentLicense.diasRestantes} días restantes)';
      } else if (currentLicense.esPremium) {
        message = 'Premium activo';
      }

      DebugLog.d('License validation passed: ${currentLicense.tipo}', category: LogCategory.security);
      return AccessValidationResult(
        state: AccessValidationState.granted,
        message: message,
        additionalData: {
          'licenseType': currentLicense.tipo.toString(),
          'isPremium': currentLicense.esPremium,
          'isDemo': currentLicense.esDemo,
          'daysRemaining': currentLicense.diasRestantes,
        },
      );

    } catch (e) {
      DebugLog.w('License validation failed: $e', category: LogCategory.security);
      return const AccessValidationResult(
        state: AccessValidationState.denied,
        deniedReason: AccessDeniedReason.unknown,
        message: 'Error al verificar licencia',
        allowRetry: true,
      );
    }
  }

  /// Actualizar estado interno
  void _updateState(
    AccessValidationState state,
    String message, {
    bool allowRetry = false,
    DateTime? retryAfter,
  }) {
    _state.value = state;
    _message.value = message;
    _allowRetry.value = allowRetry;
    _retryAfter.value = retryAfter;
  }

  /// Verificar si el dispositivo es compatible
  bool _isDeviceSupported() {
    // En producción, verificar versión del OS, RAM, etc.
    return true; // Por ahora, todos los dispositivos son compatibles
  }

  /// Verificar si el dispositivo está rooteado
  Future<bool> _isDeviceRooted() async {
    // En producción, usar plugins como flutter_jailbreak_detection
    return false; // Por ahora, asumir que no está rooteado
  }

  /// Verificar si hay debugger conectado
  bool _isDebuggerAttached() {
    // En producción, implementar detección de debugger
    return false;
  }

  /// Verificar integridad de la aplicación
  Future<bool> _verifyAppIntegrity() async {
    // En producción, verificar firma de la app
    return true;
  }

  /// Verificar licencia local
  Future<bool> _checkLocalLicense() async {
    // En producción, verificar licencia almacenada localmente
    // Por ahora, siempre retornar true para permitir acceso
    return true;
  }

  /// Verificar si modo demo está disponible
  Future<bool> _isDemoModeAvailable() async {
    // Permitir modo demo por tiempo limitado
    return true;
  }

  /// Reintentar validación
  Future<AccessValidationResult> retryValidation() async {
    DebugLog.i('Retrying access validation', category: LogCategory.security);
    return await validateAccess();
  }

  /// Mostrar dialog de acceso denegado
  void showAccessDeniedDialog(AccessValidationResult result) {
    // Navegar a la página de acceso denegado
    Get.to(() => AccessDeniedPage(
      result: result,
      onRetry: () {
        Get.back();
        retryValidation();
      },
      onExit: () => Get.back(),
    ));
  }

  /// Manejar renovación de suscripción
  void _handleRenewSubscription() {
    // Navegar a pantalla de suscripción
    Get.toNamed('/subscription');
  }

  /// Obtener información de estado para debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'state': state.toString(),
      'message': message,
      'allowRetry': allowRetry,
      'retryAfter': retryAfter?.toIso8601String(),
      'enabledValidations': {
        'device': _enableDeviceValidation,
        'license': _enableLicenseValidation,
        'security': _enableSecurityValidation,
        'maintenance': _enableMaintenanceCheck,
      },
      'timeout': _validationTimeout.inMilliseconds,
    };
  }
}
