import 'package:get/get.dart';

import 'library_controller.dart';

/// Binding para el módulo Library
/// Registra solo el controlador (servicios ya están en AppBootstrapService)
class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    // Los servicios ya están registrados por AppBootstrapService
    // Solo registrar el controlador usando lazy loading
    Get.lazyPut<LibraryController>(() => LibraryController());
  }
}
