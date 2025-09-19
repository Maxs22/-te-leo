import 'package:get/get.dart';
import 'home_controller.dart';

/// Binding para el módulo Home
/// Registra las dependencias necesarias para la página principal
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Registro del controlador de Home usando lazy loading
    // Se crea solo cuando es necesario para optimizar memoria
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
  }
}
