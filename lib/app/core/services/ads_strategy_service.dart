import 'package:get/get.dart';

import 'ads_service.dart';
import 'debug_console_service.dart';

/// Servicio para manejar la estrategia de mostrar anuncios
class AdsStrategyService extends GetxController {
  static AdsStrategyService get to => Get.find();

  // Configuración de frecuencia
  final RxInt _interstitialFrequency = 3.obs; // Cada 3 capítulos
  final RxInt _appOpenMinInterval = 4.obs; // 4 minutos mínimo
  final RxInt _bannerRefreshInterval = 30.obs; // 30 segundos

  // Contadores y estado
  final RxInt _chapterReadCount = 0.obs;
  final RxInt _bookChangeCount = 0.obs;
  final Rx<DateTime> _lastInterstitialTime = Rx<DateTime>(DateTime.now());
  final Rx<DateTime> _lastAppOpenTime = Rx<DateTime>(DateTime.now());

  // Configuración de premium
  final RxBool _disableAdsForPremium = true.obs;
  final RxBool _showAdsInTrial = true.obs;

  // Getters
  int get interstitialFrequency => _interstitialFrequency.value;
  int get appOpenMinInterval => _appOpenMinInterval.value;
  int get bannerRefreshInterval => _bannerRefreshInterval.value;
  int get chapterReadCount => _chapterReadCount.value;
  int get bookChangeCount => _bookChangeCount.value;
  DateTime get lastInterstitialTime => _lastInterstitialTime.value;
  DateTime get lastAppOpenTime => _lastAppOpenTime.value;
  bool get disableAdsForPremium => _disableAdsForPremium.value;
  bool get showAdsInTrial => _showAdsInTrial.value;

  @override
  void onInit() {
    super.onInit();
    _loadStrategyConfig();
  }

  /// Cargar configuración de estrategia
  void _loadStrategyConfig() {
    // En producción, podrías cargar esto desde Firebase Remote Config
    // Por ahora usamos valores por defecto optimizados para apps de lectura

    DebugLog.i('Ads strategy loaded', category: LogCategory.service);
  }

  /// Configurar frecuencia de anuncios intersticiales
  void setInterstitialFrequency(int frequency) {
    _interstitialFrequency.value = frequency;
    DebugLog.d('Interstitial frequency set to: $frequency chapters');
  }

  /// Configurar intervalo mínimo para App Open
  void setAppOpenMinInterval(int minutes) {
    _appOpenMinInterval.value = minutes;
    DebugLog.d('App Open min interval set to: $minutes minutes');
  }

  /// Configurar intervalo de refresh para banners
  void setBannerRefreshInterval(int seconds) {
    _bannerRefreshInterval.value = seconds;
    DebugLog.d('Banner refresh interval set to: $seconds seconds');
  }

  /// Incrementar contador de capítulos leídos
  void incrementChapterCount() {
    _chapterReadCount.value++;
    DebugLog.d('Chapter count: ${_chapterReadCount.value}');
  }

  /// Incrementar contador de cambios de libro
  void incrementBookChangeCount() {
    _bookChangeCount.value++;
    DebugLog.d('Book change count: ${_bookChangeCount.value}');
  }

  /// Verificar si se debe mostrar anuncio intersticial
  bool shouldShowInterstitial() {
    final adsService = Get.find<AdsService>();

    // No mostrar si no hay anuncios habilitados
    if (!adsService.shouldShowAds) {
      return false;
    }

    // Verificar frecuencia de capítulos
    if (_chapterReadCount.value < _interstitialFrequency.value) {
      return false;
    }

    // Verificar intervalo mínimo de tiempo
    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime.value);
    if (timeSinceLastAd.inMinutes < 2) {
      // Mínimo 2 minutos
      return false;
    }

    return true;
  }

  /// Verificar si se debe mostrar anuncio App Open
  bool shouldShowAppOpen() {
    final adsService = Get.find<AdsService>();

    // No mostrar si no hay anuncios habilitados
    if (!adsService.shouldShowAds) {
      return false;
    }

    // Verificar intervalo mínimo de tiempo
    final timeSinceLastAd = DateTime.now().difference(_lastAppOpenTime.value);
    if (timeSinceLastAd.inMinutes < _appOpenMinInterval.value) {
      return false;
    }

    return true;
  }

  /// Mostrar anuncio intersticial al completar capítulo
  Future<bool> showInterstitialOnChapterComplete() async {
    if (!shouldShowInterstitial()) {
      return false;
    }

    final adsService = Get.find<AdsService>();
    final success = await adsService.showInterstitialAd();

    if (success) {
      _lastInterstitialTime.value = DateTime.now();
      _chapterReadCount.value = 0; // Resetear contador
      DebugLog.i('Interstitial shown after chapter completion');
    }

    return success;
  }

  /// Mostrar anuncio intersticial al cambiar de libro
  Future<bool> showInterstitialOnBookChange() async {
    final adsService = Get.find<AdsService>();

    if (!adsService.shouldShowAds) {
      return false;
    }

    final success = await adsService.showInterstitialAd();

    if (success) {
      _lastInterstitialTime.value = DateTime.now();
      DebugLog.i('Interstitial shown on book change');
    }

    return success;
  }

  /// Mostrar anuncio App Open
  Future<bool> showAppOpenAd() async {
    if (!shouldShowAppOpen()) {
      return false;
    }

    final adsService = Get.find<AdsService>();
    final success = await adsService.showAppOpenAd();

    if (success) {
      _lastAppOpenTime.value = DateTime.now();
      DebugLog.i('App Open ad shown');
    }

    return success;
  }

  /// Configurar estrategia para usuarios premium
  void configurePremiumStrategy({bool? disableAds, bool? showInTrial}) {
    if (disableAds != null) {
      _disableAdsForPremium.value = disableAds;
    }
    if (showInTrial != null) {
      _showAdsInTrial.value = showInTrial;
    }

    DebugLog.i('Premium strategy updated: disableAds=$disableAds, showInTrial=$showInTrial');
  }

  /// Obtener configuración optimizada para diferentes tipos de usuario
  Map<String, dynamic> getOptimizedConfig(String userType) {
    switch (userType) {
      case 'new_user':
        return {
          'interstitialFrequency': 2, // Más frecuente para nuevos usuarios
          'appOpenMinInterval': 3,
          'bannerRefreshInterval': 20,
        };
      case 'active_user':
        return {
          'interstitialFrequency': 3, // Frecuencia estándar
          'appOpenMinInterval': 4,
          'bannerRefreshInterval': 30,
        };
      case 'power_user':
        return {
          'interstitialFrequency': 5, // Menos frecuente para usuarios activos
          'appOpenMinInterval': 6,
          'bannerRefreshInterval': 45,
        };
      default:
        return {'interstitialFrequency': 3, 'appOpenMinInterval': 4, 'bannerRefreshInterval': 30};
    }
  }

  /// Aplicar configuración optimizada
  void applyOptimizedConfig(String userType) {
    final config = getOptimizedConfig(userType);

    setInterstitialFrequency(config['interstitialFrequency']);
    setAppOpenMinInterval(config['appOpenMinInterval']);
    setBannerRefreshInterval(config['bannerRefreshInterval']);

    DebugLog.i('Optimized config applied for user type: $userType');
  }

  /// Resetear todos los contadores
  void resetCounters() {
    _chapterReadCount.value = 0;
    _bookChangeCount.value = 0;
    _lastInterstitialTime.value = DateTime.now();
    _lastAppOpenTime.value = DateTime.now();

    DebugLog.i('All counters reset');
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'interstitialFrequency': _interstitialFrequency.value,
      'appOpenMinInterval': _appOpenMinInterval.value,
      'bannerRefreshInterval': _bannerRefreshInterval.value,
      'chapterReadCount': _chapterReadCount.value,
      'bookChangeCount': _bookChangeCount.value,
      'lastInterstitialTime': _lastInterstitialTime.value.toIso8601String(),
      'lastAppOpenTime': _lastAppOpenTime.value.toIso8601String(),
      'shouldShowInterstitial': shouldShowInterstitial(),
      'shouldShowAppOpen': shouldShowAppOpen(),
      'disableAdsForPremium': _disableAdsForPremium.value,
      'showAdsInTrial': _showAdsInTrial.value,
    };
  }
}
