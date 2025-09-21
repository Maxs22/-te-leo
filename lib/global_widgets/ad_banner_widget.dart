import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../app/core/services/ads_service.dart';
import '../app/core/services/subscription_service.dart';

/// Widget para mostrar banners de anuncios en la app
class AdBannerWidget extends StatelessWidget {
  final EdgeInsets? margin;
  final bool showOnlyIfFree;

  const AdBannerWidget({
    super.key,
    this.margin,
    this.showOnlyIfFree = true,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final adsService = Get.find<AdsService>();
      return Obx(() {
        // No mostrar si el usuario es premium y está configurado para solo mostrar a usuarios gratuitos
        if (showOnlyIfFree) {
          try {
            final subscriptionService = Get.find<SubscriptionService>();
            if (subscriptionService.isPremium) {
              return const SizedBox.shrink();
            }
          } catch (e) {
            // Si no se puede verificar, mostrar por defecto
          }
        }

        // No mostrar si los anuncios están deshabilitados
        if (!adsService.shouldShowAds) {
          return const SizedBox.shrink();
        }

        // No mostrar si el anuncio no está cargado
        if (adsService.bannerState != AdState.loaded || adsService.bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Get.theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: adsService.bannerAd!.size.width.toDouble(),
              height: adsService.bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: adsService.bannerAd!),
            ),
          ),
        );
      });
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}

/// Widget para mostrar el estado de carga de anuncios (desarrollo)
class AdStatusWidget extends StatelessWidget {
  const AdStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AdsService>(
      builder: (adsService) {
        return Obx(() {
          if (!adsService.shouldShowAds) {
            return Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Premium - Sin anuncios',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final bannerState = adsService.bannerState;
          Color statusColor;
          String statusText;
          IconData statusIcon;

          switch (bannerState) {
            case AdState.loading:
              statusColor = Colors.orange;
              statusText = 'Cargando anuncio...';
              statusIcon = Icons.hourglass_empty;
              break;
            case AdState.loaded:
              statusColor = Colors.green;
              statusText = 'Anuncio listo';
              statusIcon = Icons.check_circle;
              break;
            case AdState.failed:
              statusColor = Colors.red;
              statusText = 'Error cargando anuncio';
              statusIcon = Icons.error;
              break;
            default:
              statusColor = Colors.grey;
              statusText = 'Estado: ${bannerState.name}';
              statusIcon = Icons.info;
          }

          return Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

/// Widget para mostrar anuncios intersticiales con botón de prueba (desarrollo)
class InterstitialAdTestWidget extends StatelessWidget {
  const InterstitialAdTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AdsService>(
      builder: (adsService) {
        return Obx(() {
          if (!adsService.shouldShowAds) {
            return const SizedBox.shrink();
          }

          final interstitialState = adsService.interstitialState;
          final canShow = interstitialState == AdState.loaded;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: canShow 
                ? () async {
                    final shown = await adsService.showInterstitialAd();
                    if (shown) {
                      Get.snackbar(
                        '📺 Anuncio Mostrado',
                        'Anuncio intersticial mostrado exitosamente',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  }
                : null,
              icon: Icon(
                canShow ? Icons.play_arrow : Icons.hourglass_empty,
                size: 16,
              ),
              label: Text(
                canShow 
                  ? 'Mostrar Anuncio Intersticial' 
                  : 'Cargando anuncio... (${interstitialState.name})',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canShow ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          );
        });
      },
    );
  }
}
