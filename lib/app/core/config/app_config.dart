import 'package:flutter/foundation.dart';

import '../services/environment_service.dart';

/// Configuración de la aplicación
class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Flag para determinar si estamos en modo desarrollo
  /// Se puede sobrescribir con --dart-define=DEBUG_MODE=false
  static bool get isDevelopment {
    return EnvironmentService.getBool('DEBUG_MODE', defaultValue: kDebugMode);
  }

  /// Flag para determinar si estamos en modo producción
  static bool get isProduction => !isDevelopment;

  /// Flag para mostrar elementos de debug en la UI
  /// Se puede sobrescribir con --dart-define=SHOW_DEBUG_ELEMENTS=false
  static bool get showDebugElements {
    return EnvironmentService.getBool('SHOW_DEBUG_ELEMENTS', defaultValue: isDevelopment);
  }

  /// Flag para mostrar logs detallados
  static bool get showDetailedLogs => isDevelopment;

  /// Flag para mostrar información de debug en la consola
  static bool get showDebugInfo => isDevelopment;

  /// Flag para habilitar herramientas de desarrollo
  static bool get enableDevTools => isDevelopment;

  /// Flag para mostrar botones de debug en la UI
  static bool get showDebugButtons => showDebugElements;

  /// Flag para mostrar información de estado de servicios
  static bool get showServiceStatus => showDebugElements;

  /// Flag para habilitar funciones experimentales
  static bool get enableExperimentalFeatures => isDevelopment;

  /// Obtener el entorno actual
  static String get environment {
    return EnvironmentService.getOrDefault('ENVIRONMENT', 'development');
  }

  /// Información de la versión de la aplicación
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  /// Obtener claves de Firebase
  static String get firebaseProjectId => EnvironmentService.getOrDefault('FIREBASE_PROJECT_ID', '');
  static String get firebaseApiKey => EnvironmentService.getOrDefault('FIREBASE_API_KEY', '');
  static String get firebaseAppId => EnvironmentService.getOrDefault('FIREBASE_APP_ID', '');
  static String get firebaseMessagingSenderId => EnvironmentService.getOrDefault('FIREBASE_MESSAGING_SENDER_ID', '');
  static String get firebaseStorageBucket => EnvironmentService.getOrDefault('FIREBASE_STORAGE_BUCKET', '');

  /// Obtener claves de Google Play Store
  static String get playStorePackageName => EnvironmentService.getOrDefault('PLAY_STORE_PACKAGE_NAME', '');
  static String get playStoreServiceAccountKey => EnvironmentService.getOrDefault('PLAY_STORE_SERVICE_ACCOUNT_KEY', '');
  static String get playStoreTrack => EnvironmentService.getOrDefault('PLAY_STORE_TRACK', 'internal');

  /// Obtener configuración de APIs
  static String get apiBaseUrl => EnvironmentService.getOrDefault('API_BASE_URL', '');
  static String get apiKey => EnvironmentService.getOrDefault('API_KEY', '');
  static String get apiSecret => EnvironmentService.getOrDefault('API_SECRET', '');

  /// Obtener configuración de Google Analytics
  static String get googleAnalyticsId => EnvironmentService.getOrDefault('GOOGLE_ANALYTICS_ID', '');
  static String get googleAdsAppId => EnvironmentService.getOrDefault('GOOGLE_ADS_APP_ID', '');
  static String get googleAdsTestDeviceId => EnvironmentService.getOrDefault('GOOGLE_ADS_TEST_DEVICE_ID', '');

  /// Obtener configuración específica de AdMob
  /// Los IDs se pasan via --dart-define o se obtienen de .env
  static String get adMobBannerAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_BANNER_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/6300978111', // Test ID como fallback
    );
  }

  static String get adMobInterstitialAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_INTERSTITIAL_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/1033173712', // Test ID como fallback
    );
  }

  static String get adMobRewardedAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_REWARDED_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/5224354917', // Test ID como fallback
    );
  }

  static String get adMobRewardedInterstitialAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/5354046379', // Test ID como fallback
    );
  }

  static String get adMobAppOpenAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_APP_OPEN_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/3419835294', // Test ID como fallback
    );
  }

  static String get adMobNativeAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_NATIVE_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/2247696110', // Test ID como fallback
    );
  }

  static String get adMobAdaptiveBannerAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_ADAPTIVE_BANNER_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/9214589741', // Test ID como fallback
    );
  }

  static String get adMobMediumRectangleAdUnitId {
    return EnvironmentService.getOrDefault(
      'ADMOB_MEDIUM_RECTANGLE_AD_UNIT_ID',
      'ca-app-pub-3940256099942544/6300978111', // Test ID como fallback
    );
  }

  /// Obtener configuración de base de datos
  static String get databaseUrl => EnvironmentService.getOrDefault('DATABASE_URL', '');
  static String get databaseEncryptionKey => EnvironmentService.getOrDefault('DATABASE_ENCRYPTION_KEY', '');

  /// Obtener configuración de notificaciones
  static String get fcmServerKey => EnvironmentService.getOrDefault('FCM_SERVER_KEY', '');
  static String get notificationChannelId => EnvironmentService.getOrDefault('NOTIFICATION_CHANNEL_ID', '');

  /// Obtener configuración de ML Kit
  static String get mlKitApiKey => EnvironmentService.getOrDefault('ML_KIT_API_KEY', '');
  static String get ocrServiceUrl => EnvironmentService.getOrDefault('OCR_SERVICE_URL', '');

  /// Obtener configuración de logging
  static String get logLevel => EnvironmentService.getOrDefault('LOG_LEVEL', 'debug');
  static bool get analyticsEnabled => EnvironmentService.getBool('ANALYTICS_ENABLED', defaultValue: true);
  static bool get crashReportingEnabled => EnvironmentService.getBool('CRASH_REPORTING_ENABLED', defaultValue: true);

  /// Información completa de la configuración
  static Map<String, dynamic> get configInfo => {
    'isDevelopment': isDevelopment,
    'isProduction': isProduction,
    'showDebugElements': showDebugElements,
    'showDetailedLogs': showDetailedLogs,
    'showDebugInfo': showDebugInfo,
    'enableDevTools': enableDevTools,
    'showDebugButtons': showDebugButtons,
    'showServiceStatus': showServiceStatus,
    'enableExperimentalFeatures': enableExperimentalFeatures,
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'environment': environment,
    'firebaseProjectId': firebaseProjectId.isNotEmpty ? '${firebaseProjectId.substring(0, 8)}...' : 'Not set',
    'playStorePackageName': playStorePackageName,
    'apiBaseUrl': apiBaseUrl,
    'logLevel': logLevel,
    'analyticsEnabled': analyticsEnabled,
    'crashReportingEnabled': crashReportingEnabled,
  };

  /// Método para imprimir información de configuración (solo en desarrollo)
  static void printConfigInfo() {
    if (isDevelopment) {
      print('=== APP CONFIG ===');
      configInfo.forEach((key, value) {
        print('$key: $value');
      });
      print('==================');

      // También imprimir información del EnvironmentService
      EnvironmentService.printConfig();
    }
  }
}
