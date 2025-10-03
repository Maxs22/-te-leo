import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/models/licencia.dart';
import '../config/purchase_config.dart';
import 'debug_console_service.dart';

/// Estados de suscripción
enum SubscriptionState { loading, active, expired, cancelled, error, notSubscribed }

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

  // InAppPurchase instance
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Estado reactivo
  final Rx<SubscriptionState> _state = SubscriptionState.loading.obs;
  final Rx<Licencia?> _currentLicense = Rx<Licencia?>(null);
  final RxList<SubscriptionProduct> _availableProducts = <SubscriptionProduct>[].obs;
  final RxBool _isRestoring = false.obs;

  // Getters
  SubscriptionState get state => _state.value;
  Licencia? get currentLicense => _currentLicense.value;
  RxList<SubscriptionProduct> get availableProducts => _availableProducts;
  bool get isRestoring => _isRestoring.value;
  bool get isPremium => currentLicense?.esPremium ?? false;
  bool get isDemo => currentLicense?.esDemo ?? false;
  bool get isActive => isPremium && (state == SubscriptionState.active);

  // Constructor: cargar productos mock inmediatamente
  SubscriptionService() {
    _loadAvailableProducts();
    // Log seguro (puede que DebugConsoleService aún no esté disponible)
    try {
      DebugLog.i(
        'SubscriptionService constructor: ${_availableProducts.length} mock products loaded',
        category: LogCategory.service,
      );
    } catch (e) {
      if (kDebugMode) {
        print('🚀 SubscriptionService constructor: ${_availableProducts.length} mock products loaded');
      }
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeSubscriptions();
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  /// Inicializar servicio de suscripciones
  Future<void> _initializeSubscriptions() async {
    try {
      DebugLog.i('Initializing subscription service', category: LogCategory.service);

      _state.value = SubscriptionState.loading;

      // Los productos mock ya están cargados en el constructor
      DebugLog.i('Products available: ${_availableProducts.length}', category: LogCategory.service);

      // Cargar licencia actual
      await _loadCurrentLicense();

      // Verificar si In-App Purchase está disponible
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        DebugLog.w('In-App Purchase not available on this device - using mock products', category: LogCategory.service);
        _state.value = SubscriptionState.notSubscribed;
        return;
      }

      // Escuchar el stream de compras
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => DebugLog.d('Purchase stream done', category: LogCategory.service),
        onError: (error) => DebugLog.e('Purchase stream error: $error', category: LogCategory.service),
      );

      // Intentar cargar productos reales desde las tiendas
      await _loadRealProducts();

      // Verificar estado de suscripción
      await _verifySubscriptionStatus();

      DebugLog.i('Subscription service initialized successfully', category: LogCategory.service);
    } catch (e, stackTrace) {
      DebugLog.e(
        'Error initializing subscription service: $e',
        category: LogCategory.service,
        stackTrace: stackTrace.toString(),
      );
      _state.value = SubscriptionState.notSubscribed;
      // Los productos mock ya están cargados
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

  /// Cargar productos REALES desde Google Play / App Store
  Future<void> _loadRealProducts() async {
    try {
      final Set<String> productIds = {PurchaseConfig.monthlyProductId, PurchaseConfig.yearlyProductId};

      DebugLog.d('Querying products: $productIds', category: LogCategory.service);

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        DebugLog.w('Products not found: ${response.notFoundIDs}', category: LogCategory.service);
      }

      if (response.error != null) {
        DebugLog.e('Error loading products: ${response.error}', category: LogCategory.service);
        // No cargar productos mock de nuevo, ya están cargados en el constructor
        DebugLog.i('Keeping existing mock products (${_availableProducts.length})', category: LogCategory.service);
        return;
      }

      // Convertir ProductDetails a SubscriptionProduct
      final products = response.productDetails.map((productDetail) {
        final isMonthly = productDetail.id == PurchaseConfig.monthlyProductId;
        return SubscriptionProduct(
          id: productDetail.id,
          title: isMonthly ? 'Premium Mensual' : 'Premium Anual',
          description: isMonthly ? 'Escaneos ilimitados y sin anuncios' : 'El mejor valor - ahorra 17%',
          price: productDetail.price, // Precio real desde la tienda
          currency: productDetail.currencyCode,
          type: isMonthly ? TipoLicencia.premiumMensual : TipoLicencia.premiumAnual,
          duration: isMonthly ? const Duration(days: 30) : const Duration(days: 365),
          features: isMonthly
              ? ['∞ Escaneos ilimitados', '🚫 Sin anuncios', '🎧 Soporte prioritario', '🧪 Funciones beta']
              : [
                  '∞ Escaneos ilimitados',
                  '🚫 Sin anuncios',
                  '🎧 Soporte prioritario',
                  '🧪 Funciones beta',
                  '💰 Ahorra 17% vs mensual',
                ],
          isPopular: !isMonthly,
        );
      }).toList();

      // Solo actualizar si encontramos productos reales, de lo contrario mantener los mock
      if (products.isNotEmpty) {
        _availableProducts.assignAll(products);
        DebugLog.i('Loaded ${products.length} real products from store', category: LogCategory.service);
      } else {
        DebugLog.w(
          'No real products found, keeping mock products (${_availableProducts.length})',
          category: LogCategory.service,
        );
      }
    } catch (e) {
      DebugLog.e('Error loading real products: $e', category: LogCategory.service);
      // No cargar productos mock de nuevo, ya están cargados en el constructor
      DebugLog.i('Keeping existing mock products (${_availableProducts.length})', category: LogCategory.service);
    }
  }

  /// Cargar productos de suscripción disponibles (MOCK - solo para fallback)
  void _loadAvailableProducts() {
    final products = [
      SubscriptionProduct(
        id: PurchaseConfig.monthlyProductId,
        title: 'Premium Mensual',
        description: 'Escaneos ilimitados y sin anuncios',
        price: PurchaseConfig.getFormattedPrice('monthly'),
        currency: 'USD',
        type: TipoLicencia.premiumMensual,
        duration: const Duration(days: 30),
        features: ['∞ Escaneos ilimitados', '🚫 Sin anuncios', '🎧 Soporte prioritario', '🧪 Funciones beta'],
      ),
      SubscriptionProduct(
        id: PurchaseConfig.yearlyProductId,
        title: 'Premium Anual',
        description: 'El mejor valor - ahorra 17%',
        price: PurchaseConfig.getFormattedPrice('yearly'),
        currency: 'USD',
        type: TipoLicencia.premiumAnual,
        duration: const Duration(days: 365),
        features: [
          '∞ Escaneos ilimitados',
          '🚫 Sin anuncios',
          '🎧 Soporte prioritario',
          '🧪 Funciones beta',
          '💰 Ahorra 17% vs mensual',
        ],
        isPopular: true,
      ),
    ];

    // Usar assignAll para asegurar reactividad
    _availableProducts.assignAll(products);

    try {
      DebugLog.d('Loaded ${_availableProducts.length} mock subscription products', category: LogCategory.service);
    } catch (e) {
      // Si DebugConsoleService no está disponible, usar print como fallback
      if (kDebugMode) {
        print('✅ Loaded ${_availableProducts.length} mock subscription products');
      }
    }
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

  /// Manejar actualizaciones del stream de compras
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      DebugLog.d(
        'Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}',
        category: LogCategory.service,
      );

      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        // Verificar la compra
        final valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _deliverProduct(purchaseDetails);
        }
      }

      if (purchaseDetails.status == PurchaseStatus.error) {
        DebugLog.e('Purchase error: ${purchaseDetails.error}', category: LogCategory.service);
        Get.snackbar(
          'Error de Compra',
          'No se pudo procesar la compra. Intenta nuevamente.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

      // Completar la transacción
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verificar compra (aquí podrías validar con tu backend)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // En producción, deberías validar con tu backend
    // Por ahora, confiar en Google Play / App Store
    return true;
  }

  /// Entregar producto al usuario
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      DebugLog.i('Delivering product: ${purchaseDetails.productID}', category: LogCategory.service);

      // Crear nueva licencia premium
      Licencia newLicense;
      if (purchaseDetails.productID == PurchaseConfig.monthlyProductId) {
        newLicense = Licencia.premiumMensual(usuarioId: 'user_${purchaseDetails.purchaseID}');
      } else {
        newLicense = Licencia.premiumAnual(usuarioId: 'user_${purchaseDetails.purchaseID}');
      }

      // Guardar licencia
      await _saveLicense(newLicense);

      _currentLicense.value = newLicense;
      _state.value = SubscriptionState.active;

      DebugLog.i('Product delivered successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error delivering product: $e', category: LogCategory.service);
    }
  }

  /// Iniciar proceso de suscripción REAL
  Future<bool> subscribe(SubscriptionProduct product) async {
    try {
      DebugLog.i('Starting REAL subscription process for: ${product.id}', category: LogCategory.service);

      // Obtener el ProductDetails real
      final Set<String> productIds = {product.id};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.productDetails.isEmpty) {
        DebugLog.e('Product not found: ${product.id}', category: LogCategory.service);
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;

      // Crear parámetros de compra para SUSCRIPCIÓN
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

      // Iniciar compra de SUSCRIPCIÓN (no consumible)
      // Para suscripciones en Google Play y App Store
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        DebugLog.w('Purchase initiation failed', category: LogCategory.service);
        Get.snackbar(
          'Error',
          'No se pudo iniciar la compra. Verifica tu método de pago.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

      DebugLog.i('Purchase initiated: $success', category: LogCategory.service);
      return success;
    } catch (e) {
      DebugLog.e('Error during subscription: $e', category: LogCategory.service);
      Get.snackbar(
        'Error',
        'No se pudo iniciar la compra: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Activar modo demo - DESACTIVADO
  /// La app da escaneos de prueba gratuitos en lugar de período de prueba
  // Future<bool> activateDemo() async {
  //   try {
  //     DebugLog.i('Activating demo mode', category: LogCategory.service);
  //
  //     final demoLicense = Licencia.demo();
  //     await _saveLicense(demoLicense);
  //
  //     _currentLicense.value = demoLicense;
  //     _state.value = SubscriptionState.active;
  //
  //     Get.snackbar(
  //       'Modo Demo Activado',
  //       'Tienes 7 días para probar todas las funciones premium',
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: Get.theme.colorScheme.primary,
  //       colorText: Colors.white,
  //     );
  //
  //     return true;
  //   } catch (e) {
  //     DebugLog.e('Error activating demo: $e', category: LogCategory.service);
  //     return false;
  //   }
  // }

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

  /// Restaurar compras REALES desde Google Play / App Store
  Future<bool> restorePurchases() async {
    try {
      _isRestoring.value = true;
      DebugLog.i('Restoring purchases from store', category: LogCategory.service);

      // Restaurar compras desde la tienda
      await _inAppPurchase.restorePurchases();

      // El stream de compras manejará la restauración automáticamente
      // Esperar un momento para que se procesen
      await Future.delayed(const Duration(seconds: 2));

      // Verificar si se restauró algo
      if (isPremium) {
        Get.snackbar(
          'Compras Restauradas',
          'Tu suscripción premium ha sido restaurada',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Sin Compras',
          'No se encontraron compras previas para restaurar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      DebugLog.e('Error restoring purchases: $e', category: LogCategory.service);
      Get.snackbar(
        'Error',
        'No se pudieron restaurar las compras',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
