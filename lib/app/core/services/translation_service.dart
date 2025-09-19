import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'debug_console_service.dart';

/// Idiomas soportados para traducción
enum SupportedLanguage {
  spanish('es', 'Español', '🇪🇸'),
  english('en', 'English', '🇺🇸');

  const SupportedLanguage(this.code, this.name, this.flag);
  
  final String code;
  final String name;
  final String flag;
}

/// Resultado de traducción
class TranslationResult {
  final String originalText;
  final String translatedText;
  final SupportedLanguage sourceLanguage;
  final SupportedLanguage targetLanguage;
  final double confidence;
  final DateTime timestamp;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.confidence,
    required this.timestamp,
  });
}

/// Servicio de traducción usando Google Translate API (gratuita)
class TranslationService extends GetxService {
  static const String _baseUrl = 'https://translate.googleapis.com/translate_a/single';
  
  /// Estados reactivos
  final RxBool _isTranslating = false.obs;
  final RxList<TranslationResult> _translationHistory = <TranslationResult>[].obs;
  
  bool get isTranslating => _isTranslating.value;
  List<TranslationResult> get translationHistory => _translationHistory;
  
  @override
  void onInit() {
    super.onInit();
    DebugLog.i('TranslationService initialized', category: LogCategory.service);
  }
  
  /// Traduce texto de un idioma a otro
  Future<TranslationResult?> translateText({
    required String text,
    required SupportedLanguage targetLanguage,
    SupportedLanguage? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) {
      DebugLog.w('Empty text provided for translation', category: LogCategory.service);
      return null;
    }
    
    _isTranslating.value = true;
    
    try {
      // Auto-detectar idioma fuente si no se especifica
      final sourceLang = sourceLanguage?.code ?? 'auto';
      
      DebugLog.d('Translating text: ${text.substring(0, text.length.clamp(0, 50))}... to ${targetLanguage.code}', 
                category: LogCategory.service);
      
      final response = await _makeTranslationRequest(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLanguage.code,
      );
      
      if (response != null) {
        final result = TranslationResult(
          originalText: text,
          translatedText: response['translatedText'],
          sourceLanguage: _getLanguageFromCode(response['detectedSourceLanguage'] ?? sourceLang),
          targetLanguage: targetLanguage,
          confidence: response['confidence'] ?? 0.9,
          timestamp: DateTime.now(),
        );
        
        // Agregar al historial
        _translationHistory.insert(0, result);
        if (_translationHistory.length > 50) {
          _translationHistory.removeRange(50, _translationHistory.length);
        }
        
        DebugLog.i('Translation completed: ${response['detectedSourceLanguage']} → ${targetLanguage.code}', 
                  category: LogCategory.service);
        
        return result;
      }
      
    } catch (e) {
      DebugLog.e('Error translating text: $e', category: LogCategory.service);
    } finally {
      _isTranslating.value = false;
    }
    
    return null;
  }
  
  /// Realiza la petición de traducción a Google Translate
  Future<Map<String, dynamic>?> _makeTranslationRequest({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': sourceLang,
        'tl': targetLang,
        'dt': 't',
        'q': text,
      });
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final translations = decoded[0] as List;
          final translatedText = translations
              .map((t) => t is List && t.isNotEmpty ? t[0].toString() : '')
              .where((t) => t.isNotEmpty)
              .join(' ');
          
          // Intentar detectar idioma fuente
          String? detectedLang;
          if (decoded.length > 2 && decoded[2] is String) {
            detectedLang = decoded[2] as String;
          }
          
          return {
            'translatedText': translatedText,
            'detectedSourceLanguage': detectedLang ?? sourceLang,
            'confidence': 0.9, // Google Translate no devuelve confidence, usar valor alto
          };
        }
      }
      
      DebugLog.e('Translation API error: ${response.statusCode}', category: LogCategory.service);
      return null;
      
    } catch (e) {
      DebugLog.e('Translation request error: $e', category: LogCategory.service);
      return null;
    }
  }
  
  /// Convierte código de idioma a SupportedLanguage
  SupportedLanguage _getLanguageFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'es':
      case 'spa':
        return SupportedLanguage.spanish;
      case 'en':
      case 'eng':
        return SupportedLanguage.english;
      default:
        return SupportedLanguage.spanish; // Default
    }
  }
  
  /// Obtiene idiomas disponibles
  List<SupportedLanguage> getAvailableLanguages() {
    return SupportedLanguage.values;
  }
  
  /// Detecta idioma del texto (usando la API de traducción)
  Future<SupportedLanguage?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return null;
    
    try {
      final result = await _makeTranslationRequest(
        text: text.substring(0, text.length.clamp(0, 100)), // Solo primeros 100 caracteres
        sourceLang: 'auto',
        targetLang: 'en', // Traducir a inglés para detectar idioma
      );
      
      if (result != null) {
        final detectedCode = result['detectedSourceLanguage'];
        return _getLanguageFromCode(detectedCode ?? 'es');
      }
    } catch (e) {
      DebugLog.e('Error detecting language: $e', category: LogCategory.service);
    }
    
    return null;
  }
  
  /// Limpia el historial de traducciones
  void clearHistory() {
    _translationHistory.clear();
    DebugLog.i('Translation history cleared', category: LogCategory.service);
  }
  
  /// Obtiene estadísticas de uso
  Map<String, dynamic> getUsageStats() {
    final totalTranslations = _translationHistory.length;
    final languagePairs = <String, int>{};
    
    for (final translation in _translationHistory) {
      final pair = '${translation.sourceLanguage.code} → ${translation.targetLanguage.code}';
      languagePairs[pair] = (languagePairs[pair] ?? 0) + 1;
    }
    
    return {
      'totalTranslations': totalTranslations,
      'languagePairs': languagePairs,
      'lastTranslation': _translationHistory.isNotEmpty 
        ? _translationHistory.first.timestamp 
        : null,
    };
  }
}
