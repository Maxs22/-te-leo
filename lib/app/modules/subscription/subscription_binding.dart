import 'package:get/get.dart';
import 'subscription_controller.dart';

/// Binding para la página de suscripción
class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(),
    );
  }
}
