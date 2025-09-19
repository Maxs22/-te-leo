import 'package:get/get.dart';
import 'welcome_controller.dart';

/// Binding para la pantalla de bienvenida
class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(
      () => WelcomeController(),
    );
  }
}
