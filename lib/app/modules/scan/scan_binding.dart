import 'package:get/get.dart';

import 'scan_controller.dart';

/// Binding para el módulo de escaneo de texto
/// Registra solo el controlador (servicios ya están en AppBootstrapService)
class ScanBinding extends Bindings {
  @override
  void dependencies() {
    // Los servicios ya están registrados por AppBootstrapService
    // Solo registrar el controlador del módulo
    Get.lazyPut<ScanController>(() => ScanController());
  }
}
