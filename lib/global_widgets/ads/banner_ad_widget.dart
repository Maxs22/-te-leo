import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/core/services/ads_service.dart';

/// Widget para mostrar anuncios banner
class BannerAdWidget extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;
  final bool showDebugInfo;

  const BannerAdWidget({super.key, this.height, this.margin, this.showDebugInfo = false});

  @override
  Widget build(BuildContext context) {
    final adsService = Get.find<AdsService>();

    return Obx(() {
      // No mostrar anuncios si el usuario es premium
      if (!adsService.shouldShowAds) {
        return const SizedBox.shrink();
      }

      // No mostrar si el anuncio no está cargado
      final state = adsService.bannerState;
      final ad = adsService.bannerAd;

      if (state != AdState.loaded || ad == null) {
        if (showDebugInfo) {
          return Container(
            height: height ?? 50,
            margin: margin,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text('Banner Ad: $state', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      // Crear un AdWidget único con key para evitar duplicados
      return Container(
        height: height ?? 50,
        margin: margin ?? const EdgeInsets.all(8.0),
        child: AdWidget(key: ValueKey('banner_ad_${ad.hashCode}'), ad: ad),
      );
    });
  }
}

/// Widget para banner adaptativo (se ajusta al ancho de la pantalla)
class AdaptiveBannerAdWidget extends StatelessWidget {
  final EdgeInsets? margin;
  final bool showDebugInfo;

  const AdaptiveBannerAdWidget({super.key, this.margin, this.showDebugInfo = false});

  @override
  Widget build(BuildContext context) {
    final adsService = Get.find<AdsService>();

    return Obx(() {
      // No mostrar anuncios si el usuario es premium
      if (!adsService.shouldShowAds) {
        return const SizedBox.shrink();
      }

      // No mostrar si el anuncio no está cargado
      final state = adsService.adaptiveBannerState;
      final ad = adsService.adaptiveBannerAd;

      if (state != AdState.loaded || ad == null) {
        if (showDebugInfo) {
          return Container(
            height: 50,
            margin: margin,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text('Adaptive Banner: $state', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      return Container(
        height: 60, // Altura fija para banners adaptativos
        margin: margin ?? const EdgeInsets.all(8.0),
        child: AdWidget(key: ValueKey('adaptive_banner_ad_${ad.hashCode}'), ad: ad),
      );
    });
  }
}

/// Widget para anuncios medium rectangle (300x250)
class MediumRectangleAdWidget extends StatelessWidget {
  final EdgeInsets? margin;
  final bool showDebugInfo;

  const MediumRectangleAdWidget({super.key, this.margin, this.showDebugInfo = false});

  @override
  Widget build(BuildContext context) {
    final adsService = Get.find<AdsService>();

    return Obx(() {
      // No mostrar anuncios si el usuario es premium
      if (!adsService.shouldShowAds) {
        return const SizedBox.shrink();
      }

      // No mostrar si el anuncio no está cargado
      final state = adsService.mediumRectangleState;
      final ad = adsService.mediumRectangleAd;

      if (state != AdState.loaded || ad == null) {
        if (showDebugInfo) {
          return Container(
            width: 300,
            height: 250,
            margin: margin,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text('Medium Rectangle: $state', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      return Center(
        child: Container(
          width: 300,
          height: 250,
          margin: margin ?? const EdgeInsets.all(8.0),
          child: AdWidget(key: ValueKey('medium_rectangle_ad_${ad.hashCode}'), ad: ad),
        ),
      );
    });
  }
}
