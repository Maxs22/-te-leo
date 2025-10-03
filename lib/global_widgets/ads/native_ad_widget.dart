import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/core/services/ads_service.dart';

/// Widget para mostrar anuncios nativos integrados
class NativeAdWidget extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;
  final bool showDebugInfo;
  final Widget Function(NativeAd nativeAd)? customBuilder;

  const NativeAdWidget({super.key, this.height, this.margin, this.showDebugInfo = false, this.customBuilder});

  @override
  Widget build(BuildContext context) {
    final adsService = Get.find<AdsService>();

    return Obx(() {
      // No mostrar anuncios si el usuario es premium
      if (!adsService.shouldShowAds) {
        return const SizedBox.shrink();
      }

      // No mostrar si el anuncio no está cargado
      final state = adsService.nativeState;
      final ad = adsService.nativeAd;

      if (state != AdState.loaded || ad == null) {
        if (showDebugInfo) {
          return Container(
            height: height ?? 120,
            margin: margin,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('Native Ad: $state', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      // Usar builder personalizado si se proporciona
      if (customBuilder != null) {
        return Container(
          key: ValueKey('native_ad_custom_${ad.hashCode}'),
          margin: margin ?? const EdgeInsets.all(8.0),
          child: customBuilder!(ad),
        );
      }

      // Builder por defecto para anuncios nativos
      return Container(
        height: height ?? 120,
        margin: margin ?? const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AdWidget(key: ValueKey('native_ad_${ad.hashCode}'), ad: ad),
        ),
      );
    });
  }
}

/// Widget especializado para anuncios nativos en listas de libros
class BookListNativeAdWidget extends StatelessWidget {
  final EdgeInsets? margin;
  final bool showDebugInfo;

  const BookListNativeAdWidget({super.key, this.margin, this.showDebugInfo = false});

  @override
  Widget build(BuildContext context) {
    return NativeAdWidget(
      height: 100,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showDebugInfo: showDebugInfo,
      customBuilder: (nativeAd) => _buildBookListNativeAd(context, nativeAd),
    );
  }

  Widget _buildBookListNativeAd(BuildContext context, NativeAd nativeAd) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Imagen del anuncio (placeholder)
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.ads_click, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          // Contenido del anuncio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descubre nuevos libros',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Encuentra tu próxima lectura favorita',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Text(
                    'Publicidad',
                    style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Widget del anuncio nativo
          SizedBox(
            width: 100,
            height: 80,
            child: AdWidget(key: ValueKey('book_list_native_${nativeAd.hashCode}'), ad: nativeAd),
          ),
        ],
      ),
    );
  }
}
