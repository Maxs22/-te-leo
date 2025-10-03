import 'dart:io';

/// Servicio para manejar variables de entorno y claves privadas
class EnvironmentService {
  // Singleton
  static final EnvironmentService _instance = EnvironmentService._internal();
  factory EnvironmentService() => _instance;
  EnvironmentService._internal();

  // Variables de entorno privadas
  static Map<String, String>? _envVars;

  /// Inicializa las variables de entorno
  static Future<void> initialize() async {
    try {
      _envVars = <String, String>{};

      // Cargar variables desde dart-define
      _loadFromDartDefine();

      // Cargar variables desde archivos .env
      await _loadFromEnvFiles();

      // Cargar variables del sistema
      _loadFromSystem();
    } catch (e) {
      print('Error loading environment variables: $e');
    }
  }

  /// Carga variables desde --dart-define
  static void _loadFromDartDefine() {
    // Cargar cada variable individualmente (deben ser constantes en tiempo de compilación)
    _setIfNotEmpty('ENVIRONMENT', const String.fromEnvironment('ENVIRONMENT'));
    _setIfNotEmpty('DEBUG_MODE', const String.fromEnvironment('DEBUG_MODE'));
    _setIfNotEmpty('SHOW_DEBUG_ELEMENTS', const String.fromEnvironment('SHOW_DEBUG_ELEMENTS'));

    // Firebase
    _setIfNotEmpty('FIREBASE_PROJECT_ID', const String.fromEnvironment('FIREBASE_PROJECT_ID'));
    _setIfNotEmpty('FIREBASE_API_KEY', const String.fromEnvironment('FIREBASE_API_KEY'));
    _setIfNotEmpty('FIREBASE_APP_ID', const String.fromEnvironment('FIREBASE_APP_ID'));
    _setIfNotEmpty('FIREBASE_MESSAGING_SENDER_ID', const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'));
    _setIfNotEmpty('FIREBASE_STORAGE_BUCKET', const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'));

    // Google Play
    _setIfNotEmpty('PLAY_STORE_PACKAGE_NAME', const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'));
    _setIfNotEmpty('GOOGLE_ANALYTICS_ID', const String.fromEnvironment('GOOGLE_ANALYTICS_ID'));
    _setIfNotEmpty('GOOGLE_ADS_APP_ID', const String.fromEnvironment('GOOGLE_ADS_APP_ID'));

    // AdMob
    _setIfNotEmpty('ADMOB_BANNER_AD_UNIT_ID', const String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID'));
    _setIfNotEmpty('ADMOB_INTERSTITIAL_AD_UNIT_ID', const String.fromEnvironment('ADMOB_INTERSTITIAL_AD_UNIT_ID'));
    _setIfNotEmpty('ADMOB_REWARDED_AD_UNIT_ID', const String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID'));
    _setIfNotEmpty(
      'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID',
      const String.fromEnvironment('ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID'),
    );
    _setIfNotEmpty('ADMOB_APP_OPEN_AD_UNIT_ID', const String.fromEnvironment('ADMOB_APP_OPEN_AD_UNIT_ID'));
    _setIfNotEmpty('ADMOB_NATIVE_AD_UNIT_ID', const String.fromEnvironment('ADMOB_NATIVE_AD_UNIT_ID'));
    _setIfNotEmpty(
      'ADMOB_ADAPTIVE_BANNER_AD_UNIT_ID',
      const String.fromEnvironment('ADMOB_ADAPTIVE_BANNER_AD_UNIT_ID'),
    );
    _setIfNotEmpty(
      'ADMOB_MEDIUM_RECTANGLE_AD_UNIT_ID',
      const String.fromEnvironment('ADMOB_MEDIUM_RECTANGLE_AD_UNIT_ID'),
    );

    // APIs
    _setIfNotEmpty('API_BASE_URL', const String.fromEnvironment('API_BASE_URL'));
    _setIfNotEmpty('API_KEY', const String.fromEnvironment('API_KEY'));

    // Logging
    _setIfNotEmpty('LOG_LEVEL', const String.fromEnvironment('LOG_LEVEL'));
    _setIfNotEmpty('ANALYTICS_ENABLED', const String.fromEnvironment('ANALYTICS_ENABLED'));
    _setIfNotEmpty('CRASH_REPORTING_ENABLED', const String.fromEnvironment('CRASH_REPORTING_ENABLED'));

    // Valores por defecto críticos si no vienen de --dart-define
    _envVars!['ENVIRONMENT'] ??= 'development';
    _envVars!['DEBUG_MODE'] ??= 'true';
    _envVars!['SHOW_DEBUG_ELEMENTS'] ??= 'true';
  }

  /// Helper para setear variable solo si no está vacía
  static void _setIfNotEmpty(String key, String value) {
    if (value.isNotEmpty) {
      _envVars![key] = value;
    }
  }

  /// Carga variables desde archivos .env
  static Future<void> _loadFromEnvFiles() async {
    try {
      // Determinar qué archivo .env usar
      final environment = _envVars!['ENVIRONMENT'] ?? 'development';
      String envFile = '.env.$environment';

      // Verificar si existe el archivo específico del entorno
      final envFileSpecific = File(envFile);
      if (!envFileSpecific.existsSync()) {
        // Fallback al archivo .env base
        envFile = '.env';
        final envFileBase = File(envFile);
        if (!envFileBase.existsSync()) {
          // En release mode es normal que no existan los archivos .env
          // Las variables vienen de --dart-define
          if (environment != 'development') {
            // Silencioso en producción
            return;
          }
          print('⚠️ No .env file found for environment: $environment (usando --dart-define o valores por defecto)');
          return;
        }
      }

      // Leer el archivo .env
      final content = await File(envFile).readAsString();
      final lines = content.split('\n');

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

        final equalIndex = trimmedLine.indexOf('=');
        if (equalIndex == -1) continue;

        final key = trimmedLine.substring(0, equalIndex).trim();
        final value = trimmedLine.substring(equalIndex + 1).trim();

        // Remover comillas si las hay
        String cleanValue = value;
        if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
          cleanValue = cleanValue.substring(1, cleanValue.length - 1);
        } else if (cleanValue.startsWith("'") && cleanValue.endsWith("'")) {
          cleanValue = cleanValue.substring(1, cleanValue.length - 1);
        }
        _envVars![key] = cleanValue;
      }

      print('Loaded environment variables from: $envFile');
    } catch (e) {
      print('Error loading .env file: $e');
    }
  }

  /// Carga variables del sistema operativo
  static void _loadFromSystem() {
    try {
      final env = Platform.environment;
      for (final entry in env.entries) {
        // Solo agregar si no existe ya
        if (!_envVars!.containsKey(entry.key)) {
          _envVars![entry.key] = entry.value;
        }
      }
    } catch (e) {
      print('Error loading system environment: $e');
    }
  }

  /// Obtiene una variable de entorno
  static String? get(String key) {
    return _envVars?[key];
  }

  /// Obtiene una variable de entorno con valor por defecto
  static String getOrDefault(String key, String defaultValue) {
    return _envVars?[key] ?? defaultValue;
  }

  /// Obtiene una variable de entorno como booleano
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = _envVars?[key]?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Obtiene una variable de entorno como entero
  static int getInt(String key, {int defaultValue = 0}) {
    final value = _envVars?[key];
    return int.tryParse(value ?? '') ?? defaultValue;
  }

  /// Verifica si una variable existe
  static bool has(String key) {
    return _envVars?.containsKey(key) ?? false;
  }

  /// Obtiene todas las variables (solo para debug)
  static Map<String, String> getAll() {
    return Map.from(_envVars ?? {});
  }

  /// Obtiene variables sensibles (solo para debug, con valores ocultos)
  static Map<String, String> getSensitiveVars() {
    final sensitiveKeys = [
      'API_KEY',
      'SECRET_KEY',
      'PRIVATE_KEY',
      'PASSWORD',
      'TOKEN',
      'CREDENTIAL',
      'CLIENT_SECRET',
      'PLAY_STORE_KEY',
      'FIREBASE_KEY',
      'GOOGLE_SERVICES_KEY',
    ];

    final result = <String, String>{};
    for (final key in sensitiveKeys) {
      if (_envVars?.containsKey(key) == true) {
        final value = _envVars![key]!;
        // Ocultar la mayoría del valor, mostrar solo los primeros y últimos caracteres
        if (value.length > 8) {
          result[key] = '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
        } else {
          result[key] = '***';
        }
      }
    }
    return result;
  }

  /// Imprime información de configuración (solo en desarrollo)
  static void printConfig() {
    final environment = getOrDefault('ENVIRONMENT', 'development');
    if (environment == 'development') {
      print('=== ENVIRONMENT CONFIG ===');
      print('Environment: $environment');
      print('Debug Mode: ${getBool('DEBUG_MODE')}');
      print('Show Debug Elements: ${getBool('SHOW_DEBUG_ELEMENTS')}');

      final sensitiveVars = getSensitiveVars();
      if (sensitiveVars.isNotEmpty) {
        print('Sensitive Variables:');
        sensitiveVars.forEach((key, value) {
          print('  $key: $value');
        });
      }

      print('========================');
    }
  }
}
