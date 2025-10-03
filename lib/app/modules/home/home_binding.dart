import 'package:get/get.dart';
import 'home_controller.dart';

/// Binding para el módulo Home
/// Registra las dependencias necesarias para la página principal
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Registro del controlador de Home
    // Usar put en lugar de lazyPut para que se recargue cada vez
    Get.put<HomeController>(
      HomeController(),
      // NO permanent para que se recree cada vez que volvemos a Home
    );
  }
}
