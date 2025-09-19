import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'subscription_controller.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/licencia.dart';

/// Página de suscripción premium
class SubscriptionPage extends GetView<SubscriptionController> {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Get.theme.colorScheme.primary,
              Get.theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      'Te Leo Premium',
                      style: Get.theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance del IconButton
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de beneficios
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade300,
                                      Colors.orange.shade400,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Desbloquea Todo el Potencial',
                                style: Get.theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Accede a funciones avanzadas y mejora tu experiencia de lectura',
                                style: Get.theme.textTheme.bodyLarge?.copyWith(
                                  color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Lista de beneficios
                        Text(
                          'Funciones Premium',
                          style: Get.theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Get.theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._buildFeatureList(),

                        const SizedBox(height: 32),

                        // Planes de suscripción
                        Text(
                          'Elige tu Plan',
                          style: Get.theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Get.theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Obx(() => Column(
                          children: controller.subscriptionProducts
                              .map((product) => _buildSubscriptionCard(product))
                              .toList(),
                        )),

                        const SizedBox(height: 24),

                        // Botón de demo
                        Center(
                          child: TextButton(
                            onPressed: controller.activateDemo,
                            child: Text(
                              'Probar Gratis por 7 Días',
                              style: TextStyle(
                                color: Get.theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botón de restaurar compras
                        Center(
                          child: Obx(() => TextButton(
                            onPressed: controller.isRestoring 
                                ? null 
                                : controller.restorePurchases,
                            child: Text(
                              controller.isRestoring 
                                  ? 'Restaurando...' 
                                  : 'Restaurar Compras',
                              style: TextStyle(
                                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          )),
                        ),

                        const SizedBox(height: 32),

                        // Términos y condiciones
                        Center(
                          child: Text(
                            'Al suscribirte aceptas nuestros Términos de Servicio y Política de Privacidad',
                            style: Get.theme.textTheme.bodySmall?.copyWith(
                              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir lista de características
  List<Widget> _buildFeatureList() {
    final features = [
      {'icon': Icons.record_voice_over, 'title': 'Voces Premium', 'description': 'Acceso a voces naturales adicionales'},
      {'icon': Icons.file_download, 'title': 'Exportar Documentos', 'description': 'Guarda en PDF, Word y otros formatos'},
      {'icon': Icons.cloud_sync, 'title': 'Sincronización', 'description': 'Accede a tus documentos desde cualquier dispositivo'},
      {'icon': Icons.support_agent, 'title': 'Soporte Prioritario', 'description': 'Respuesta garantizada en 24 horas'},
      {'icon': Icons.block, 'title': 'Sin Anuncios', 'description': 'Experiencia completamente libre de publicidad'},
      {'icon': Icons.science, 'title': 'Funciones Beta', 'description': 'Acceso anticipado a nuevas características'},
    ];

    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: Get.theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: Get.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'] as String,
                  style: Get.theme.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )).toList();
  }

  /// Construir tarjeta de suscripción
  Widget _buildSubscriptionCard(SubscriptionProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isPopular 
              ? Get.theme.colorScheme.primary
              : Get.theme.colorScheme.outline.withValues(alpha: 0.3),
          width: product.isPopular ? 2 : 1,
        ),
        gradient: product.isPopular
            ? LinearGradient(
                colors: [
                  Get.theme.colorScheme.primary.withValues(alpha: 0.05),
                  Get.theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                ],
              )
            : null,
      ),
      child: Stack(
        children: [
          // Badge de popular
          if (product.isPopular)
            Positioned(
              top: -1,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Más Popular',
                  style: Get.theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del plan
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: Get.theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: Get.theme.textTheme.bodyMedium?.copyWith(
                              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.price,
                          style: Get.theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Get.theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          product.type == TipoLicencia.premiumMensual ? '/mes' : '/año',
                          style: Get.theme.textTheme.bodySmall?.copyWith(
                            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Características incluidas
                ...product.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                     const  Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: Get.theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 20),

                // Botón de suscripción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.subscribe(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isPopular 
                          ? Get.theme.colorScheme.primary
                          : Get.theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Suscribirse',
                      style: Get.theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
