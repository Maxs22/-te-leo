import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/core/services/ads_service.dart';
import '../../app/core/services/debug_console_service.dart';

/// Gestor para manejar anuncios App Open
class AppOpenAdManager {
  static AppOpenAdManager get instance => _instance;
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  // Control de frecuencia
  DateTime? _lastAppOpenAdTime;
  Duration _minInterval = const Duration(minutes: 4); // Mínimo 4 minutos entre anuncios
  bool _isShowingAd = false;
  bool _isAppInBackground = false;

  /// Configurar intervalo mínimo entre anuncios App Open
  void setMinInterval(Duration interval) {
    _minInterval = interval;
    DebugLog.d('App Open ad min interval set to: $interval');
  }

  /// Verificar si se debe mostrar anuncio App Open
  bool shouldShowAppOpenAd() {
    final adsService = Get.find<AdsService>();

    // No mostrar si no hay anuncios habilitados
    if (!adsService.shouldShowAds) {
      DebugLog.d('Should not show app open ad: ads disabled or premium user');
      return false;
    }

    // No mostrar si no hay anuncio cargado
    if (adsService.appOpenState != AdState.loaded) {
      DebugLog.d('Should not show app open ad: ad not loaded (${adsService.appOpenState})');
      return false;
    }

    // No mostrar si ya se está mostrando un anuncio
    if (_isShowingAd) {
      DebugLog.d('Should not show app open ad: already showing an ad');
      return false;
    }

    // Verificar intervalo mínimo de tiempo
    if (_lastAppOpenAdTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAppOpenAdTime!);
      if (timeSinceLastAd < _minInterval) {
        DebugLog.d('Should not show app open ad: too soon since last ad ($timeSinceLastAd)');
        return false;
      }
    }

    DebugLog.d('Should show app open ad: all conditions met');
    return true;
  }

  /// Mostrar anuncio App Open si cumple las condiciones
  Future<bool> showAppOpenAdIfAppropriate() async {
    if (!shouldShowAppOpenAd()) {
      return false;
    }

    return await _showAppOpenAd();
  }

  /// Forzar mostrar anuncio App Open (para testing)
  Future<bool> forceShowAppOpenAd() async {
    final adsService = Get.find<AdsService>();

    if (!adsService.shouldShowAds) {
      DebugLog.w('Cannot force show app open ad: ads disabled or premium user');
      return false;
    }

    if (adsService.appOpenState != AdState.loaded) {
      DebugLog.w('Cannot force show app open ad: ad not loaded (${adsService.appOpenState})');
      return false;
    }

    if (_isShowingAd) {
      DebugLog.w('Cannot force show app open ad: already showing an ad');
      return false;
    }

    return await _showAppOpenAd();
  }

  /// Mostrar anuncio App Open
  Future<bool> _showAppOpenAd() async {
    try {
      _isShowingAd = true;
      final adsService = Get.find<AdsService>();
      final success = await adsService.showAppOpenAd();

      if (success) {
        _lastAppOpenAdTime = DateTime.now();
        DebugLog.i('App open ad shown successfully');
      } else {
        DebugLog.w('Failed to show app open ad');
      }

      return success;
    } catch (e) {
      DebugLog.e('Error showing app open ad: $e');
      return false;
    } finally {
      _isShowingAd = false;
    }
  }

  /// Manejar cuando la app entra en primer plano
  Future<void> onAppResumed() async {
    DebugLog.d('App resumed - checking for app open ad');

    // Solo mostrar si la app estuvo en segundo plano por suficiente tiempo
    if (_isAppInBackground && shouldShowAppOpenAd()) {
      // Pequeño delay para que la app se estabilice
      await Future.delayed(const Duration(milliseconds: 500));
      await showAppOpenAdIfAppropriate();
    }

    _isAppInBackground = false;
  }

  /// Manejar cuando la app entra en segundo plano
  void onAppPaused() {
    DebugLog.d('App paused');
    _isAppInBackground = true;
  }

  /// Manejar cuando la app se inicia por primera vez
  Future<void> onAppStarted() async {
    DebugLog.d('App started - checking for app open ad');

    // Pequeño delay para que la app se estabilice
    await Future.delayed(const Duration(milliseconds: 1000));
    await showAppOpenAdIfAppropriate();
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'lastAppOpenAdTime': _lastAppOpenAdTime?.toIso8601String(),
      'minInterval': _minInterval.inMinutes,
      'isShowingAd': _isShowingAd,
      'isAppInBackground': _isAppInBackground,
      'shouldShow': shouldShowAppOpenAd(),
    };
  }

  /// Resetear estado completo
  void reset() {
    _lastAppOpenAdTime = null;
    _isShowingAd = false;
    _isAppInBackground = false;
    DebugLog.d('App open ad manager state reset');
  }
}

/// Mixin para agregar funcionalidad de anuncios App Open a widgets
mixin AppOpenAdMixin<T extends StatefulWidget> on State<T> {
  final AppOpenAdManager _adManager = AppOpenAdManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(_adManager));
  }

  /// Configurar intervalo mínimo
  void setAppOpenMinInterval(Duration interval) {
    _adManager.setMinInterval(interval);
  }

  /// Forzar mostrar anuncio App Open
  Future<void> forceShowAppOpenAd() async {
    await _adManager.forceShowAppOpenAd();
  }
}

/// Observer del ciclo de vida de la app para manejar anuncios App Open
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppOpenAdManager _adManager;

  _AppLifecycleObserver(this._adManager);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _adManager.onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _adManager.onAppPaused();
        break;
      case AppLifecycleState.detached:
        // La app se está cerrando
        break;
      case AppLifecycleState.hidden:
        _adManager.onAppPaused();
        break;
    }
  }
}

/// Widget para mostrar información de debug de anuncios App Open
class AppOpenDebugWidget extends StatelessWidget {
  const AppOpenDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdsService>(
      builder: (adsService) {
        if (!adsService.showDebugInfo) {
          return const SizedBox.shrink();
        }

        final debugInfo = AppOpenAdManager.instance.getDebugInfo();

        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('App Open Debug Info', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...debugInfo.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
