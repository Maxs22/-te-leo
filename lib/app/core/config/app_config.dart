import 'package:flutter/foundation.dart';

/// Configuración de la aplicación para diferentes entornos
class AppConfig {
  static const String _appName = 'Te Leo';
  static const String _packageName = 'com.teleo.app';
  
  /// Nombre de la aplicación
  static String get appName => _appName;
  
  /// Nombre del paquete
  static String get packageName => _packageName;
  
  /// Determina si estamos en modo desarrollo
  static bool get isDevelopment => kDebugMode;
  
  /// Determina si estamos en modo producción
  static bool get isProduction => kReleaseMode;
  
  /// Versión de la API (para futuras integraciones)
  static String get apiVersion => 'v1';
  
  /// URL base para la API (para futuras funciones online)
  static String get baseUrl => isDevelopment 
    ? 'https://api-dev.teleo.com'
    : 'https://api.teleo.com';
}

/// Configuración específica de AdMob
class AdMobConfig {
  // ⚠️ IMPORTANTE: Reemplazar con IDs reales antes de publicar
  
  /// Application ID de AdMob
  static String get applicationId {
    if (AppConfig.isDevelopment) {
      // IDs de prueba
      return 'ca-app-pub-3940256099942544~3347511713'; // Android test
    } else {
      // IDs de producción - REEMPLAZAR ANTES DE PUBLICAR
      return 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
    }
  }
  
  /// Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (AppConfig.isDevelopment) {
      // IDs de prueba
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test
    } else {
      // IDs de producción - REEMPLAZAR ANTES DE PUBLICAR
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
  }
  
  /// Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (AppConfig.isDevelopment) {
      // IDs de prueba
      return 'ca-app-pub-3940256099942544/1033173712'; // Android test
    } else {
      // IDs de producción - REEMPLAZAR ANTES DE PUBLICAR
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
  }
  
  /// Rewarded Ad Unit ID (para futuras funciones)
  static String get rewardedAdUnitId {
    if (AppConfig.isDevelopment) {
      // IDs de prueba
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test
    } else {
      // IDs de producción - REEMPLAZAR ANTES DE PUBLICAR
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
  }
}

/// Configuración de In-App Purchases
class PurchaseConfig {
  /// Product ID para suscripción mensual
  static String get monthlyProductId {
    if (AppConfig.isDevelopment) {
      return 'te_leo_premium_monthly_test';
    } else {
      return 'te_leo_premium_monthly';
    }
  }
  
  /// Product ID para suscripción anual
  static String get yearlyProductId {
    if (AppConfig.isDevelopment) {
      return 'te_leo_premium_yearly_test';
    } else {
      return 'te_leo_premium_yearly';
    }
  }
  
  /// Precios (solo para mostrar, los reales vienen de las tiendas)
  static const Map<String, double> prices = {
    'monthly': 4.99,
    'yearly': 24.99,
  };
  
  /// Días de prueba gratuita
  static const int freeTrialDays = 7;
}

/// Configuración de límites para usuarios gratuitos
class LimitsConfig {
  /// Máximo de documentos por mes para usuarios gratuitos
  static const int maxDocumentsPerMonth = 5;
  
  /// Días del período de reseteo
  static const int resetPeriodDays = 30;
  
  /// Frecuencia de anuncios intersticiales (cada X documentos)
  static const int interstitialAdFrequency = 3;
  
  /// Tiempo mínimo entre anuncios intersticiales (segundos)
  static const int minInterstitialInterval = 120; // 2 minutos
}

/// Configuración de analytics y tracking
class AnalyticsConfig {
  /// Firebase Analytics habilitado
  static bool get analyticsEnabled => AppConfig.isProduction;
  
  /// Crashlytics habilitado
  static bool get crashlyticsEnabled => AppConfig.isProduction;
  
  /// Logging detallado (solo en desarrollo)
  static bool get verboseLogging => AppConfig.isDevelopment;
  
  /// Enviar métricas de uso
  static bool get usageMetricsEnabled => AppConfig.isProduction;
}

/// Configuración de funciones experimentales
class FeatureFlags {
  /// Habilitar funciones de traducción (movidas a rama separada)
  static const bool translationEnabled = false;
  
  /// Habilitar navegación por voz (removida)
  static const bool voiceNavigationEnabled = false;
  
  /// Habilitar vibración (removida)
  static const bool vibrationEnabled = false;
  
  /// Habilitar estadísticas avanzadas (removidas)
  static const bool advancedStatsEnabled = false;
  
  /// Habilitar funciones de accesibilidad extendidas
  static const bool extendedAccessibilityEnabled = true;
  
  /// Habilitar modo offline avanzado
  static const bool advancedOfflineModeEnabled = true;
  
  /// Habilitar sincronización en la nube (futura función)
  static const bool cloudSyncEnabled = false;
  
  /// Habilitar compartir documentos (futura función)
  static const bool documentSharingEnabled = false;
}

/// URLs importantes
class AppUrls {
  /// Política de privacidad
  static const String privacyPolicy = 'https://teleo.com/privacy';
  
  /// Términos de servicio
  static const String termsOfService = 'https://teleo.com/terms';
  
  /// Soporte técnico
  static const String support = 'https://teleo.com/support';
  
  /// Sitio web principal
  static const String website = 'https://teleo.com';
  
  /// Repositorio de GitHub
  static const String githubRepo = 'https://github.com/Maxs22/-te-leo';
  
  /// Contacto por email
  static const String contactEmail = 'support@teleo.com';
}
