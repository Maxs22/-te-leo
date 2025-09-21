import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'debug_console_service.dart';
import 'subscription_service.dart';
import '../config/app_config.dart';

/// Estados de anuncios
enum AdState {
  loading,
  loaded,
  failed,
  showing,
  closed,
  clicked,
}

/// Servicio de gestión de anuncios para versión gratuita
class AdsService extends GetxController {
  static AdsService get to => Get.find();

  // Estado reactivo
  final Rx<AdState> _bannerState = AdState.loading.obs;
  final Rx<AdState> _interstitialState = AdState.loading.obs;
  final RxBool _adsEnabled = true.obs;

  // Anuncios
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  // IDs de anuncios (configurados centralmente)
  static String get _bannerAdUnitId => AdMobConfig.bannerAdUnitId;
  static String get _interstitialAdUnitId => AdMobConfig.interstitialAdUnitId;

  // Getters
  AdState get bannerState => _bannerState.value;
  AdState get interstitialState => _interstitialState.value;
  bool get adsEnabled => _adsEnabled.value;
  bool get shouldShowAds => _adsEnabled.value && !_isPremiumUser();
  BannerAd? get bannerAd => _bannerAd;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeAds();
  }

  @override
  void onClose() {
    _disposeBannerAd();
    _disposeInterstitialAd();
    super.onClose();
  }

  /// Inicializar el sistema de anuncios
  Future<void> _initializeAds() async {
    try {
      // Solo inicializar si no es premium
      if (_isPremiumUser()) {
        _adsEnabled.value = false;
        DebugLog.i('User is premium - ads disabled', category: LogCategory.service);
        return;
      }

      // Inicializar SDK de anuncios
      await MobileAds.instance.initialize();
      
      // Configurar opciones de anuncios
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: kDebugMode ? ['YOUR_TEST_DEVICE_ID'] : [],
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        ),
      );

      _adsEnabled.value = true;
      
      // Cargar anuncios iniciales
      await _loadBannerAd();
      await _loadInterstitialAd();

      DebugLog.i('AdsService initialized successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing ads: $e', category: LogCategory.service);
      _adsEnabled.value = false;
    }
  }

  /// Cargar anuncio banner
  Future<void> _loadBannerAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeBannerAd();
      _bannerState.value = AdState.loading;

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _bannerState.value = AdState.loaded;
            DebugLog.d('Banner ad loaded', category: LogCategory.service);
          },
          onAdFailedToLoad: (ad, error) {
            _bannerState.value = AdState.failed;
            DebugLog.w('Banner ad failed to load: $error', category: LogCategory.service);
            ad.dispose();
            _bannerAd = null;
          },
          onAdClicked: (ad) {
            _bannerState.value = AdState.clicked;
            DebugLog.d('Banner ad clicked', category: LogCategory.service);
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      DebugLog.e('Error loading banner ad: $e', category: LogCategory.service);
      _bannerState.value = AdState.failed;
    }
  }

  /// Cargar anuncio intersticial
  Future<void> _loadInterstitialAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeInterstitialAd();
      _interstitialState.value = AdState.loading;

      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialState.value = AdState.loaded;
            DebugLog.d('Interstitial ad loaded', category: LogCategory.service);
            
            _setupInterstitialCallbacks();
          },
          onAdFailedToLoad: (error) {
            _interstitialState.value = AdState.failed;
            DebugLog.w('Interstitial ad failed to load: $error', category: LogCategory.service);
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      DebugLog.e('Error loading interstitial ad: $e', category: LogCategory.service);
      _interstitialState.value = AdState.failed;
    }
  }

  /// Configurar callbacks del anuncio intersticial
  void _setupInterstitialCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _interstitialState.value = AdState.showing;
        DebugLog.d('Interstitial ad showing', category: LogCategory.service);
      },
      onAdDismissedFullScreenContent: (ad) {
        _interstitialState.value = AdState.closed;
        DebugLog.d('Interstitial ad closed', category: LogCategory.service);
        ad.dispose();
        _interstitialAd = null;
        // Cargar el siguiente anuncio
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _interstitialState.value = AdState.failed;
        DebugLog.w('Interstitial ad failed to show: $error', category: LogCategory.service);
        ad.dispose();
        _interstitialAd = null;
      },
      onAdClicked: (ad) {
        _interstitialState.value = AdState.clicked;
        DebugLog.d('Interstitial ad clicked', category: LogCategory.service);
      },
    );
  }

  /// Mostrar anuncio intersticial
  Future<bool> showInterstitialAd() async {
    if (!shouldShowAds || _interstitialAd == null) {
      DebugLog.d('Cannot show interstitial ad - shouldShowAds: $shouldShowAds, ad: ${_interstitialAd != null}', 
                 category: LogCategory.service);
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      DebugLog.e('Error showing interstitial ad: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Verificar si el usuario es premium
  bool _isPremiumUser() {
    try {
      final subscriptionService = Get.find<SubscriptionService>();
      return subscriptionService.isActive;
    } catch (e) {
      return false;
    }
  }

  /// Disponer del anuncio banner
  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// Disponer del anuncio intersticial
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// Deshabilitar anuncios (cuando el usuario compra premium)
  void disableAds() {
    _adsEnabled.value = false;
    _disposeBannerAd();
    _disposeInterstitialAd();
    DebugLog.i('Ads disabled - user is now premium', category: LogCategory.service);
  }

  /// Habilitar anuncios (cuando la suscripción expira)
  Future<void> enableAds() async {
    if (_isPremiumUser()) return;
    
    _adsEnabled.value = true;
    await _loadBannerAd();
    await _loadInterstitialAd();
    DebugLog.i('Ads enabled - user subscription expired', category: LogCategory.service);
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'adsEnabled': _adsEnabled.value,
      'shouldShowAds': shouldShowAds,
      'bannerState': _bannerState.value.toString(),
      'interstitialState': _interstitialState.value.toString(),
      'bannerLoaded': _bannerAd != null,
      'interstitialLoaded': _interstitialAd != null,
      'isPremium': _isPremiumUser(),
    };
  }
}
