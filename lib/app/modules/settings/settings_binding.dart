import 'package:get/get.dart';
import 'settings_controller.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/debug_console_service.dart';

/// Binding para el módulo de configuraciones
/// Registra las dependencias necesarias para la página de settings
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar servicios si no existen
    Get.lazyPut<DebugConsoleService>(() => DebugConsoleService(), fenix: true);
    Get.lazyPut<TTSService>(() => TTSService(), fenix: true);
    
    // Registrar controlador de configuraciones
    Get.lazyPut<SettingsController>(
      () => SettingsController(),
    );
  }
}
