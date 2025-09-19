import 'package:get/get.dart';
import 'scan_controller.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/error_service.dart';

/// Binding para el módulo de escaneo de texto
/// Registra todas las dependencias necesarias para el proceso de OCR
class ScanBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar servicios como singletons si no existen
    Get.lazyPut<ErrorService>(() => ErrorService(), fenix: true);
    Get.lazyPut<CameraService>(() => CameraService(), fenix: true);
    Get.lazyPut<OCRService>(() => OCRService(), fenix: true);
    Get.lazyPut<TTSService>(() => TTSService(), fenix: true);
    
    // Registrar controlador del módulo
    Get.lazyPut<ScanController>(() => ScanController());
  }
}
