import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget para mostrar el estado de los servicios (solo en debug)
class ServiceStatusWidget extends StatelessWidget {
  const ServiceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Solo mostrar en modo debug
    if (!Get.isLogEnable) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado de Servicios',
            style: Get.theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildServiceStatus(),
        ],
      ),
    );
  }

  List<Widget> _buildServiceStatus() {
    final services = [
      'VersionService',
      'SubscriptionService',
      'DeviceSecurityService',
      'AccessValidationService',
      'AppUpdateService',
      'EnhancedTTSService',
      'TTSService',
    ];

     return services.map((serviceName) {
       Color statusColor = Colors.red;
       String statusText = 'No registrado';

       try {
         // Verificar si el servicio está registrado sin usar tipos específicos
         Get.find(tag: serviceName);
         statusColor = Colors.green;
         statusText = 'Activo';
       } catch (e) {
         // Servicio no encontrado
         try {
           // Intentar sin tag
           switch (serviceName) {
             case 'VersionService':
               Get.find(tag: 'VersionService');
               break;
             default:
               // Asumir no registrado
               break;
           }
           statusColor = Colors.green;
           statusText = 'Activo';
         } catch (e2) {
           // Definitivamente no registrado
         }
       }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                serviceName,
                style: Get.theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              statusText,
              style: Get.theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Widget flotante para mostrar estado de servicios
class FloatingServiceStatus extends StatelessWidget {
  const FloatingServiceStatus({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isLogEnable) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: () => _showDetailedStatus(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 16,
              ),
               SizedBox(width: 4),
              Text(
                'Debug',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedStatus() {
    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estado de Servicios',
                style: Get.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
             const  Expanded(
                child: SingleChildScrollView(
                  child: ServiceStatusWidget(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
