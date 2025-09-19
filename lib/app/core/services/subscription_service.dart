import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'debug_console_service.dart';
import '../../data/models/licencia.dart';

/// Estados de suscripción
enum SubscriptionState {
  loading,
  active,
  expired,
  cancelled,
  error,
  notSubscribed,
}

/// Información de producto de suscripción
class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currency;
  final TipoLicencia type;
  final Duration duration;
  final List<String> features;
  final bool isPopular;

  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.duration,
    required this.features,
    this.isPopular = false,
  });
}

/// Servicio de gestión de suscripciones premium
class SubscriptionService extends GetxService {
  static SubscriptionService get to => Get.find();

  // Estado reactivo
  final Rx<SubscriptionState> _state = SubscriptionState.loading.obs;
  final Rx<Licencia?> _currentLicense = Rx<Licencia?>(null);
  final RxList<SubscriptionProduct> _availableProducts = <SubscriptionProduct>[].obs;
  final RxBool _isRestoring = false.obs;

  // Getters
  SubscriptionState get state => _state.value;
  Licencia? get currentLicense => _currentLicense.value;
  List<SubscriptionProduct> get availableProducts => _availableProducts;
  bool get isRestoring => _isRestoring.value;
  bool get isPremium => currentLicense?.esPremium ?? false;
  bool get isDemo => currentLicense?.esDemo ?? false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeSubscriptions();
  }

  /// Inicializar servicio de suscripciones
  Future<void> _initializeSubscriptions() async {
    try {
      DebugLog.i('Initializing subscription service', category: LogCategory.service);
      
      _state.value = SubscriptionState.loading;
      
      // Cargar licencia actual
      await _loadCurrentLicense();
      
      // Cargar productos disponibles
      _loadAvailableProducts();
      
      // Verificar estado de suscripción
      await _verifySubscriptionStatus();
      
      DebugLog.i('Subscription service initialized successfully', category: LogCategory.service);
      
    } catch (e) {
      DebugLog.e('Error initializing subscription service: $e', category: LogCategory.service);
      _state.value = SubscriptionState.error;
    }
  }

  /// Cargar licencia actual del almacenamiento local
  Future<void> _loadCurrentLicense() async {
    try {
      // En una implementación real, cargarías desde base de datos local
      // Por ahora, crear licencia gratuita por defecto
      _currentLicense.value = Licencia.gratuita();
      
      DebugLog.d('Current license loaded: ${_currentLicense.value?.tipo}', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error loading current license: $e', category: LogCategory.service);
      _currentLicense.value = Licencia.gratuita();
    }
  }

  /// Cargar productos de suscripción disponibles
  void _loadAvailableProducts() {
    _availableProducts.value = [
      const SubscriptionProduct(
        id: 'te_leo_premium_monthly',
        title: 'Premium Mensual',
        description: 'Acceso completo a todas las funciones',
        price: '\$2.99',
        currency: 'USD',
        type: TipoLicencia.premiumMensual,
        duration: Duration(days: 30),
        features: [
          'Voces premium adicionales',
          'Exportación de documentos',
          'Sincronización en la nube',
          'Soporte prioritario',
          'Sin anuncios',
        ],
      ),
      const SubscriptionProduct(
        id: 'te_leo_premium_yearly',
        title: 'Premium Anual',
        description: 'El mejor valor - ahorra 50%',
        price: '\$29.99',
        currency: 'USD',
        type: TipoLicencia.premiumAnual,
        duration: Duration(days: 365),
        features: [
          'Todas las funciones mensuales',
          'Voces exclusivas anuales',
          'Funciones beta anticipadas',
          'Soporte VIP',
          'Descuento del 50%',
        ],
        isPopular: true,
      ),
    ];

    DebugLog.d('Loaded ${_availableProducts.length} subscription products', category: LogCategory.service);
  }

  /// Verificar estado actual de suscripción
  Future<void> _verifySubscriptionStatus() async {
    try {
      final license = _currentLicense.value;
      if (license == null) {
        _state.value = SubscriptionState.notSubscribed;
        return;
      }

      if (license.esActiva) {
        if (license.esPremium) {
          _state.value = SubscriptionState.active;
        } else {
          _state.value = SubscriptionState.notSubscribed;
        }
      } else if (license.haExpirado) {
        _state.value = SubscriptionState.expired;
      } else {
        _state.value = SubscriptionState.cancelled;
      }

      DebugLog.d('Subscription status verified: ${_state.value}', category: LogCategory.service);
      
    } catch (e) {
      DebugLog.e('Error verifying subscription status: $e', category: LogCategory.service);
      _state.value = SubscriptionState.error;
    }
  }

  /// Iniciar proceso de suscripción
  Future<bool> subscribe(SubscriptionProduct product) async {
    try {
      DebugLog.i('Starting subscription process for: ${product.id}', category: LogCategory.service);
      
      // En una implementación real, aquí usarías in_app_purchase
      // Por ahora, simular suscripción exitosa
      await Future.delayed(const Duration(seconds: 2));
      
      // Crear nueva licencia premium
      Licencia newLicense;
      if (product.type == TipoLicencia.premiumMensual) {
        newLicense = Licencia.premiumMensual(usuarioId: 'user_123');
      } else {
        newLicense = Licencia.premiumAnual(usuarioId: 'user_123');
      }
      
      // Guardar licencia
      await _saveLicense(newLicense);
      
      _currentLicense.value = newLicense;
      _state.value = SubscriptionState.active;
      
      DebugLog.i('Subscription completed successfully', category: LogCategory.service);
      return true;
      
    } catch (e) {
      DebugLog.e('Error during subscription: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Activar modo demo
  Future<bool> activateDemo() async {
    try {
      DebugLog.i('Activating demo mode', category: LogCategory.service);
      
      final demoLicense = Licencia.demo();
      await _saveLicense(demoLicense);
      
      _currentLicense.value = demoLicense;
      _state.value = SubscriptionState.active;
      
      Get.snackbar(
        'Modo Demo Activado',
        'Tienes 7 días para probar todas las funciones premium',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
      );
      
      return true;
      
    } catch (e) {
      DebugLog.e('Error activating demo: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Cancelar suscripción
  Future<bool> cancelSubscription() async {
    try {
      DebugLog.i('Cancelling subscription', category: LogCategory.service);
      
      // En una implementación real, cancelarías en la tienda
      await Future.delayed(const Duration(seconds: 1));
      
      // Revertir a licencia gratuita
      final freeLicense = Licencia.gratuita();
      await _saveLicense(freeLicense);
      
      _currentLicense.value = freeLicense;
      _state.value = SubscriptionState.notSubscribed;
      
      return true;
      
    } catch (e) {
      DebugLog.e('Error cancelling subscription: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Restaurar compras
  Future<bool> restorePurchases() async {
    try {
      _isRestoring.value = true;
      DebugLog.i('Restoring purchases', category: LogCategory.service);
      
      // En una implementación real, consultarías las tiendas
      await Future.delayed(const Duration(seconds: 2));
      
      // Simular restauración exitosa
      final restoredLicense = Licencia.premiumAnual(usuarioId: 'user_123');
      await _saveLicense(restoredLicense);
      
      _currentLicense.value = restoredLicense;
      _state.value = SubscriptionState.active;
      
      Get.snackbar(
        'Compras Restauradas',
        'Tu suscripción premium ha sido restaurada',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      return true;
      
    } catch (e) {
      DebugLog.e('Error restoring purchases: $e', category: LogCategory.service);
      return false;
    } finally {
      _isRestoring.value = false;
    }
  }

  /// Verificar si una característica está disponible
  bool hasFeature(String feature) {
    return _currentLicense.value?.tieneCaracteristica(feature) ?? false;
  }

  /// Obtener límite de uso para una característica
  int? getUsageLimit(String feature) {
    return _currentLicense.value?.obtenerLimite(feature);
  }

  /// Guardar licencia en almacenamiento local
  Future<void> _saveLicense(Licencia license) async {
    try {
      // En una implementación real, guardarías en base de datos
      // Por ahora, solo log
      DebugLog.d('License saved: ${license.tipo}', category: LogCategory.database);
    } catch (e) {
      DebugLog.e('Error saving license: $e', category: LogCategory.database);
      rethrow;
    }
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'state': state.toString(),
      'currentLicense': currentLicense?.toString(),
      'isPremium': isPremium,
      'isDemo': isDemo,
      'availableProducts': availableProducts.length,
      'isRestoring': isRestoring,
    };
  }
}
