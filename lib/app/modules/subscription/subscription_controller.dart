import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global_widgets/global_widgets.dart';
import '../../core/services/debug_console_service.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/licencia.dart';

/// Controlador para la página de suscripción
class SubscriptionController extends GetxController {
  final SubscriptionService _subscriptionService = Get.find<SubscriptionService>();

  // Estado reactivo
  final RxBool _isLoading = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isRestoring => _subscriptionService.isRestoring;

  // Getter reactivo que accede directamente a la RxList
  RxList<SubscriptionProduct> get subscriptionProducts => _subscriptionService.availableProducts;
  SubscriptionState get subscriptionState => _subscriptionService.state;

  @override
  void onInit() {
    super.onInit();
    DebugLog.i('SubscriptionController initialized', category: LogCategory.ui);
    DebugLog.i('Available products: ${subscriptionProducts.length}', category: LogCategory.ui);
  }

  @override
  void onReady() {
    super.onReady();
    // Verificar productos después de que la vista esté lista
    DebugLog.i('SubscriptionController ready - products: ${subscriptionProducts.length}', category: LogCategory.ui);
  }

  /// Suscribirse a un producto
  Future<void> subscribe(SubscriptionProduct product) async {
    try {
      _isLoading.value = true;
      DebugLog.i('User attempting to subscribe to: ${product.id}', category: LogCategory.ui);

      // Mostrar confirmación
      final confirmed = await _showSubscriptionConfirmation(product);
      if (!confirmed) {
        _isLoading.value = false;
        return;
      }

      // Procesar suscripción
      final success = await _subscriptionService.subscribe(product);

      if (success) {
        Get.snackbar(
          'Suscripción Exitosa',
          'Bienvenido a Te Leo Premium',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Volver a la pantalla anterior
        Get.back();
      } else {
        Get.snackbar(
          'Error',
          'No se pudo procesar la suscripción. Intenta nuevamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      DebugLog.e('Error in subscription process: $e', category: LogCategory.ui);
      Get.snackbar(
        'Error',
        'Ocurrió un error inesperado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Restaurar compras
  Future<void> restorePurchases() async {
    try {
      DebugLog.i('User restoring purchases', category: LogCategory.ui);

      final success = await _subscriptionService.restorePurchases();

      if (success) {
        Get.back(); // Volver a la pantalla anterior
      }
    } catch (e) {
      DebugLog.e('Error restoring purchases: $e', category: LogCategory.ui);
      Get.snackbar(
        'Error',
        'No se pudieron restaurar las compras',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Mostrar confirmación de suscripción
  Future<bool> _showSubscriptionConfirmation(SubscriptionProduct product) async {
    bool confirmed = false;

    await Get.dialog(
      ModernDialog(
        titulo: 'Confirmar Suscripción',
        contenido:
            '${product.title}\n${product.price}\n\n'
            'Se te cobrará ${product.price} ${product.type == TipoLicencia.premiumMensual ? 'mensualmente' : 'anualmente'} hasta que canceles.',
        textoBotonPrimario: 'Confirmar',
        textoBotonSecundario: 'Cancelar',
        onBotonPrimario: () {
          confirmed = true;
          Get.back();
        },
        onBotonSecundario: () {
          confirmed = false;
          Get.back();
        },
      ),
    );

    return confirmed;
  }

  /// Mostrar información de gestión de suscripción
  void showManageSubscription() {
    Get.dialog(
      ModernDialog(
        titulo: 'Gestionar Suscripción',
        contenido:
            'Para gestionar tu suscripción:\n\n'
            'Android: Play Store > Suscripciones\n\n'
            'iOS: Configuración > Apple ID > Suscripciones',
        textoBotonPrimario: 'Entendido',
        onBotonPrimario: () => Get.back(),
      ),
    );
  }
}
