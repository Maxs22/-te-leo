import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../global_widgets/modern_dialog.dart';
import 'tts_service.dart';
import 'debug_console_service.dart';

/// Servicio para gestionar voces TTS y su disponibilidad
class VoiceManagerService extends GetxService {
  final TTSService _ttsService = Get.find<TTSService>();
  
  /// Lista de voces disponibles en el dispositivo
  final RxList<Map<String, dynamic>> _availableVoices = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get availableVoices => _availableVoices;
  
  /// Indica si se están cargando las voces
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadAvailableVoices();
  }

  /// Carga las voces disponibles en el dispositivo
  Future<void> _loadAvailableVoices() async {
    try {
      _isLoading.value = true;
      
      final voices = await _ttsService.obtenerVocesReales();
      _availableVoices.value = voices;
      
      // Log de voces disponibles
      try {
        final debugService = Get.find<DebugConsoleService>();
        debugService.log(
          'Loaded ${voices.length} voices from device',
          level: LogLevel.info,
          category: LogCategory.service,
        );
      } catch (_) {}
      
    } catch (e) {
      try {
        final debugService = Get.find<DebugConsoleService>();
        debugService.log(
          'Error loading available voices: $e',
          level: LogLevel.error,
          category: LogCategory.service,
        );
      } catch (_) {}
    } finally {
      _isLoading.value = false;
    }
  }

  /// Verifica si una voz específica está disponible
  bool isVoiceAvailable(String voiceName, String locale) {
    return _availableVoices.any((voice) => 
      voice['name'] == voiceName && voice['locale'] == locale
    );
  }

  /// Obtiene voces compatibles para un idioma
  List<Map<String, dynamic>> getCompatibleVoices(String locale) {
    final languageCode = locale.split('-')[0];
    return _availableVoices.where((voice) =>
      voice['locale']?.toString().startsWith(languageCode) == true
    ).toList();
  }

  /// Verifica la disponibilidad de voces y sugiere descargas
  Future<void> checkVoiceAvailability() async {
    final spanishVoices = getCompatibleVoices('es-ES');
    final englishVoices = getCompatibleVoices('en-US');
    
    if (spanishVoices.isEmpty || englishVoices.isEmpty) {
      await _showVoiceDownloadSuggestion(
        missingSpanish: spanishVoices.isEmpty,
        missingEnglish: englishVoices.isEmpty,
      );
    }
  }

  /// Muestra sugerencia para descargar voces
  Future<void> _showVoiceDownloadSuggestion({
    required bool missingSpanish,
    required bool missingEnglish,
  }) async {
    String title = 'voice_download_needed'.tr;
    String message = '';
    
    if (missingSpanish && missingEnglish) {
      message = 'voice_download_both_missing'.tr;
    } else if (missingSpanish) {
      message = 'voice_download_spanish_missing'.tr;
    } else {
      message = 'voice_download_english_missing'.tr;
    }
    
    final result = await ModernDialog.mostrarConfirmacion(
      titulo: title,
      mensaje: '$message\n\n${'voice_download_instructions'.tr}',
      textoConfirmar: 'open_tts_settings'.tr,
      textoCancelar: 'continue_without_voices'.tr,
      icono: Icons.record_voice_over,
    );
    
    if (result) {
      await _openTTSSettings();
    }
  }

  /// Intenta abrir la configuración de TTS del sistema
  Future<void> _openTTSSettings() async {
    try {
      // Intentar abrir configuración de TTS en Android
      await _openAndroidTTSSettings();
    } catch (e) {
      // Si falla, mostrar instrucciones manuales
      await _showManualInstructions();
    }
  }

  /// Abre configuración de TTS en Android
  Future<void> _openAndroidTTSSettings() async {
    const platform = MethodChannel('com.teleo.te_leo/tts_settings');
    try {
      await platform.invokeMethod('openTTSSettings');
    } catch (e) {
      throw Exception('No se pudo abrir configuración TTS: $e');
    }
  }

  /// Muestra instrucciones manuales para descargar voces
  Future<void> _showManualInstructions() async {
    await ModernDialog.mostrarInformacion(
      titulo: 'manual_voice_instructions'.tr,
      mensaje: 'manual_voice_steps'.tr,
      icono: Icons.help_outline,
    );
  }

  /// Refresca la lista de voces disponibles
  Future<void> refreshVoices() async {
    await _loadAvailableVoices();
  }

  /// Obtiene información detallada de una voz
  Map<String, dynamic>? getVoiceInfo(String voiceName, String locale) {
    try {
      return _availableVoices.firstWhere(
        (voice) => voice['name'] == voiceName && voice['locale'] == locale,
      );
    } catch (e) {
      return null;
    }
  }
}
