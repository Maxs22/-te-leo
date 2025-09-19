import 'package:get/get.dart';
import 'library_controller.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/enhanced_tts_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/reading_progress_service.dart';
import '../../core/services/error_service.dart';

/// Binding para el módulo Library
/// Registra las dependencias necesarias para la página de biblioteca
class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar servicios si no existen
    Get.lazyPut<ErrorService>(() => ErrorService(), fenix: true);
    Get.lazyPut<TTSService>(() => TTSService(), fenix: true);
    Get.lazyPut<EnhancedTTSService>(() => EnhancedTTSService(), fenix: true);
    Get.lazyPut<ThemeService>(() => ThemeService(), fenix: true);
    Get.lazyPut<ReadingProgressService>(() => ReadingProgressService(), fenix: true);
    
    // Registro del controlador de Library usando lazy loading
    // Se crea solo cuando es necesario para optimizar memoria
    Get.lazyPut<LibraryController>(
      () => LibraryController(),
    );
  }
}
