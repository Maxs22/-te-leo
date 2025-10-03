import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/core/services/ads_service.dart';
import '../../app/core/services/debug_console_service.dart';

/// Gestor para manejar la lógica de anuncios intersticiales
class InterstitialAdManager {
  static InterstitialAdManager get instance => _instance;
  static final InterstitialAdManager _instance = InterstitialAdManager._internal();
  factory InterstitialAdManager() => _instance;
  InterstitialAdManager._internal();

  // Contador para controlar frecuencia de anuncios
  int _chapterCount = 0;
  int _interstitialFrequency = 3; // Mostrar cada 3 capítulos
  DateTime? _lastInterstitialTime;
  Duration _minInterval = const Duration(minutes: 5); // Mínimo 5 minutos entre anuncios

  /// Configurar frecuencia de anuncios intersticiales
  void setFrequency(int frequency) {
    _interstitialFrequency = frequency;
    DebugLog.d('Interstitial frequency set to: $frequency chapters');
  }

  /// Configurar intervalo mínimo entre anuncios
  void setMinInterval(Duration interval) {
    _minInterval = interval;
    DebugLog.d('Min interval between interstitials set to: $interval');
  }

  /// Incrementar contador de capítulos
  void incrementChapterCount() {
    _chapterCount++;
    DebugLog.d('Chapter count incremented to: $_chapterCount');
  }

  /// Resetear contador de capítulos
  void resetChapterCount() {
    _chapterCount = 0;
    DebugLog.d('Chapter count reset to 0');
  }

  /// Verificar si se debe mostrar anuncio intersticial
  bool shouldShowInterstitial() {
    final adsService = Get.find<AdsService>();
    
    // No mostrar si no hay anuncios habilitados
    if (!adsService.shouldShowAds) {
      DebugLog.d('Should not show interstitial: ads disabled or premium user');
      return false;
    }

    // No mostrar si no hay anuncio cargado
    if (adsService.interstitialState != AdState.loaded) {
      DebugLog.d('Should not show interstitial: ad not loaded (${adsService.interstitialState})');
      return false;
    }

    // Verificar frecuencia de capítulos
    if (_chapterCount < _interstitialFrequency) {
      DebugLog.d('Should not show interstitial: chapter count ($_chapterCount) < frequency ($_interstitialFrequency)');
      return false;
    }

    // Verificar intervalo mínimo de tiempo
    if (_lastInterstitialTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime!);
      if (timeSinceLastAd < _minInterval) {
        DebugLog.d('Should not show interstitial: too soon since last ad ($timeSinceLastAd)');
        return false;
      }
    }

    DebugLog.d('Should show interstitial: all conditions met');
    return true;
  }

  /// Mostrar anuncio intersticial si cumple las condiciones
  Future<bool> showInterstitialIfAppropriate() async {
    if (!shouldShowInterstitial()) {
      return false;
    }

    return await _showInterstitial();
  }

  /// Forzar mostrar anuncio intersticial (para testing)
  Future<bool> forceShowInterstitial() async {
    final adsService = Get.find<AdsService>();
    
    if (!adsService.shouldShowAds) {
      DebugLog.w('Cannot force show interstitial: ads disabled or premium user');
      return false;
    }

    if (adsService.interstitialState != AdState.loaded) {
      DebugLog.w('Cannot force show interstitial: ad not loaded (${adsService.interstitialState})');
      return false;
    }

    return await _showInterstitial();
  }

  /// Mostrar anuncio intersticial
  Future<bool> _showInterstitial() async {
    try {
      final adsService = Get.find<AdsService>();
      final success = await adsService.showInterstitialAd();
      
      if (success) {
        _lastInterstitialTime = DateTime.now();
        resetChapterCount(); // Resetear contador después de mostrar
        DebugLog.i('Interstitial ad shown successfully');
      } else {
        DebugLog.w('Failed to show interstitial ad');
      }
      
      return success;
    } catch (e) {
      DebugLog.e('Error showing interstitial ad: $e');
      return false;
    }
  }

  /// Mostrar anuncio al completar capítulo
  Future<bool> showInterstitialOnChapterComplete() async {
    incrementChapterCount();
    return await showInterstitialIfAppropriate();
  }

  /// Mostrar anuncio al cambiar de libro
  Future<bool> showInterstitialOnBookChange() async {
    // Forzar mostrar al cambiar de libro (sin verificar frecuencia)
    return await _showInterstitial();
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'chapterCount': _chapterCount,
      'interstitialFrequency': _interstitialFrequency,
      'lastInterstitialTime': _lastInterstitialTime?.toIso8601String(),
      'minInterval': _minInterval.inMinutes,
      'shouldShow': shouldShowInterstitial(),
    };
  }

  /// Resetear estado completo
  void reset() {
    _chapterCount = 0;
    _lastInterstitialTime = null;
    DebugLog.d('Interstitial manager state reset');
  }
}

/// Mixin para agregar funcionalidad de anuncios intersticiales a widgets
mixin InterstitialAdMixin<T extends StatefulWidget> on State<T> {
  final InterstitialAdManager _adManager = InterstitialAdManager.instance;

  /// Mostrar anuncio al completar capítulo
  Future<void> showInterstitialOnChapterComplete() async {
    await _adManager.showInterstitialOnChapterComplete();
  }

  /// Mostrar anuncio al cambiar de libro
  Future<void> showInterstitialOnBookChange() async {
    await _adManager.showInterstitialOnBookChange();
  }

  /// Configurar frecuencia de anuncios
  void setInterstitialFrequency(int frequency) {
    _adManager.setFrequency(frequency);
  }

  /// Configurar intervalo mínimo
  void setInterstitialMinInterval(Duration interval) {
    _adManager.setMinInterval(interval);
  }
}

/// Widget para mostrar información de debug de anuncios intersticiales
class InterstitialDebugWidget extends StatelessWidget {
  const InterstitialDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdsService>(
      builder: (adsService) {
        if (!adsService.showDebugInfo) {
          return const SizedBox.shrink();
        }

        final debugInfo = InterstitialAdManager.instance.getDebugInfo();
        
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Interstitial Debug Info',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...debugInfo.entries.map((entry) => Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(fontSize: 12),
              )),
            ],
          ),
        );
      },
    );
  }
}
