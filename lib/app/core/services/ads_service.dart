import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import 'debug_console_service.dart';
import 'subscription_service.dart';

/// Estados de anuncios
enum AdState { loading, loaded, failed, showing, closed, clicked }

/// Tipos de anuncios disponibles
enum AdType { banner, interstitial, rewarded, rewardedInterstitial, appOpen, native, adaptiveBanner, mediumRectangle }

/// Servicio de gestión de anuncios para versión gratuita
class AdsService extends GetxController {
  static AdsService get to => Get.find();

  // Estado reactivo
  final Rx<AdState> _bannerState = AdState.loading.obs;
  final Rx<AdState> _interstitialState = AdState.loading.obs;
  final Rx<AdState> _rewardedState = AdState.loading.obs;
  final Rx<AdState> _rewardedInterstitialState = AdState.loading.obs;
  final Rx<AdState> _appOpenState = AdState.loading.obs;
  final Rx<AdState> _nativeState = AdState.loading.obs;
  final Rx<AdState> _adaptiveBannerState = AdState.loading.obs;
  final Rx<AdState> _mediumRectangleState = AdState.loading.obs;
  final RxBool _adsEnabled = true.obs;

  // Manejo de errores
  final RxInt _consecutiveFailures = 0.obs;
  final Rx<DateTime?> _lastFailureTime = Rx<DateTime?>(null);
  final RxBool _isRetrying = false.obs;

  // Anuncios
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  AppOpenAd? _appOpenAd;
  NativeAd? _nativeAd;
  BannerAd? _adaptiveBannerAd;
  BannerAd? _mediumRectangleAd;

  // IDs de anuncios (configurados centralmente)
  static String get _bannerAdUnitId => AppConfig.adMobBannerAdUnitId.isNotEmpty
      ? AppConfig.adMobBannerAdUnitId
      : 'ca-app-pub-3940256099942544/6300978111'; // Test ID

  static String get _interstitialAdUnitId => AppConfig.adMobInterstitialAdUnitId.isNotEmpty
      ? AppConfig.adMobInterstitialAdUnitId
      : 'ca-app-pub-3940256099942544/1033173712'; // Test ID

  static String get _rewardedAdUnitId => AppConfig.adMobRewardedAdUnitId.isNotEmpty
      ? AppConfig.adMobRewardedAdUnitId
      : 'ca-app-pub-3940256099942544/5224354917'; // Test ID

  static String get _rewardedInterstitialAdUnitId => AppConfig.adMobRewardedInterstitialAdUnitId.isNotEmpty
      ? AppConfig.adMobRewardedInterstitialAdUnitId
      : 'ca-app-pub-3940256099942544/5354046379'; // Test ID

  static String get _appOpenAdUnitId => AppConfig.adMobAppOpenAdUnitId.isNotEmpty
      ? AppConfig.adMobAppOpenAdUnitId
      : 'ca-app-pub-3940256099942544/3419835294'; // Test ID

  static String get _nativeAdUnitId => AppConfig.adMobNativeAdUnitId.isNotEmpty
      ? AppConfig.adMobNativeAdUnitId
      : 'ca-app-pub-3940256099942544/2247696110'; // Test ID

  static String get _adaptiveBannerAdUnitId => AppConfig.adMobAdaptiveBannerAdUnitId.isNotEmpty
      ? AppConfig.adMobAdaptiveBannerAdUnitId
      : 'ca-app-pub-3940256099942544/9214589741'; // Test ID

  static String get _mediumRectangleAdUnitId => AppConfig.adMobMediumRectangleAdUnitId.isNotEmpty
      ? AppConfig.adMobMediumRectangleAdUnitId
      : 'ca-app-pub-3940256099942544/6300978111'; // Test ID

  // Getters
  AdState get bannerState => _bannerState.value;
  AdState get interstitialState => _interstitialState.value;
  AdState get rewardedState => _rewardedState.value;
  AdState get rewardedInterstitialState => _rewardedInterstitialState.value;
  AdState get appOpenState => _appOpenState.value;
  AdState get nativeState => _nativeState.value;
  AdState get adaptiveBannerState => _adaptiveBannerState.value;
  AdState get mediumRectangleState => _mediumRectangleState.value;
  bool get adsEnabled => _adsEnabled.value;

  // Cached premium status para evitar ciclos de Obx
  bool _cachedIsPremium = false;
  bool get shouldShowAds => _adsEnabled.value && !_cachedIsPremium;

  // Getters para manejo de errores
  int get consecutiveFailures => _consecutiveFailures.value;
  DateTime? get lastFailureTime => _lastFailureTime.value;
  bool get isRetrying => _isRetrying.value;

  // Getter para debug info (de AppConfig)
  bool get showDebugInfo => AppConfig.showDebugInfo;

  // Getters para acceso a anuncios
  BannerAd? get bannerAd => _bannerAd;
  InterstitialAd? get interstitialAd => _interstitialAd;
  RewardedAd? get rewardedAd => _rewardedAd;
  RewardedInterstitialAd? get rewardedInterstitialAd => _rewardedInterstitialAd;
  AppOpenAd? get appOpenAd => _appOpenAd;
  NativeAd? get nativeAd => _nativeAd;
  BannerAd? get adaptiveBannerAd => _adaptiveBannerAd;
  BannerAd? get mediumRectangleAd => _mediumRectangleAd;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Actualizar estado premium cacheado
    _updatePremiumStatus();
    // Escuchar cambios en el estado premium
    _listenToPremiumChanges();
    await _initializeAds();
  }

  /// Actualizar estado premium cacheado
  void _updatePremiumStatus() {
    _cachedIsPremium = _isPremiumUser();
  }

  /// Escuchar cambios en el estado premium
  void _listenToPremiumChanges() {
    // Actualizar periódicamente el estado premium
    // Evitamos usar ever() para prevenir ciclos de Obx
    Future.delayed(const Duration(seconds: 1), () {
      _checkAndUpdatePremiumStatus();
    });
  }

  /// Verificar y actualizar estado premium periódicamente
  void _checkAndUpdatePremiumStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wasPremium = _cachedIsPremium;
      _updatePremiumStatus();
      
      // Si cambió de premium a gratuito, habilitar anuncios
      if (wasPremium && !_cachedIsPremium) {
        enableAds();
      }
      // Si cambió de gratuito a premium, deshabilitar anuncios
      else if (!wasPremium && _cachedIsPremium) {
        disableAds();
      }
      
      // Verificar de nuevo en 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        _checkAndUpdatePremiumStatus();
      });
    });
  }

  @override
  void onClose() {
    _disposeBannerAd();
    _disposeInterstitialAd();
    _disposeRewardedAd();
    _disposeRewardedInterstitialAd();
    _disposeAppOpenAd();
    _disposeNativeAd();
    _disposeAdaptiveBannerAd();
    _disposeMediumRectangleAd();
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
      await _loadRewardedAd();
      await _loadRewardedInterstitialAd();
      await _loadAppOpenAd();
      await _loadNativeAd();
      await _loadAdaptiveBannerAd();
      await _loadMediumRectangleAd();

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
            _handleAdLoadSuccess();
            DebugLog.d('Banner ad loaded', category: LogCategory.service);
          },
          onAdFailedToLoad: (ad, error) {
            _bannerState.value = AdState.failed;
            _handleAdLoadError(AdType.banner, error.toString());
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
            _handleAdLoadSuccess();
            DebugLog.d('Interstitial ad loaded', category: LogCategory.service);

            _setupInterstitialCallbacks();
          },
          onAdFailedToLoad: (error) {
            _interstitialState.value = AdState.failed;
            _handleAdLoadError(AdType.interstitial, error.toString());
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      DebugLog.e('Error loading interstitial ad: $e', category: LogCategory.service);
      _interstitialState.value = AdState.failed;
    }
  }

  /// Cargar anuncio rewarded
  Future<void> _loadRewardedAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeRewardedAd();
      _rewardedState.value = AdState.loading;

      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedState.value = AdState.loaded;
            DebugLog.d('Rewarded ad loaded', category: LogCategory.service);
            _setupRewardedCallbacks();
          },
          onAdFailedToLoad: (error) {
            _rewardedState.value = AdState.failed;
            DebugLog.w('Rewarded ad failed to load: $error', category: LogCategory.service);
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      DebugLog.e('Error loading rewarded ad: $e', category: LogCategory.service);
      _rewardedState.value = AdState.failed;
    }
  }

  /// Cargar anuncio rewarded intersticial
  Future<void> _loadRewardedInterstitialAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeRewardedInterstitialAd();
      _rewardedInterstitialState.value = AdState.loading;

      await RewardedInterstitialAd.load(
        adUnitId: _rewardedInterstitialAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedInterstitialAd = ad;
            _rewardedInterstitialState.value = AdState.loaded;
            DebugLog.d('Rewarded interstitial ad loaded', category: LogCategory.service);
            _setupRewardedInterstitialCallbacks();
          },
          onAdFailedToLoad: (error) {
            _rewardedInterstitialState.value = AdState.failed;
            DebugLog.w('Rewarded interstitial ad failed to load: $error', category: LogCategory.service);
            _rewardedInterstitialAd = null;
          },
        ),
      );
    } catch (e) {
      DebugLog.e('Error loading rewarded interstitial ad: $e', category: LogCategory.service);
      _rewardedInterstitialState.value = AdState.failed;
    }
  }

  /// Cargar anuncio app open
  Future<void> _loadAppOpenAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeAppOpenAd();
      _appOpenState.value = AdState.loading;

      await AppOpenAd.load(
        adUnitId: _appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _appOpenState.value = AdState.loaded;
            DebugLog.d('App open ad loaded', category: LogCategory.service);
            _setupAppOpenCallbacks();
          },
          onAdFailedToLoad: (error) {
            _appOpenState.value = AdState.failed;
            DebugLog.w('App open ad failed to load: $error', category: LogCategory.service);
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      DebugLog.e('Error loading app open ad: $e', category: LogCategory.service);
      _appOpenState.value = AdState.failed;
    }
  }

  /// Cargar anuncio nativo
  Future<void> _loadNativeAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeNativeAd();
      _nativeState.value = AdState.loading;

      _nativeAd = NativeAd(
        adUnitId: _nativeAdUnitId,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.white,
          cornerRadius: 12.0,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _nativeState.value = AdState.loaded;
            DebugLog.d('Native ad loaded', category: LogCategory.service);
          },
          onAdFailedToLoad: (ad, error) {
            _nativeState.value = AdState.failed;
            DebugLog.w('Native ad failed to load: $error', category: LogCategory.service);
            ad.dispose();
            _nativeAd = null;
          },
          onAdClicked: (ad) {
            _nativeState.value = AdState.clicked;
            DebugLog.d('Native ad clicked', category: LogCategory.service);
          },
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      DebugLog.e('Error loading native ad: $e', category: LogCategory.service);
      _nativeState.value = AdState.failed;
    }
  }

  /// Cargar anuncio adaptive banner
  Future<void> _loadAdaptiveBannerAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeAdaptiveBannerAd();
      _adaptiveBannerState.value = AdState.loading;

      _adaptiveBannerAd = BannerAd(
        adUnitId: _adaptiveBannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _adaptiveBannerState.value = AdState.loaded;
            DebugLog.d('Adaptive banner ad loaded', category: LogCategory.service);
          },
          onAdFailedToLoad: (ad, error) {
            _adaptiveBannerState.value = AdState.failed;
            DebugLog.w('Adaptive banner ad failed to load: $error', category: LogCategory.service);
            ad.dispose();
            _adaptiveBannerAd = null;
          },
          onAdClicked: (ad) {
            _adaptiveBannerState.value = AdState.clicked;
            DebugLog.d('Adaptive banner ad clicked', category: LogCategory.service);
          },
        ),
      );

      await _adaptiveBannerAd!.load();
    } catch (e) {
      DebugLog.e('Error loading adaptive banner ad: $e', category: LogCategory.service);
      _adaptiveBannerState.value = AdState.failed;
    }
  }

  /// Cargar anuncio medium rectangle
  Future<void> _loadMediumRectangleAd() async {
    if (!shouldShowAds) return;

    try {
      _disposeMediumRectangleAd();
      _mediumRectangleState.value = AdState.loading;

      _mediumRectangleAd = BannerAd(
        adUnitId: _mediumRectangleAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _mediumRectangleState.value = AdState.loaded;
            DebugLog.d('Medium rectangle ad loaded', category: LogCategory.service);
          },
          onAdFailedToLoad: (ad, error) {
            _mediumRectangleState.value = AdState.failed;
            DebugLog.w('Medium rectangle ad failed to load: $error', category: LogCategory.service);
            ad.dispose();
            _mediumRectangleAd = null;
          },
          onAdClicked: (ad) {
            _mediumRectangleState.value = AdState.clicked;
            DebugLog.d('Medium rectangle ad clicked', category: LogCategory.service);
          },
        ),
      );

      await _mediumRectangleAd!.load();
    } catch (e) {
      DebugLog.e('Error loading medium rectangle ad: $e', category: LogCategory.service);
      _mediumRectangleState.value = AdState.failed;
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

  /// Configurar callbacks del anuncio rewarded
  void _setupRewardedCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _rewardedState.value = AdState.showing;
        DebugLog.d('Rewarded ad showing', category: LogCategory.service);
      },
      onAdDismissedFullScreenContent: (ad) {
        _rewardedState.value = AdState.closed;
        DebugLog.d('Rewarded ad closed', category: LogCategory.service);
        ad.dispose();
        _rewardedAd = null;
        // Cargar el siguiente anuncio
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _rewardedState.value = AdState.failed;
        DebugLog.w('Rewarded ad failed to show: $error', category: LogCategory.service);
        ad.dispose();
        _rewardedAd = null;
      },
      onAdClicked: (ad) {
        _rewardedState.value = AdState.clicked;
        DebugLog.d('Rewarded ad clicked', category: LogCategory.service);
      },
    );
  }

  /// Configurar callbacks del anuncio rewarded intersticial
  void _setupRewardedInterstitialCallbacks() {
    _rewardedInterstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _rewardedInterstitialState.value = AdState.showing;
        DebugLog.d('Rewarded interstitial ad showing', category: LogCategory.service);
      },
      onAdDismissedFullScreenContent: (ad) {
        _rewardedInterstitialState.value = AdState.closed;
        DebugLog.d('Rewarded interstitial ad closed', category: LogCategory.service);
        ad.dispose();
        _rewardedInterstitialAd = null;
        // Cargar el siguiente anuncio
        _loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _rewardedInterstitialState.value = AdState.failed;
        DebugLog.w('Rewarded interstitial ad failed to show: $error', category: LogCategory.service);
        ad.dispose();
        _rewardedInterstitialAd = null;
      },
      onAdClicked: (ad) {
        _rewardedInterstitialState.value = AdState.clicked;
        DebugLog.d('Rewarded interstitial ad clicked', category: LogCategory.service);
      },
    );
  }

  /// Configurar callbacks del anuncio app open
  void _setupAppOpenCallbacks() {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _appOpenState.value = AdState.showing;
        DebugLog.d('App open ad showing', category: LogCategory.service);
      },
      onAdDismissedFullScreenContent: (ad) {
        _appOpenState.value = AdState.closed;
        DebugLog.d('App open ad closed', category: LogCategory.service);
        ad.dispose();
        _appOpenAd = null;
        // Cargar el siguiente anuncio
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _appOpenState.value = AdState.failed;
        DebugLog.w('App open ad failed to show: $error', category: LogCategory.service);
        ad.dispose();
        _appOpenAd = null;
      },
      onAdClicked: (ad) {
        _appOpenState.value = AdState.clicked;
        DebugLog.d('App open ad clicked', category: LogCategory.service);
      },
    );
  }

  /// Mostrar anuncio intersticial
  Future<bool> showInterstitialAd() async {
    if (!shouldShowAds || _interstitialAd == null) {
      DebugLog.d(
        'Cannot show interstitial ad - shouldShowAds: $shouldShowAds, ad: ${_interstitialAd != null}',
        category: LogCategory.service,
      );
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

  /// Mostrar anuncio rewarded
  Future<bool> showRewardedAd() async {
    if (!shouldShowAds || _rewardedAd == null) {
      DebugLog.d(
        'Cannot show rewarded ad - shouldShowAds: $shouldShowAds, ad: ${_rewardedAd != null}',
        category: LogCategory.service,
      );
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          DebugLog.d('User earned reward: ${reward.amount} ${reward.type}', category: LogCategory.service);
          // Aquí puedes manejar la recompensa del usuario
        },
      );
      return true;
    } catch (e) {
      DebugLog.e('Error showing rewarded ad: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Mostrar anuncio rewarded intersticial
  Future<bool> showRewardedInterstitialAd() async {
    if (!shouldShowAds || _rewardedInterstitialAd == null) {
      DebugLog.d(
        'Cannot show rewarded interstitial ad - shouldShowAds: $shouldShowAds, ad: ${_rewardedInterstitialAd != null}',
        category: LogCategory.service,
      );
      return false;
    }

    try {
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          DebugLog.d('User earned reward: ${reward.amount} ${reward.type}', category: LogCategory.service);
          // Aquí puedes manejar la recompensa del usuario
        },
      );
      return true;
    } catch (e) {
      DebugLog.e('Error showing rewarded interstitial ad: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Mostrar anuncio app open
  Future<bool> showAppOpenAd() async {
    if (!shouldShowAds || _appOpenAd == null) {
      DebugLog.d(
        'Cannot show app open ad - shouldShowAds: $shouldShowAds, ad: ${_appOpenAd != null}',
        category: LogCategory.service,
      );
      return false;
    }

    try {
      await _appOpenAd!.show();
      return true;
    } catch (e) {
      DebugLog.e('Error showing app open ad: $e', category: LogCategory.service);
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

  /// Disponer del anuncio rewarded
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Disponer del anuncio rewarded intersticial
  void _disposeRewardedInterstitialAd() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
  }

  /// Disponer del anuncio app open
  void _disposeAppOpenAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  /// Disponer del anuncio nativo
  void _disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
  }

  /// Disponer del anuncio adaptive banner
  void _disposeAdaptiveBannerAd() {
    _adaptiveBannerAd?.dispose();
    _adaptiveBannerAd = null;
  }

  /// Disponer del anuncio medium rectangle
  void _disposeMediumRectangleAd() {
    _mediumRectangleAd?.dispose();
    _mediumRectangleAd = null;
  }

  /// Deshabilitar anuncios (cuando el usuario compra premium)
  void disableAds() {
    _adsEnabled.value = false;
    _disposeBannerAd();
    _disposeInterstitialAd();
    _disposeRewardedAd();
    _disposeRewardedInterstitialAd();
    _disposeAppOpenAd();
    _disposeNativeAd();
    _disposeAdaptiveBannerAd();
    _disposeMediumRectangleAd();
    DebugLog.i('Ads disabled - user is now premium', category: LogCategory.service);
  }

  /// Habilitar anuncios (cuando la suscripción expira)
  Future<void> enableAds() async {
    if (_isPremiumUser()) return;

    _adsEnabled.value = true;
    await _loadBannerAd();
    await _loadInterstitialAd();
    await _loadRewardedAd();
    await _loadRewardedInterstitialAd();
    await _loadAppOpenAd();
    await _loadNativeAd();
    await _loadAdaptiveBannerAd();
    await _loadMediumRectangleAd();
    DebugLog.i('Ads enabled - user subscription expired', category: LogCategory.service);
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'adsEnabled': _adsEnabled.value,
      'shouldShowAds': shouldShowAds,
      'bannerState': _bannerState.value.toString(),
      'interstitialState': _interstitialState.value.toString(),
      'rewardedState': _rewardedState.value.toString(),
      'rewardedInterstitialState': _rewardedInterstitialState.value.toString(),
      'appOpenState': _appOpenState.value.toString(),
      'nativeState': _nativeState.value.toString(),
      'adaptiveBannerState': _adaptiveBannerState.value.toString(),
      'mediumRectangleState': _mediumRectangleState.value.toString(),
      'bannerLoaded': _bannerAd != null,
      'interstitialLoaded': _interstitialAd != null,
      'rewardedLoaded': _rewardedAd != null,
      'rewardedInterstitialLoaded': _rewardedInterstitialAd != null,
      'appOpenLoaded': _appOpenAd != null,
      'nativeLoaded': _nativeAd != null,
      'adaptiveBannerLoaded': _adaptiveBannerAd != null,
      'mediumRectangleLoaded': _mediumRectangleAd != null,
      'isPremium': _isPremiumUser(),
      'consecutiveFailures': _consecutiveFailures.value,
      'lastFailureTime': _lastFailureTime.value?.toIso8601String(),
      'isRetrying': _isRetrying.value,
    };
  }

  /// Manejar error de carga de anuncio
  void _handleAdLoadError(AdType adType, String error) {
    _consecutiveFailures.value++;
    _lastFailureTime.value = DateTime.now();

    DebugLog.e('Ad load error for $adType: $error', category: LogCategory.service);

    // Si hay muchos errores consecutivos, pausar temporalmente
    if (_consecutiveFailures.value >= 5) {
      _pauseAdLoading();
    }
  }

  /// Manejar éxito de carga de anuncio
  void _handleAdLoadSuccess() {
    _consecutiveFailures.value = 0; // Resetear contador de errores
    _lastFailureTime.value = null;
  }

  /// Pausar carga de anuncios temporalmente
  void _pauseAdLoading() {
    _adsEnabled.value = false;
    DebugLog.w('Ad loading paused due to consecutive failures', category: LogCategory.service);

    // Reintentar después de 5 minutos
    Future.delayed(const Duration(minutes: 5), () {
      _resumeAdLoading();
    });
  }

  /// Reanudar carga de anuncios
  Future<void> _resumeAdLoading() async {
    _consecutiveFailures.value = 0;
    _adsEnabled.value = true;
    _isRetrying.value = true;

    DebugLog.i('Resuming ad loading after pause', category: LogCategory.service);

    // Recargar anuncios
    await _initializeAds();

    _isRetrying.value = false;
  }

  /// Reiniciar sistema de anuncios
  Future<void> restartAdSystem() async {
    DebugLog.i('Restarting ad system', category: LogCategory.service);

    _consecutiveFailures.value = 0;
    _lastFailureTime.value = null;
    _isRetrying.value = false;
    _adsEnabled.value = true;

    // Limpiar anuncios existentes
    onClose();

    // Reinicializar
    await _initializeAds();
  }

  /// Verificar si se puede mostrar anuncios
  bool canShowAds() {
    if (!shouldShowAds) return false;
    if (_consecutiveFailures.value >= 3) return false;
    if (_isRetrying.value) return false;

    // Verificar si el último error fue muy reciente
    if (_lastFailureTime.value != null) {
      final timeSinceLastError = DateTime.now().difference(_lastFailureTime.value!);
      if (timeSinceLastError.inMinutes < 2) {
        return false;
      }
    }

    return true;
  }
}
