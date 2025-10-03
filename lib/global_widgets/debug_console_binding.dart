import 'package:get/get.dart';

import 'debug_console_page.dart';

/// Binding para la página de Debug Console
/// Solo registra el controlador (el servicio ya está en AppBootstrapService)
class DebugConsoleBinding extends Bindings {
  @override
  void dependencies() {
    // El DebugConsoleService ya está registrado por AppBootstrapService
    // Solo registrar el controlador
    Get.lazyPut<DebugConsoleController>(() => DebugConsoleController());
  }
}
