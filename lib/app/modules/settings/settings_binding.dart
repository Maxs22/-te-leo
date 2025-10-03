import 'package:get/get.dart';

import 'settings_controller.dart';

/// Binding para el módulo de configuraciones
/// Registra las dependencias necesarias para la página de settings
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Los servicios ya están registrados por AppBootstrapService
    // Solo registrar el controlador
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
