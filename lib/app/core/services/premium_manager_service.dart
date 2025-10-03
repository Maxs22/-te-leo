import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'ads_service.dart';
import 'debug_console_service.dart';
import 'subscription_service.dart';
import 'usage_limits_service.dart';

/// Estado de la suscripción premium
enum PremiumStatus {
  free, // Usuario gratuito
  active, // Premium activo
  expired, // Premium expirado
  cancelled, // Premium cancelado
  pending, // Compra pendiente de verificación
}

/// Información de suscripción premium
class PremiumSubscription {
  final String productId;
  final String transactionId;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String platform;
  final bool isActive;
  final PremiumStatus status;

  const PremiumSubscription({
    required this.productId,
    required this.transactionId,
    required this.purchaseDate,
    required this.expiryDate,
    required this.platform,
    required this.isActive,
    required this.status,
  });

  /// Crear desde Map (para cargar desde almacenamiento)
  factory PremiumSubscription.fromMap(Map<String, dynamic> map) {
    return PremiumSubscription(
      productId: map['product_id'] ?? '',
      transactionId: map['transaction_id'] ?? '',
      purchaseDate: DateTime.parse(map['purchase_date'] ?? DateTime.now().toIso8601String()),
      expiryDate: DateTime.parse(map['expiry_date'] ?? DateTime.now().toIso8601String()),
      platform: map['platform'] ?? 'unknown',
      isActive: map['is_active'] ?? false,
      status: PremiumStatus.values.firstWhere((s) => s.name == map['status'], orElse: () => PremiumStatus.free),
    );
  }

  /// Convertir a Map (para guardar en almacenamiento)
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'transaction_id': transactionId,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'platform': platform,
      'is_active': isActive,
      'status': status.name,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Verificar si la suscripción está activa
  bool get isValidAndActive {
    return isActive && status == PremiumStatus.active && DateTime.now().isBefore(expiryDate);
  }

  /// Días restantes de suscripción
  int get daysRemaining {
    if (!isValidAndActive) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// Crear copia con cambios
  PremiumSubscription copyWith({
    String? productId,
    String? transactionId,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? platform,
    bool? isActive,
    PremiumStatus? status,
  }) {
    return PremiumSubscription(
      productId: productId ?? this.productId,
      transactionId: transactionId ?? this.transactionId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      platform: platform ?? this.platform,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
    );
  }
}

/// Servicio para gestionar el estado premium del usuario
class PremiumManagerService extends GetxService {
  static PremiumManagerService get to => Get.find();

  // Claves para GetStorage
  static const String _premiumDataKey = 'te_leo_premium_data';
  static const String _lastVerificationKey = 'te_leo_last_verification';

  // Instancia de GetStorage
  final _storage = GetStorage();

  // Estado reactivo
  final Rx<PremiumSubscription?> _subscription = Rx<PremiumSubscription?>(null);
  final Rx<PremiumStatus> _status = PremiumStatus.free.obs;
  final RxBool _isLoading = false.obs;

  // Getters públicos
  PremiumSubscription? get subscription => _subscription.value;
  PremiumStatus get status => _status.value;
  bool get isLoading => _isLoading.value;
  bool get isPremium => _subscription.value?.isValidAndActive ?? false;
  bool get isFree => !isPremium;
  int get daysRemaining => _subscription.value?.daysRemaining ?? 0;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePremiumManager();
  }

  /// Inicializar el gestor premium
  Future<void> _initializePremiumManager() async {
    try {
      DebugLog.i('Initializing PremiumManagerService', category: LogCategory.service);

      _isLoading.value = true;

      // Cargar datos de suscripción guardados
      await _loadSubscriptionData();

      // Verificar estado actual
      await _verifySubscriptionStatus();

      // Programar verificaciones periódicas
      _schedulePeriodicVerification();

      DebugLog.i('PremiumManagerService initialized - Status: ${_status.value}', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing PremiumManagerService: $e', category: LogCategory.service);
      _status.value = PremiumStatus.free;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar datos de suscripción desde almacenamiento local
  Future<void> _loadSubscriptionData() async {
    try {
      final subscriptionData = _storage.read<String>(_premiumDataKey);

      if (subscriptionData != null) {
        final map = jsonDecode(subscriptionData) as Map<String, dynamic>;
        _subscription.value = PremiumSubscription.fromMap(map);
        _status.value = _subscription.value!.status;

        DebugLog.d('Subscription data loaded from storage', category: LogCategory.service);
      } else {
        DebugLog.d('No subscription data found - user is free', category: LogCategory.service);
        _status.value = PremiumStatus.free;
      }
    } catch (e) {
      DebugLog.e('Error loading subscription data: $e', category: LogCategory.service);
      _status.value = PremiumStatus.free;
    }
  }

  /// Guardar datos de suscripción en almacenamiento local
  Future<void> _saveSubscriptionData() async {
    try {
      if (_subscription.value != null) {
        final subscriptionJson = jsonEncode(_subscription.value!.toMap());
        await _storage.write(_premiumDataKey, subscriptionJson);
        await _storage.write(_lastVerificationKey, DateTime.now().toIso8601String());

        DebugLog.d('Subscription data saved to storage', category: LogCategory.service);
      } else {
        await _storage.remove(_premiumDataKey);
        DebugLog.d('Subscription data cleared from storage', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error saving subscription data: $e', category: LogCategory.service);
    }
  }

  /// Verificar estado actual de la suscripción
  Future<void> _verifySubscriptionStatus() async {
    try {
      final subscription = _subscription.value;
      if (subscription == null) {
        _status.value = PremiumStatus.free;
        return;
      }

      final now = DateTime.now();

      // Verificar si expiró
      if (now.isAfter(subscription.expiryDate)) {
        DebugLog.i('Subscription expired on ${subscription.expiryDate}', category: LogCategory.service);
        await _handleExpiredSubscription();
        return;
      }

      // Verificar si está activa
      if (subscription.isValidAndActive) {
        _status.value = PremiumStatus.active;
        DebugLog.d(
          'Subscription is active - expires in ${subscription.daysRemaining} days',
          category: LogCategory.service,
        );
      } else {
        _status.value = PremiumStatus.cancelled;
        DebugLog.w('Subscription is cancelled or invalid', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error verifying subscription status: $e', category: LogCategory.service);
      _status.value = PremiumStatus.free;
    }
  }

  /// Activar suscripción premium
  Future<bool> activatePremium({
    required String productId,
    required String transactionId,
    required DateTime expiryDate,
    String platform = 'google_play',
  }) async {
    try {
      DebugLog.i('Activating premium subscription', category: LogCategory.service);

      _isLoading.value = true;

      final newSubscription = PremiumSubscription(
        productId: productId,
        transactionId: transactionId,
        purchaseDate: DateTime.now(),
        expiryDate: expiryDate,
        platform: platform,
        isActive: true,
        status: PremiumStatus.active,
      );

      _subscription.value = newSubscription;
      _status.value = PremiumStatus.active;

      // Guardar en almacenamiento local
      await _saveSubscriptionData();

      // Notificar a otros servicios
      await _notifyPremiumActivated();

      DebugLog.i('Premium activated successfully - expires: $expiryDate', category: LogCategory.service);

      return true;
    } catch (e) {
      DebugLog.e('Error activating premium: $e', category: LogCategory.service);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Manejar suscripción expirada
  Future<void> _handleExpiredSubscription() async {
    try {
      DebugLog.i('Handling expired subscription', category: LogCategory.service);

      // Cambiar estado pero mantener información para posible renovación
      if (_subscription.value != null) {
        _subscription.value = _subscription.value!.copyWith(isActive: false, status: PremiumStatus.expired);
      }

      _status.value = PremiumStatus.expired;

      // Guardar estado actualizado
      await _saveSubscriptionData();

      // Notificar a otros servicios
      await _notifyPremiumExpired();

      // Mostrar notificación al usuario
      _showExpirationNotification();
    } catch (e) {
      DebugLog.e('Error handling expired subscription: $e', category: LogCategory.service);
    }
  }

  /// Cancelar suscripción
  Future<bool> cancelSubscription() async {
    try {
      DebugLog.i('Cancelling subscription', category: LogCategory.service);

      if (_subscription.value != null) {
        _subscription.value = _subscription.value!.copyWith(isActive: false, status: PremiumStatus.cancelled);

        _status.value = PremiumStatus.cancelled;
        await _saveSubscriptionData();

        // Notificar a otros servicios
        await _notifyPremiumCancelled();

        return true;
      }

      return false;
    } catch (e) {
      DebugLog.e('Error cancelling subscription: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Restaurar suscripción desde las tiendas
  Future<bool> restoreSubscription() async {
    try {
      DebugLog.i('Attempting to restore subscription', category: LogCategory.service);

      _isLoading.value = true;

      // Usar SubscriptionService para verificar compras
      final subscriptionService = Get.find<SubscriptionService>();
      final restored = await subscriptionService.restorePurchases();

      if (restored) {
        // Si se restauró, actualizar datos locales
        await _loadSubscriptionData();
        await _verifySubscriptionStatus();

        DebugLog.i('Subscription restored successfully', category: LogCategory.service);
        return true;
      }

      return false;
    } catch (e) {
      DebugLog.e('Error restoring subscription: $e', category: LogCategory.service);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Programar verificaciones periódicas
  void _schedulePeriodicVerification() {
    // Verificar cada 6 horas si la suscripción sigue válida
    Timer.periodic(const Duration(hours: 6), (timer) {
      _verifySubscriptionStatus();
    });

    // Verificar cada día si hay que mostrar recordatorio de renovación
    Timer.periodic(const Duration(days: 1), (timer) {
      _checkRenewalReminder();
    });
  }

  /// Verificar si hay que mostrar recordatorio de renovación
  void _checkRenewalReminder() {
    final subscription = _subscription.value;
    if (subscription == null || !subscription.isActive) return;

    final daysRemaining = subscription.daysRemaining;

    // Mostrar recordatorio 7 días antes del vencimiento
    if (daysRemaining <= 7 && daysRemaining > 0) {
      _showRenewalReminder(daysRemaining);
    }
  }

  /// Mostrar recordatorio de renovación
  void _showRenewalReminder(int daysRemaining) {
    Get.snackbar(
      '⏰ Renovación Premium',
      'Tu suscripción premium expira en $daysRemaining días',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () => Get.toNamed('/subscription'),
        child: const Text('Renovar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Mostrar notificación de expiración
  void _showExpirationNotification() {
    Get.snackbar(
      '😔 Premium Expirado',
      'Tu suscripción premium ha expirado. Renueva para seguir disfrutando todas las funciones.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
      mainButton: TextButton(
        onPressed: () => Get.toNamed('/subscription'),
        child: const Text('Renovar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Notificar a otros servicios que premium se activó
  Future<void> _notifyPremiumActivated() async {
    try {
      // Deshabilitar anuncios
      final adsService = Get.find<AdsService>();
      adsService.disableAds();

      // Resetear límites de uso
      final limitsService = Get.find<UsageLimitsService>();
      await limitsService.resetLimitsForTesting(); // Esto debería ser un método específico

      DebugLog.d('Other services notified of premium activation', category: LogCategory.service);
    } catch (e) {
      DebugLog.w('Error notifying services of premium activation: $e', category: LogCategory.service);
    }
  }

  /// Notificar a otros servicios que premium expiró
  Future<void> _notifyPremiumExpired() async {
    try {
      // Habilitar anuncios
      final adsService = Get.find<AdsService>();
      await adsService.enableAds();

      DebugLog.d('Other services notified of premium expiration', category: LogCategory.service);
    } catch (e) {
      DebugLog.w('Error notifying services of premium expiration: $e', category: LogCategory.service);
    }
  }

  /// Notificar a otros servicios que premium se canceló
  Future<void> _notifyPremiumCancelled() async {
    try {
      // Habilitar anuncios inmediatamente
      final adsService = Get.find<AdsService>();
      await adsService.enableAds();

      DebugLog.d('Other services notified of premium cancellation', category: LogCategory.service);
    } catch (e) {
      DebugLog.w('Error notifying services of premium cancellation: $e', category: LogCategory.service);
    }
  }

  /// Obtener información detallada de la suscripción
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final subscription = _subscription.value;

    return {
      'isPremium': isPremium,
      'status': _status.value.name,
      'daysRemaining': daysRemaining,
      'subscription': subscription?.toMap(),
      'lastVerification': await _getLastVerificationDate(),
    };
  }

  /// Obtener fecha de última verificación
  Future<String?> _getLastVerificationDate() async {
    try {
      return _storage.read<String>(_lastVerificationKey);
    } catch (e) {
      return null;
    }
  }

  /// 🧪 MODO DESARROLLO: Activar premium de prueba
  Future<void> activateTestPremium({int days = 30}) async {
    if (!kDebugMode) return;

    DebugLog.i('🧪 ACTIVATING TEST PREMIUM for $days days', category: LogCategory.service);

    final testSubscription = PremiumSubscription(
      productId: 'te_leo_premium_test',
      transactionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      purchaseDate: DateTime.now(),
      expiryDate: DateTime.now().add(Duration(days: days)),
      platform: 'test',
      isActive: true,
      status: PremiumStatus.active,
    );

    _subscription.value = testSubscription;
    _status.value = PremiumStatus.active;

    await _saveSubscriptionData();
    await _notifyPremiumActivated();

    Get.snackbar(
      '🧪 Premium Test Activado',
      'Premium activado por $days días para pruebas',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  /// 🧪 MODO DESARROLLO: Simular expiración
  Future<void> simulateExpiration() async {
    if (!kDebugMode) return;

    DebugLog.i('🧪 SIMULATING PREMIUM EXPIRATION', category: LogCategory.service);

    if (_subscription.value != null) {
      _subscription.value = _subscription.value!.copyWith(
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        status: PremiumStatus.expired,
        isActive: false,
      );

      await _saveSubscriptionData();
      await _verifySubscriptionStatus();
    }
  }

  /// 🧪 MODO DESARROLLO: Limpiar datos premium
  Future<void> clearPremiumData() async {
    if (!kDebugMode) return;

    DebugLog.i('🧪 CLEARING PREMIUM DATA', category: LogCategory.service);

    _subscription.value = null;
    _status.value = PremiumStatus.free;

    await _storage.remove(_premiumDataKey);
    await _storage.remove(_lastVerificationKey);

    await _notifyPremiumExpired();
  }
}
