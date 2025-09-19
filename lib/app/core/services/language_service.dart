import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_preferences_service.dart';
import 'debug_console_service.dart';

/// Servicio para gestión de idiomas e internacionalización
class LanguageService extends GetxController {
  UserPreferencesService? _prefsService;
  
  // Estado reactivo del idioma
  final Rx<Locale> _currentLocale = const Locale('es', 'ES').obs;
  
  /// Getter para el idioma actual
  Locale get currentLocale => _currentLocale.value;
  
  /// Idiomas soportados
  static const List<Locale> supportedLocales = [
    Locale('es', 'ES'), // Español
    Locale('en', 'US'), // Inglés
  ];
  
  /// Nombres de idiomas para mostrar en UI
  static const Map<String, String> languageNames = {
    'es_ES': 'Español',
    'en_US': 'English',
  };
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeLanguage();
  }
  
  /// Inicializar el idioma desde las preferencias
  Future<void> _initializeLanguage() async {
    try {
      _prefsService = Get.find<UserPreferencesService>();
      
      final savedLanguage = _prefsService?.savedLanguage ?? 'es_ES';
      _currentLocale.value = _getLocaleFromString(savedLanguage);
      
      // Aplicar el idioma inmediatamente
      Get.updateLocale(_currentLocale.value);
      
      DebugLog.i('Language initialized: $savedLanguage', category: LogCategory.app);
    } catch (e) {
      DebugLog.w('Could not initialize language service, using Spanish default', category: LogCategory.app);
      _currentLocale.value = const Locale('es', 'ES');
    }
  }
  
  /// Cambiar el idioma
  Future<void> changeLanguage(Locale newLocale) async {
    try {
      _currentLocale.value = newLocale;
      
      // Aplicar el idioma
      Get.updateLocale(newLocale);
      
      // Guardar en preferencias
      if (_prefsService != null) {
        await _prefsService!.saveLanguage(_getStringFromLocale(newLocale));
      }
      
      DebugLog.i('Language changed to: ${_getStringFromLocale(newLocale)}', category: LogCategory.app);
    } catch (e) {
      DebugLog.e('Error changing language: $e', category: LogCategory.app);
    }
  }
  
  /// Cambiar idioma por string
  Future<void> changeLanguageByString(String languageCode) async {
    final locale = _getLocaleFromString(languageCode);
    await changeLanguage(locale);
  }
  
  /// Alternar entre idiomas
  Future<void> toggleLanguage() async {
    if (_currentLocale.value.languageCode == 'es') {
      await changeLanguage(const Locale('en', 'US'));
    } else {
      await changeLanguage(const Locale('es', 'ES'));
    }
  }
  
  /// Obtener Locale desde string
  Locale _getLocaleFromString(String languageString) {
    switch (languageString) {
      case 'en_US':
        return const Locale('en', 'US');
      case 'es_ES':
      default:
        return const Locale('es', 'ES');
    }
  }
  
  /// Obtener string desde Locale
  String _getStringFromLocale(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  
  /// Obtener nombre legible del idioma actual
  String get currentLanguageName {
    final key = _getStringFromLocale(_currentLocale.value);
    return languageNames[key] ?? 'Español';
  }
  
  /// Verificar si el idioma actual es inglés
  bool get isEnglish => _currentLocale.value.languageCode == 'en';
  
  /// Verificar si el idioma actual es español
  bool get isSpanish => _currentLocale.value.languageCode == 'es';
  
  /// Obtener todos los idiomas disponibles
  List<Map<String, String>> get availableLanguages {
    return supportedLocales.map((locale) {
      final key = _getStringFromLocale(locale);
      return {
        'code': key,
        'name': languageNames[key] ?? key,
      };
    }).toList();
  }
}
