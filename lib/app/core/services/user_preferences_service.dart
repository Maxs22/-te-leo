import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'debug_console_service.dart';

/// Claves para SharedPreferences
class PreferenceKeys {
  // Onboarding y primera vez
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String firstLaunchDate = 'first_launch_date';
  static const String lastAppVersion = 'last_app_version';
  
  // Información del usuario
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userRegistrationDate = 'user_registration_date';
  
  // Progreso de lectura
  static const String lastDocumentId = 'last_document_id';
  static const String lastReadingPosition = 'last_reading_position';
  static const String lastReadingPercentage = 'last_reading_percentage';
  static const String lastReadingDate = 'last_reading_date';
  static const String totalReadingTime = 'total_reading_time';
  
  // Estadísticas de uso
  static const String documentsScanned = 'documents_scanned';
  static const String minutesListened = 'minutes_listened';
  static const String consecutiveDays = 'consecutive_days';
  static const String lastUsageDate = 'last_usage_date';
  
  // Configuraciones de app
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String fontSize = 'font_size';
  static const String ttsSpeed = 'tts_speed';
  static const String ttsVoice = 'tts_voice';
  
  // Premium y suscripciones
  static const String isPremium = 'is_premium';
  static const String premiumExpirationDate = 'premium_expiration_date';
  static const String licenseType = 'license_type';
  static const String demoActivationDate = 'demo_activation_date';
  
  // Configuraciones de funcionalidades
  static const String autoScrollEnabled = 'auto_scroll_enabled';
  static const String highlightCurrentWord = 'highlight_current_word';
  static const String saveReadingProgress = 'save_reading_progress';
  static const String showTutorialHints = 'show_tutorial_hints';
}

/// Servicio para gestionar preferencias de usuario con SharedPreferences
class UserPreferencesService extends GetxService {
  static UserPreferencesService get to => Get.find();

  late SharedPreferences _prefs;

  // Estado reactivo
  final RxBool _hasSeenOnboarding = false.obs;
  final RxString _userName = ''.obs;
  final RxString _lastDocumentId = ''.obs;
  final RxInt _lastReadingPosition = 0.obs;
  final RxDouble _lastReadingPercentage = 0.0.obs;
  final RxInt _documentsScanned = 0.obs;
  final RxInt _minutesListened = 0.obs;
  final RxInt _consecutiveDays = 1.obs;

  // Getters reactivos
  bool get hasSeenOnboarding => _hasSeenOnboarding.value;
  String get userName => _userName.value;
  String get lastDocumentId => _lastDocumentId.value;
  int get lastReadingPosition => _lastReadingPosition.value;
  double get lastReadingPercentage => _lastReadingPercentage.value;
  int get documentsScanned => _documentsScanned.value;
  int get minutesListened => _minutesListened.value;
  int get consecutiveDays => _consecutiveDays.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePreferences();
  }

  /// Inicializar SharedPreferences
  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAllPreferences();
      
      DebugLog.i('UserPreferencesService initialized successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing UserPreferencesService: $e', category: LogCategory.service);
      rethrow;
    }
  }

  /// Cargar todas las preferencias
  Future<void> _loadAllPreferences() async {
    try {
      // Onboarding y primera vez
      _hasSeenOnboarding.value = _prefs.getBool(PreferenceKeys.hasSeenOnboarding) ?? false;
      
      // Información del usuario
      _userName.value = _prefs.getString(PreferenceKeys.userName) ?? '';
      
      // Progreso de lectura
      _lastDocumentId.value = _prefs.getString(PreferenceKeys.lastDocumentId) ?? '';
      _lastReadingPosition.value = _prefs.getInt(PreferenceKeys.lastReadingPosition) ?? 0;
      _lastReadingPercentage.value = _prefs.getDouble(PreferenceKeys.lastReadingPercentage) ?? 0.0;
      
      // Estadísticas
      _documentsScanned.value = _prefs.getInt(PreferenceKeys.documentsScanned) ?? 0;
      _minutesListened.value = _prefs.getInt(PreferenceKeys.minutesListened) ?? 0;
      _consecutiveDays.value = _prefs.getInt(PreferenceKeys.consecutiveDays) ?? 1;

      // Calcular días consecutivos basado en última fecha de uso
      await _updateConsecutiveDays();

      DebugLog.d('Preferences loaded: onboarding=${_hasSeenOnboarding.value}, user=${_userName.value}', 
                 category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error loading preferences: $e', category: LogCategory.service);
    }
  }

  /// Marcar onboarding como visto
  Future<void> markOnboardingAsSeen() async {
    try {
      await _prefs.setBool(PreferenceKeys.hasSeenOnboarding, true);
      _hasSeenOnboarding.value = true;
      
      DebugLog.i('Onboarding marked as seen', category: LogCategory.ui);
    } catch (e) {
      DebugLog.e('Error marking onboarding as seen: $e', category: LogCategory.service);
    }
  }

  /// Guardar nombre de usuario
  Future<void> saveUserName(String name) async {
    try {
      await _prefs.setString(PreferenceKeys.userName, name);
      _userName.value = name;
      
      // Si es la primera vez que se guarda el nombre, marcar fecha de registro
      if (!_prefs.containsKey(PreferenceKeys.userRegistrationDate)) {
        await _prefs.setString(PreferenceKeys.userRegistrationDate, DateTime.now().toIso8601String());
      }
      
      DebugLog.i('User name saved: $name', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving user name: $e', category: LogCategory.service);
    }
  }

  /// Guardar progreso de lectura
  Future<void> saveReadingProgress({
    required String documentId,
    required int position,
    required double percentage,
  }) async {
    try {
      await Future.wait([
        _prefs.setString(PreferenceKeys.lastDocumentId, documentId),
        _prefs.setInt(PreferenceKeys.lastReadingPosition, position),
        _prefs.setDouble(PreferenceKeys.lastReadingPercentage, percentage),
        _prefs.setString(PreferenceKeys.lastReadingDate, DateTime.now().toIso8601String()),
      ]);

      _lastDocumentId.value = documentId;
      _lastReadingPosition.value = position;
      _lastReadingPercentage.value = percentage;

      DebugLog.d('Reading progress saved: doc=$documentId, pos=$position, %=${percentage.toStringAsFixed(2)}', 
                 category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving reading progress: $e', category: LogCategory.service);
    }
  }

  /// Obtener progreso de lectura para un documento
  Map<String, dynamic>? getReadingProgress(String documentId) {
    try {
      final lastDocId = _prefs.getString(PreferenceKeys.lastDocumentId);
      
      if (lastDocId != documentId) {
        return null; // No hay progreso para este documento
      }

      final position = _prefs.getInt(PreferenceKeys.lastReadingPosition) ?? 0;
      final percentage = _prefs.getDouble(PreferenceKeys.lastReadingPercentage) ?? 0.0;
      final dateString = _prefs.getString(PreferenceKeys.lastReadingDate);
      
      return {
        'position': position,
        'percentage': percentage,
        'date': dateString != null ? DateTime.tryParse(dateString) : null,
        'hasProgress': position > 0 || percentage > 0.05,
      };
    } catch (e) {
      DebugLog.e('Error getting reading progress: $e', category: LogCategory.service);
      return null;
    }
  }

  /// Limpiar progreso de lectura
  Future<void> clearReadingProgress() async {
    try {
      await Future.wait([
        _prefs.remove(PreferenceKeys.lastDocumentId),
        _prefs.remove(PreferenceKeys.lastReadingPosition),
        _prefs.remove(PreferenceKeys.lastReadingPercentage),
        _prefs.remove(PreferenceKeys.lastReadingDate),
      ]);

      _lastDocumentId.value = '';
      _lastReadingPosition.value = 0;
      _lastReadingPercentage.value = 0.0;

      DebugLog.i('Reading progress cleared', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error clearing reading progress: $e', category: LogCategory.service);
    }
  }

  /// Incrementar documentos escaneados
  Future<void> incrementDocumentsScanned() async {
    try {
      final newCount = _documentsScanned.value + 1;
      await _prefs.setInt(PreferenceKeys.documentsScanned, newCount);
      _documentsScanned.value = newCount;
      
      DebugLog.d('Documents scanned incremented to: $newCount', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error incrementing documents scanned: $e', category: LogCategory.service);
    }
  }

  /// Agregar tiempo de escucha
  Future<void> addListeningTime(int minutes) async {
    try {
      final newTotal = _minutesListened.value + minutes;
      await _prefs.setInt(PreferenceKeys.minutesListened, newTotal);
      _minutesListened.value = newTotal;
      
      DebugLog.d('Listening time updated: +${minutes}min, total=${newTotal}min', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error adding listening time: $e', category: LogCategory.service);
    }
  }

  /// Actualizar días consecutivos
  Future<void> _updateConsecutiveDays() async {
    try {
      final lastUsageDateString = _prefs.getString(PreferenceKeys.lastUsageDate);
      final now = DateTime.now();
      
      if (lastUsageDateString == null) {
        // Primera vez usando la app
        await _prefs.setString(PreferenceKeys.lastUsageDate, now.toIso8601String());
        await _prefs.setInt(PreferenceKeys.consecutiveDays, 1);
        _consecutiveDays.value = 1;
        return;
      }

      final lastUsageDate = DateTime.tryParse(lastUsageDateString);
      if (lastUsageDate == null) return;

      final daysDifference = now.difference(lastUsageDate).inDays;
      
      if (daysDifference == 0) {
        // Mismo día, mantener racha
        return;
      } else if (daysDifference == 1) {
        // Día consecutivo, incrementar racha
        final newStreak = _consecutiveDays.value + 1;
        await _prefs.setInt(PreferenceKeys.consecutiveDays, newStreak);
        _consecutiveDays.value = newStreak;
      } else {
        // Se rompió la racha, reiniciar
        await _prefs.setInt(PreferenceKeys.consecutiveDays, 1);
        _consecutiveDays.value = 1;
      }

      // Actualizar fecha de último uso
      await _prefs.setString(PreferenceKeys.lastUsageDate, now.toIso8601String());
      
      DebugLog.d('Consecutive days updated: ${_consecutiveDays.value}', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error updating consecutive days: $e', category: LogCategory.service);
    }
  }

  /// Registrar uso diario
  Future<void> registerDailyUsage() async {
    await _updateConsecutiveDays();
  }

  /// Verificar si es la primera vez que se abre la app
  bool get isFirstLaunch {
    return !_prefs.containsKey(PreferenceKeys.firstLaunchDate);
  }

  /// Marcar primera apertura de la app
  Future<void> markFirstLaunch() async {
    try {
      if (isFirstLaunch) {
        await _prefs.setString(PreferenceKeys.firstLaunchDate, DateTime.now().toIso8601String());
        DebugLog.i('First launch marked', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error marking first launch: $e', category: LogCategory.service);
    }
  }

  /// Verificar si hay progreso de lectura pendiente
  bool hasResumeableProgress() {
    final lastDocId = _prefs.getString(PreferenceKeys.lastDocumentId);
    final position = _prefs.getInt(PreferenceKeys.lastReadingPosition) ?? 0;
    final percentage = _prefs.getDouble(PreferenceKeys.lastReadingPercentage) ?? 0.0;
    
    return lastDocId != null && 
           lastDocId.isNotEmpty && 
           (position > 0 || percentage > 0.05);
  }

  /// Obtener información de resumen para mostrar en welcome
  Map<String, dynamic> getWelcomeSummary() {
    return {
      'userName': _userName.value.isNotEmpty ? _userName.value : 'Usuario',
      'documentsScanned': _documentsScanned.value,
      'minutesListened': _minutesListened.value,
      'consecutiveDays': _consecutiveDays.value,
      'hasResumeableProgress': hasResumeableProgress(),
      'lastDocumentId': _lastDocumentId.value,
      'lastReadingPercentage': _lastReadingPercentage.value,
    };
  }

  /// Obtener configuración de tema
  String getThemeMode() {
    return _prefs.getString(PreferenceKeys.themeMode) ?? 'system';
  }

  /// Guardar tamaño de fuente
  Future<void> saveFontSize(double fontSize) async {
    try {
      await _prefs.setDouble(PreferenceKeys.fontSize, fontSize);
      DebugLog.d('Font size saved: $fontSize', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving font size: $e', category: LogCategory.service);
    }
  }

  /// Obtener tamaño de fuente
  double getFontSize() {
    return _prefs.getDouble(PreferenceKeys.fontSize) ?? 1.0;
  }

  /// Guardar configuración de TTS
  Future<void> saveTTSSettings({
    double? speed,
    String? voice,
  }) async {
    try {
      final futures = <Future>[];
      
      if (speed != null) {
        futures.add(_prefs.setDouble(PreferenceKeys.ttsSpeed, speed));
      }
      
      if (voice != null) {
        futures.add(_prefs.setString(PreferenceKeys.ttsVoice, voice));
      }
      
      await Future.wait(futures);
      DebugLog.d('TTS settings saved: speed=$speed, voice=$voice', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving TTS settings: $e', category: LogCategory.service);
    }
  }

  /// Obtener configuración de TTS
  Map<String, dynamic> getTTSSettings() {
    return {
      'speed': _prefs.getDouble(PreferenceKeys.ttsSpeed) ?? 0.5,
      'voice': _prefs.getString(PreferenceKeys.ttsVoice),
    };
  }

  /// Guardar estado premium
  Future<void> savePremiumStatus({
    required bool isPremium,
    DateTime? expirationDate,
    String? licenseType,
  }) async {
    try {
      final futures = <Future>[
        _prefs.setBool(PreferenceKeys.isPremium, isPremium),
      ];
      
      if (expirationDate != null) {
        futures.add(_prefs.setString(PreferenceKeys.premiumExpirationDate, expirationDate.toIso8601String()));
      }
      
      if (licenseType != null) {
        futures.add(_prefs.setString(PreferenceKeys.licenseType, licenseType));
      }
      
      await Future.wait(futures);
      DebugLog.d('Premium status saved: isPremium=$isPremium', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving premium status: $e', category: LogCategory.service);
    }
  }

  /// Verificar estado premium
  bool isPremiumActive() {
    try {
      final isPremium = _prefs.getBool(PreferenceKeys.isPremium) ?? false;
      if (!isPremium) return false;

      final expirationString = _prefs.getString(PreferenceKeys.premiumExpirationDate);
      if (expirationString == null) return false;

      final expirationDate = DateTime.tryParse(expirationString);
      if (expirationDate == null) return false;

      return DateTime.now().isBefore(expirationDate);
    } catch (e) {
      DebugLog.e('Error checking premium status: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Activar modo demo
  Future<void> activateDemoMode() async {
    try {
      final expirationDate = DateTime.now().add(const Duration(days: 7));
      
      await Future.wait([
        _prefs.setBool(PreferenceKeys.isPremium, true),
        _prefs.setString(PreferenceKeys.licenseType, 'demo'),
        _prefs.setString(PreferenceKeys.premiumExpirationDate, expirationDate.toIso8601String()),
        _prefs.setString(PreferenceKeys.demoActivationDate, DateTime.now().toIso8601String()),
      ]);
      
      DebugLog.i('Demo mode activated for 7 days', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error activating demo mode: $e', category: LogCategory.service);
    }
  }

  /// Obtener días restantes de demo
  int getDemoRemainingDays() {
    try {
      final licenseType = _prefs.getString(PreferenceKeys.licenseType);
      if (licenseType != 'demo') return 0;

      final expirationString = _prefs.getString(PreferenceKeys.premiumExpirationDate);
      if (expirationString == null) return 0;

      final expirationDate = DateTime.tryParse(expirationString);
      if (expirationDate == null) return 0;

      final remainingDays = expirationDate.difference(DateTime.now()).inDays;
      return remainingDays.clamp(0, 7);
    } catch (e) {
      DebugLog.e('Error getting demo remaining days: $e', category: LogCategory.service);
      return 0;
    }
  }

  /// Limpiar todos los datos (para reset de app)
  Future<void> clearAllData() async {
    try {
      await _prefs.clear();
      await _loadAllPreferences(); // Recargar valores por defecto
      
      DebugLog.i('All user data cleared', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error clearing all data: $e', category: LogCategory.service);
    }
  }

  /// Exportar todas las preferencias (para backup)
  Map<String, dynamic> exportPreferences() {
    try {
      final allKeys = _prefs.getKeys();
      final exportData = <String, dynamic>{};
      
      for (final key in allKeys) {
        final value = _prefs.get(key);
        exportData[key] = value;
      }
      
      DebugLog.i('Preferences exported: ${exportData.length} keys', category: LogCategory.service);
      return exportData;
    } catch (e) {
      DebugLog.e('Error exporting preferences: $e', category: LogCategory.service);
      return {};
    }
  }

  /// Importar preferencias (desde backup)
  Future<void> importPreferences(Map<String, dynamic> data) async {
    try {
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is bool) {
          await _prefs.setBool(key, value);
        } else if (value is int) {
          await _prefs.setInt(key, value);
        } else if (value is double) {
          await _prefs.setDouble(key, value);
        } else if (value is String) {
          await _prefs.setString(key, value);
        } else if (value is List<String>) {
          await _prefs.setStringList(key, value);
        }
      }
      
      await _loadAllPreferences(); // Recargar valores
      DebugLog.i('Preferences imported: ${data.length} keys', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error importing preferences: $e', category: LogCategory.service);
    }
  }

  /// Configuraciones de tema
  
  /// Obtener modo de tema guardado
  String get savedThemeMode => _prefs.getString(PreferenceKeys.themeMode) ?? 'system';
  
  /// Guardar modo de tema
  Future<void> saveThemeMode(String themeMode) async {
    try {
      await _prefs.setString(PreferenceKeys.themeMode, themeMode);
      DebugLog.d('Theme mode saved: $themeMode', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving theme mode: $e', category: LogCategory.service);
    }
  }
  
  /// Obtener idioma guardado
  String get savedLanguage => _prefs.getString(PreferenceKeys.language) ?? 'es_ES';
  
  /// Guardar idioma
  Future<void> saveLanguage(String language) async {
    try {
      await _prefs.setString(PreferenceKeys.language, language);
      DebugLog.d('Language saved: $language', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving language: $e', category: LogCategory.service);
    }
  }
  
  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasSeenOnboarding': hasSeenOnboarding,
      'userName': userName,
      'documentsScanned': documentsScanned,
      'minutesListened': minutesListened,
      'consecutiveDays': consecutiveDays,
      'lastDocumentId': lastDocumentId,
      'lastReadingPosition': lastReadingPosition,
      'lastReadingPercentage': lastReadingPercentage,
      'isPremiumActive': isPremiumActive(),
      'demoRemainingDays': getDemoRemainingDays(),
      'isFirstLaunch': isFirstLaunch,
      'hasResumeableProgress': hasResumeableProgress(),
      'totalPreferences': _prefs.getKeys().length,
      'themeMode': savedThemeMode,
      'language': savedLanguage,
    };
  }
}
