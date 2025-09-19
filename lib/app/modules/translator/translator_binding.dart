import 'package:get/get.dart';
import 'translator_controller.dart';
import '../../core/services/translation_service.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/error_service.dart';

/// Binding para el módulo de traductor
/// Registra todas las dependencias necesarias para la funcionalidad de traducción
class TranslatorBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar servicios necesarios
    Get.lazyPut<TranslationService>(() => TranslationService(), fenix: true);
    Get.lazyPut<CameraService>(() => CameraService(), fenix: true);
    Get.lazyPut<OCRService>(() => OCRService(), fenix: true);
    Get.lazyPut<TTSService>(() => TTSService(), fenix: true);
    Get.lazyPut<ErrorService>(() => ErrorService(), fenix: true);
    
    // Registrar controlador del módulo
    Get.lazyPut<TranslatorController>(() => TranslatorController());
  }
}
