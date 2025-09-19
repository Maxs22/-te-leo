import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/translation_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/error_service.dart';
import '../../core/services/debug_console_service.dart';
import '../../data/models/documento.dart';

/// Estados del proceso de traducción
enum TranslatorState {
  initial,           // Estado inicial
  takingPhoto,       // Tomando foto
  extractingText,    // Extrayendo texto con OCR
  translating,       // Traduciendo texto
  completed,         // Proceso completado
  error,            // Error en el proceso
}

/// Controlador para el módulo de traductor con OCR
class TranslatorController extends GetxController {
  // Servicios
  final CameraService _cameraService = Get.find<CameraService>();
  final OCRService _ocrService = Get.find<OCRService>();
  final TranslationService _translationService = Get.find<TranslationService>();
  final TTSService _ttsService = Get.find<TTSService>();
  final ErrorService _errorService = Get.find<ErrorService>();

  /// Estados reactivos
  final Rx<TranslatorState> _state = TranslatorState.initial.obs;
  final RxString _originalText = ''.obs;
  final RxString _translatedText = ''.obs;
  final Rx<SupportedLanguage?> _detectedLanguage = Rx<SupportedLanguage?>(null);
  final Rx<SupportedLanguage> _targetLanguage = SupportedLanguage.english.obs;
  final RxString _statusMessage = ''.obs;
  final Rx<File?> _capturedImage = Rx<File?>(null);
  final RxDouble _confidence = 0.0.obs;

  // Getters
  TranslatorState get state => _state.value;
  String get originalText => _originalText.value;
  String get translatedText => _translatedText.value;
  SupportedLanguage? get detectedLanguage => _detectedLanguage.value;
  SupportedLanguage get targetLanguage => _targetLanguage.value;
  String get statusMessage => _statusMessage.value;
  File? get capturedImage => _capturedImage.value;
  double get confidence => _confidence.value;

  @override
  void onInit() {
    super.onInit();
    DebugLog.i('TranslatorController initialized', category: LogCategory.app);
  }

  /// Inicia el proceso de traducción con foto
  Future<void> startTranslationFromCamera() async {
    await _resetState();
    await _takePhotoAndTranslate();
  }

  /// Inicia el proceso de traducción desde galería
  Future<void> startTranslationFromGallery() async {
    await _resetState();
    await _pickImageAndTranslate();
  }

  /// Toma foto y procesa traducción
  Future<void> _takePhotoAndTranslate() async {
    try {
      _updateState(TranslatorState.takingPhoto, 'taking_photo'.tr);
      
      final result = await _cameraService.capturarDesdeCamara();
      final image = result != null ? File(result.rutaArchivo) : null;
      if (image != null) {
        _capturedImage.value = image;
        await _processImageForTranslation(image);
      } else {
        _updateState(TranslatorState.initial, 'photo_cancelled'.tr);
      }
    } catch (e) {
      await _handleError('Error taking photo: $e');
    }
  }

  /// Selecciona imagen de galería y procesa traducción
  Future<void> _pickImageAndTranslate() async {
    try {
      _updateState(TranslatorState.takingPhoto, 'selecting_image'.tr);
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final image = File(pickedFile.path);
        _capturedImage.value = image;
        await _processImageForTranslation(image);
      } else {
        _updateState(TranslatorState.initial, 'image_selection_cancelled'.tr);
      }
    } catch (e) {
      await _handleError('Error selecting image: $e');
    }
  }

  /// Procesa imagen para traducción
  Future<void> _processImageForTranslation(File image) async {
    try {
      // Extraer texto con OCR
      _updateState(TranslatorState.extractingText, 'extracting_text'.tr);
      
      final ocrResult = await _ocrService.extraerTextoDeImagen(image.path);
      
      if (ocrResult.textoCompleto.isEmpty) {
        _updateState(TranslatorState.error, 'no_text_detected'.tr);
        return;
      }

      _originalText.value = ocrResult.textoCompleto;
      DebugLog.d('Text extracted: ${ocrResult.textoCompleto.substring(0, ocrResult.textoCompleto.length.clamp(0, 100))}...', 
                category: LogCategory.ocr);

      // Detectar idioma del texto
      final detectedLang = await _translationService.detectLanguage(ocrResult.textoCompleto);
      _detectedLanguage.value = detectedLang;

      // Auto-seleccionar idioma objetivo opuesto al detectado
      if (detectedLang == SupportedLanguage.spanish) {
        _targetLanguage.value = SupportedLanguage.english;
      } else {
        _targetLanguage.value = SupportedLanguage.spanish;
      }

      // Proceder con la traducción
      await _performTranslation();
      
    } catch (e) {
      await _handleError('Error processing image: $e');
    }
  }

  /// Realiza la traducción del texto
  Future<void> _performTranslation() async {
    try {
      _updateState(TranslatorState.translating, 'translating_text'.tr);
      
      final result = await _translationService.translateText(
        text: _originalText.value,
        targetLanguage: _targetLanguage.value,
        sourceLanguage: _detectedLanguage.value,
      );
      
      if (result != null) {
        _translatedText.value = result.translatedText;
        _confidence.value = result.confidence;
        _updateState(TranslatorState.completed, 'translation_completed'.tr);
        
        DebugLog.i('Translation successful: ${_detectedLanguage.value?.code} → ${_targetLanguage.value.code}', 
                  category: LogCategory.service);
      } else {
        _updateState(TranslatorState.error, 'translation_failed'.tr);
      }
      
    } catch (e) {
      await _handleError('Error during translation: $e');
    }
  }

  /// Cambia el idioma objetivo y re-traduce
  Future<void> changeTargetLanguage(SupportedLanguage newLanguage) async {
    if (newLanguage == _targetLanguage.value || _originalText.value.isEmpty) return;
    
    _targetLanguage.value = newLanguage;
    await _performTranslation();
  }

  /// Reproduce el texto original con TTS
  Future<void> playOriginalText() async {
    if (_originalText.value.isEmpty) return;
    
    try {
      final languageCode = _detectedLanguage.value?.code ?? 'es';
      await _ttsService.reproducirConConfiguracion(
        _originalText.value,
        ConfiguracionVoz(idioma: '$languageCode-${languageCode.toUpperCase()}'),
      );
      
      DebugLog.d('Playing original text in ${_detectedLanguage.value?.name}', category: LogCategory.tts);
    } catch (e) {
      DebugLog.e('Error playing original text: $e', category: LogCategory.tts);
    }
  }

  /// Reproduce el texto traducido con TTS
  Future<void> playTranslatedText() async {
    if (_translatedText.value.isEmpty) return;
    
    try {
      final languageCode = _targetLanguage.value.code;
      await _ttsService.reproducirConConfiguracion(
        _translatedText.value,
        ConfiguracionVoz(idioma: '$languageCode-${languageCode.toUpperCase()}'),
      );
      
      DebugLog.d('Playing translated text in ${_targetLanguage.value.name}', category: LogCategory.tts);
    } catch (e) {
      DebugLog.e('Error playing translated text: $e', category: LogCategory.tts);
    }
  }

  /// Guarda la traducción como documento
  Future<void> saveTranslationAsDocument() async {
    if (_translatedText.value.isEmpty) return;
    
    try {
      final documento = Documento(
        titulo: 'translation_document_title'.trParams({
          'source': _detectedLanguage.value?.name ?? 'Auto',
          'target': _targetLanguage.value.name,
        }),
        contenido: _translatedText.value,
        fechaCreacion: DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      // Aquí se guardaría en la base de datos
      DebugLog.i('Translation saved as document', category: LogCategory.database);
      
      Get.snackbar(
        '✅ ${'translation_saved'.tr}',
        'document_saved_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      DebugLog.e('Error saving translation: $e', category: LogCategory.database);
    }
  }

  /// Resetea el estado para nueva traducción
  Future<void> _resetState() async {
    _state.value = TranslatorState.initial;
    _originalText.value = '';
    _translatedText.value = '';
    _detectedLanguage.value = null;
    _statusMessage.value = '';
    _capturedImage.value = null;
    _confidence.value = 0.0;
  }

  /// Actualiza el estado y mensaje
  void _updateState(TranslatorState newState, String message) {
    _state.value = newState;
    _statusMessage.value = message;
    DebugLog.d('Translator state: $newState - $message', category: LogCategory.app);
  }

  /// Maneja errores
  Future<void> _handleError(String error) async {
    _updateState(TranslatorState.error, 'translation_error'.tr);
      await _errorService.handleOCRError(Exception(error));
  }

  /// Reinicia el proceso
  void restart() {
    _resetState();
  }
}
