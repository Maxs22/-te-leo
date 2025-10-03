import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/core/services/subscription_service.dart';

/// Badge para mostrar estado premium
class PremiumBadge extends StatelessWidget {
  final bool showOnlyWhenPremium;
  final BadgeSize size;
  final VoidCallback? onTap;

  const PremiumBadge({super.key, this.showOnlyWhenPremium = true, this.size = BadgeSize.medium, this.onTap});

  @override
  Widget build(BuildContext context) {
    try {
      // Verificar si el servicio está registrado
      if (!Get.isRegistered<SubscriptionService>()) {
        return const SizedBox.shrink();
      }

      return GetX<SubscriptionService>(
        builder: (service) {
          if (showOnlyWhenPremium && !service.isPremium) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: _getPadding(),
              decoration: BoxDecoration(
                gradient: _getGradient(service),
                borderRadius: BorderRadius.circular(_getBorderRadius()),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIcon(service), color: Colors.white, size: _getIconSize()),
                  SizedBox(width: _getSpacing()),
                  Text(
                    _getText(service),
                    style: TextStyle(color: Colors.white, fontSize: _getFontSize(), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Si el servicio no está disponible, no mostrar nada
      return const SizedBox.shrink();
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 16;
      case BadgeSize.large:
        return 20;
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 14;
      case BadgeSize.medium:
        return 16;
      case BadgeSize.large:
        return 20;
    }
  }

  double _getSpacing() {
    switch (size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 6;
      case BadgeSize.large:
        return 8;
    }
  }

  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 11;
      case BadgeSize.medium:
        return 12;
      case BadgeSize.large:
        return 14;
    }
  }

  LinearGradient _getGradient(SubscriptionService service) {
    if (service.isPremium) {
      return LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade500]);
    } else if (service.isDemo) {
      return LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade500]);
    } else {
      return LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]);
    }
  }

  IconData _getIcon(SubscriptionService service) {
    if (service.isPremium) {
      return Icons.star;
    } else if (service.isDemo) {
      return Icons.access_time;
    } else {
      return Icons.lock_outline;
    }
  }

  String _getText(SubscriptionService service) {
    if (service.isPremium) {
      return 'Premium';
    } else if (service.isDemo) {
      final license = service.currentLicense;
      return 'Demo (${license?.diasRestantes ?? 0}d)';
    } else {
      return 'Gratuito';
    }
  }
}

/// Tamaños disponibles para el badge
enum BadgeSize { small, medium, large }

/// Widget para mostrar características premium bloqueadas
class PremiumFeatureLock extends StatelessWidget {
  final String featureName;
  final String description;
  final VoidCallback? onUpgrade;

  const PremiumFeatureLock({super.key, required this.featureName, required this.description, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Get.theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(featureName, style: Get.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Get.theme.textTheme.bodyMedium?.copyWith(
                        color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpgrade ?? () => Get.toNamed('/subscription'),
              icon: const Icon(Icons.upgrade, size: 18),
              label: const Text('Desbloquear con Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
