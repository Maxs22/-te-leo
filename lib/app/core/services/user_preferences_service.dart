import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/providers/database_provider.dart';
import 'app_install_service.dart';
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
  static const String lastReadingElapsedTime = 'last_reading_elapsed_time';
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

  final _storage = GetStorage();

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
    await _checkNewInstallation();
  }

  /// Inicializar GetStorage
  Future<void> _initializePreferences() async {
    try {
      // GetStorage ya está inicializado en main.dart
      await _loadAllPreferences();

      DebugLog.i('UserPreferencesService initialized successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing UserPreferencesService: $e', category: LogCategory.service);
      rethrow;
    }
  }

  /// Verifica si es una nueva instalación y resetea datos si es necesario
  Future<void> _checkNewInstallation() async {
    try {
      // Verificar si el servicio de instalación está disponible
      if (Get.isRegistered<AppInstallService>()) {
        final installService = Get.find<AppInstallService>();

        if (installService.shouldResetData()) {
          DebugLog.i('New installation detected - resetting user preferences', category: LogCategory.service);
          await _resetForNewInstallation();
        }
      }
    } catch (e) {
      DebugLog.e('Error checking new installation: $e', category: LogCategory.service);
    }
  }

  /// Resetea las preferencias para una nueva instalación
  Future<void> _resetForNewInstallation() async {
    try {
      // Resetear todas las preferencias incluyendo onboarding para nueva instalación
      await _storage.remove(PreferenceKeys.hasSeenOnboarding);
      await _storage.remove(PreferenceKeys.userName);
      await _storage.remove(PreferenceKeys.userEmail);
      await _storage.remove(PreferenceKeys.userRegistrationDate);
      await _storage.remove(PreferenceKeys.lastDocumentId);
      await _storage.remove(PreferenceKeys.lastReadingPosition);
      await _storage.remove(PreferenceKeys.lastReadingPercentage);
      await _storage.remove(PreferenceKeys.lastReadingDate);
      await _storage.remove(PreferenceKeys.totalReadingTime);
      await _storage.remove(PreferenceKeys.documentsScanned);
      await _storage.remove(PreferenceKeys.minutesListened);
      await _storage.remove(PreferenceKeys.consecutiveDays);
      await _storage.remove(PreferenceKeys.lastUsageDate);
      await _storage.remove(PreferenceKeys.isPremium);
      await _storage.remove(PreferenceKeys.premiumExpirationDate);
      await _storage.remove(PreferenceKeys.licenseType);
      await _storage.remove(PreferenceKeys.demoActivationDate);

      // Resetear base de datos también
      try {
        final databaseProvider = DatabaseProvider();
        await databaseProvider.resetearParaNuevaInstalacion();
        DebugLog.i('Database reset for new installation', category: LogCategory.service);
      } catch (e) {
        DebugLog.e('Error resetting database for new installation: $e', category: LogCategory.service);
      }

      // Recargar valores por defecto
      await _loadAllPreferences();

      DebugLog.i('User preferences reset for new installation', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error resetting preferences for new installation: $e', category: LogCategory.service);
    }
  }

  /// Cargar todas las preferencias
  Future<void> _loadAllPreferences() async {
    try {
      // Onboarding y primera vez
      _hasSeenOnboarding.value = _storage.read<bool>(PreferenceKeys.hasSeenOnboarding) ?? false;

      // Información del usuario
      _userName.value = _storage.read<String>(PreferenceKeys.userName) ?? '';

      // Progreso de lectura
      _lastDocumentId.value = _storage.read<String>(PreferenceKeys.lastDocumentId) ?? '';
      _lastReadingPosition.value = _storage.read<int>(PreferenceKeys.lastReadingPosition) ?? 0;
      _lastReadingPercentage.value = _storage.read<double>(PreferenceKeys.lastReadingPercentage) ?? 0.0;

      // Estadísticas
      _documentsScanned.value = _storage.read<int>(PreferenceKeys.documentsScanned) ?? 0;
      _minutesListened.value = _storage.read<int>(PreferenceKeys.minutesListened) ?? 0;
      _consecutiveDays.value = _storage.read<int>(PreferenceKeys.consecutiveDays) ?? 1;

      // Calcular días consecutivos basado en última fecha de uso
      await _updateConsecutiveDays();

      DebugLog.d(
        'Preferences loaded: onboarding=${_hasSeenOnboarding.value}, user=${_userName.value}',
        category: LogCategory.service,
      );
    } catch (e) {
      DebugLog.e('Error loading preferences: $e', category: LogCategory.service);
    }
  }

  /// Marcar onboarding como visto
  Future<void> markOnboardingAsSeen() async {
    try {
      await _storage.write(PreferenceKeys.hasSeenOnboarding, true);
      _hasSeenOnboarding.value = true;

      DebugLog.i('Onboarding marked as seen', category: LogCategory.ui);
    } catch (e) {
      DebugLog.e('Error marking onboarding as seen: $e', category: LogCategory.service);
    }
  }

  /// Resetear onboarding (útil para testing y debugging)
  Future<void> resetOnboarding() async {
    try {
      await _storage.remove(PreferenceKeys.hasSeenOnboarding);
      _hasSeenOnboarding.value = false;

      DebugLog.i('Onboarding reset successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error resetting onboarding: $e', category: LogCategory.service);
    }
  }

  /// Forzar reset completo de onboarding (para debugging)
  Future<void> forceResetOnboarding() async {
    try {
      // Eliminar la clave completamente
      await _storage.remove(PreferenceKeys.hasSeenOnboarding);

      // Resetear la variable reactiva
      _hasSeenOnboarding.value = false;

      // Recargar preferencias para asegurar consistencia
      await _loadAllPreferences();

      DebugLog.i(
        'Onboarding force reset completed - hasSeenOnboarding: ${_hasSeenOnboarding.value}',
        category: LogCategory.service,
      );
    } catch (e) {
      DebugLog.e('Error force resetting onboarding: $e', category: LogCategory.service);
    }
  }

  /// Guardar nombre de usuario
  Future<void> saveUserName(String name) async {
    try {
      await _storage.write(PreferenceKeys.userName, name);
      _userName.value = name;

      // Si es la primera vez que se guarda el nombre, marcar fecha de registro
      if (!_storage.hasData(PreferenceKeys.userRegistrationDate)) {
        await _storage.write(PreferenceKeys.userRegistrationDate, DateTime.now().toIso8601String());
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
    Duration? elapsedTime,
  }) async {
    try {
      final futures = <Future>[
        _storage.write(PreferenceKeys.lastDocumentId, documentId),
        _storage.write(PreferenceKeys.lastReadingPosition, position),
        _storage.write(PreferenceKeys.lastReadingPercentage, percentage),
        _storage.write(PreferenceKeys.lastReadingDate, DateTime.now().toIso8601String()),
      ];

      // Agregar tiempo transcurrido si está disponible
      if (elapsedTime != null) {
        futures.add(_storage.write(PreferenceKeys.lastReadingElapsedTime, elapsedTime.inSeconds));
      }

      await Future.wait(futures);

      _lastDocumentId.value = documentId;
      _lastReadingPosition.value = position;
      _lastReadingPercentage.value = percentage;

      DebugLog.d(
        'Reading progress saved: doc=$documentId, pos=$position, %=${percentage.toStringAsFixed(2)}, time=${elapsedTime?.inSeconds ?? 0}s',
        category: LogCategory.service,
      );
    } catch (e) {
      DebugLog.e('Error saving reading progress: $e', category: LogCategory.service);
    }
  }

  /// Obtener progreso de lectura para un documento
  Map<String, dynamic>? getReadingProgress(String documentId) {
    try {
      final lastDocId = _storage.read<String>(PreferenceKeys.lastDocumentId);

      if (lastDocId != documentId) {
        return null; // No hay progreso para este documento
      }

      final position = _storage.read<int>(PreferenceKeys.lastReadingPosition) ?? 0;
      final percentage = _storage.read<double>(PreferenceKeys.lastReadingPercentage) ?? 0.0;
      final dateString = _storage.read<String>(PreferenceKeys.lastReadingDate);
      final elapsedSeconds = _storage.read<int>(PreferenceKeys.lastReadingElapsedTime) ?? 0;

      return {
        'position': position,
        'percentage': percentage,
        'date': dateString != null ? DateTime.tryParse(dateString) : null,
        'elapsedTime': Duration(seconds: elapsedSeconds),
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
        _storage.remove(PreferenceKeys.lastDocumentId),
        _storage.remove(PreferenceKeys.lastReadingPosition),
        _storage.remove(PreferenceKeys.lastReadingPercentage),
        _storage.remove(PreferenceKeys.lastReadingDate),
        _storage.remove(PreferenceKeys.lastReadingElapsedTime),
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
      await _storage.write(PreferenceKeys.documentsScanned, newCount);
      _documentsScanned.value = newCount;

      DebugLog.d('Documents scanned incremented to: $newCount', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error incrementing documents scanned: $e', category: LogCategory.service);
    }
  }

  /// Guardar contador específico de documentos escaneados (para sincronización)
  Future<void> saveDocumentsScannedCount(int count) async {
    try {
      await _storage.write(PreferenceKeys.documentsScanned, count);
      _documentsScanned.value = count;

      DebugLog.d('Documents scanned count synchronized to: $count', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving documents scanned count: $e', category: LogCategory.service);
    }
  }

  /// Agregar tiempo de escucha
  Future<void> addListeningTime(int minutes) async {
    try {
      final newTotal = _minutesListened.value + minutes;
      await _storage.write(PreferenceKeys.minutesListened, newTotal);
      _minutesListened.value = newTotal;

      DebugLog.d('Listening time updated: +${minutes}min, total=${newTotal}min', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error adding listening time: $e', category: LogCategory.service);
    }
  }

  /// Actualizar días consecutivos
  Future<void> _updateConsecutiveDays() async {
    try {
      final lastUsageDateString = _storage.read<String>(PreferenceKeys.lastUsageDate);
      final now = DateTime.now();

      if (lastUsageDateString == null) {
        // Primera vez usando la app
        await _storage.write(PreferenceKeys.lastUsageDate, now.toIso8601String());
        await _storage.write(PreferenceKeys.consecutiveDays, 1);
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
        await _storage.write(PreferenceKeys.consecutiveDays, newStreak);
        _consecutiveDays.value = newStreak;
      } else {
        // Se rompió la racha, reiniciar
        await _storage.write(PreferenceKeys.consecutiveDays, 1);
        _consecutiveDays.value = 1;
      }

      // Actualizar fecha de último uso
      await _storage.write(PreferenceKeys.lastUsageDate, now.toIso8601String());

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
    return !_storage.hasData(PreferenceKeys.firstLaunchDate);
  }

  /// Marcar primera apertura de la app
  Future<void> markFirstLaunch() async {
    try {
      if (isFirstLaunch) {
        await _storage.write(PreferenceKeys.firstLaunchDate, DateTime.now().toIso8601String());
        DebugLog.i('First launch marked', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error marking first launch: $e', category: LogCategory.service);
    }
  }

  /// Verificar si hay progreso de lectura pendiente
  bool hasResumeableProgress() {
    final lastDocId = _storage.read<String>(PreferenceKeys.lastDocumentId);
    final position = _storage.read<int>(PreferenceKeys.lastReadingPosition) ?? 0;
    final percentage = _storage.read<double>(PreferenceKeys.lastReadingPercentage) ?? 0.0;

    return lastDocId != null && lastDocId.isNotEmpty && (position > 0 || percentage > 0.05);
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
    return _storage.read<String>(PreferenceKeys.themeMode) ?? 'system';
  }

  /// Guardar tamaño de fuente
  Future<void> saveFontSize(double fontSize) async {
    try {
      await _storage.write(PreferenceKeys.fontSize, fontSize);
      DebugLog.d('Font size saved: $fontSize', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving font size: $e', category: LogCategory.service);
    }
  }

  /// Obtener tamaño de fuente
  double getFontSize() {
    return _storage.read<double>(PreferenceKeys.fontSize) ?? 1.0;
  }

  /// Guardar configuración de TTS
  Future<void> saveTTSSettings({double? speed, String? voice}) async {
    try {
      final futures = <Future>[];

      if (speed != null) {
        futures.add(_storage.write(PreferenceKeys.ttsSpeed, speed));
      }

      if (voice != null) {
        futures.add(_storage.write(PreferenceKeys.ttsVoice, voice));
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
      'speed': _storage.read<double>(PreferenceKeys.ttsSpeed) ?? 0.5,
      'voice': _storage.read<String>(PreferenceKeys.ttsVoice),
    };
  }

  /// Guardar estado premium
  Future<void> savePremiumStatus({required bool isPremium, DateTime? expirationDate, String? licenseType}) async {
    try {
      final futures = <Future>[_storage.write(PreferenceKeys.isPremium, isPremium)];

      if (expirationDate != null) {
        futures.add(_storage.write(PreferenceKeys.premiumExpirationDate, expirationDate.toIso8601String()));
      }

      if (licenseType != null) {
        futures.add(_storage.write(PreferenceKeys.licenseType, licenseType));
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
      final isPremium = _storage.read<bool>(PreferenceKeys.isPremium) ?? false;
      if (!isPremium) return false;

      final expirationString = _storage.read<String>(PreferenceKeys.premiumExpirationDate);
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
        _storage.write(PreferenceKeys.isPremium, true),
        _storage.write(PreferenceKeys.licenseType, 'demo'),
        _storage.write(PreferenceKeys.premiumExpirationDate, expirationDate.toIso8601String()),
        _storage.write(PreferenceKeys.demoActivationDate, DateTime.now().toIso8601String()),
      ]);

      DebugLog.i('Demo mode activated for 7 days', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error activating demo mode: $e', category: LogCategory.service);
    }
  }

  /// Obtener días restantes de demo
  int getDemoRemainingDays() {
    try {
      final licenseType = _storage.read<String>(PreferenceKeys.licenseType);
      if (licenseType != 'demo') return 0;

      final expirationString = _storage.read<String>(PreferenceKeys.premiumExpirationDate);
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
      await _storage.erase();
      await _loadAllPreferences(); // Recargar valores por defecto

      DebugLog.i('All user data cleared', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error clearing all data: $e', category: LogCategory.service);
    }
  }

  /// Exportar todas las preferencias (para backup)
  Map<String, dynamic> exportPreferences() {
    try {
      final allKeys = _storage.getKeys();
      final exportData = <String, dynamic>{};

      for (final key in allKeys) {
        final value = _storage.read(key);
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
          await _storage.write(key, value);
        } else if (value is int) {
          await _storage.write(key, value);
        } else if (value is double) {
          await _storage.write(key, value);
        } else if (value is String) {
          await _storage.write(key, value);
        } else if (value is List<String>) {
          await _storage.write(key, value);
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
  String get savedThemeMode => _storage.read<String>(PreferenceKeys.themeMode) ?? 'system';

  /// Guardar modo de tema
  Future<void> saveThemeMode(String themeMode) async {
    try {
      await _storage.write(PreferenceKeys.themeMode, themeMode);
      DebugLog.d('Theme mode saved: $themeMode', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving theme mode: $e', category: LogCategory.service);
    }
  }

  /// Obtener idioma guardado
  String get savedLanguage => _storage.read<String>(PreferenceKeys.language) ?? 'es_ES';

  /// Guardar idioma
  Future<void> saveLanguage(String language) async {
    try {
      await _storage.write(PreferenceKeys.language, language);
      DebugLog.d('Language saved: $language', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving language: $e', category: LogCategory.service);
    }
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasSeenOnboarding': hasSeenOnboarding,
      'hasSeenOnboardingRaw': _storage.read<bool>(PreferenceKeys.hasSeenOnboarding),
      'hasSeenOnboardingKeyExists': _storage.hasData(PreferenceKeys.hasSeenOnboarding),
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
      'totalPreferences': _storage.getKeys().length,
      'allPreferences': _storage.getKeys().toList(),
      'themeMode': savedThemeMode,
      'language': savedLanguage,
    };
  }
}
