import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../../global_widgets/global_widgets.dart';
import '../../../global_widgets/ad_banner_widget.dart';
import '../../core/theme/accessible_colors.dart';

/// Página principal limpia y moderna de Te Leo
class CleanHomePage extends GetView<HomeController> {
  const CleanHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // Mostrar diálogo de confirmación al intentar salir
        Get.dialog(
          ModernDialog(
            titulo: 'exit_app_title'.tr,
            contenido: 'exit_app_message'.tr,
            textoBotonPrimario: 'exit'.tr,
            textoBotonSecundario: 'cancel'.tr,
            onBotonPrimario: () {
              Get.back(); // Cerrar diálogo
              SystemNavigator.pop(); // Salir de la app
            },
            onBotonSecundario: () => Get.back(), // Solo cerrar diálogo
            icono: Icons.exit_to_app,
            colorIcono: Get.theme.colorScheme.error,
          ),
        );
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Get.isDarkMode
                ? AccessibleColors.darkGradient
                : AccessibleColors.lightGradient,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Notificación de actualización (si está disponible)
                  const UpdateNotification(
                    showOnlyWhenAvailable: true,
                    compact: true,
                  ),
                  
                  // Header con saludo personalizado y configuraciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'welcome_back'.tr,
                              style: Get.theme.textTheme.titleMedium?.copyWith(
                                color: AccessibleColors.getTextOnGradient(isSecondary: true),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'home_title'.tr,
                              style: Get.theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AccessibleColors.getTextOnGradient(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Botón de configuraciones
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: controller.irAConfiguraciones,
                          icon: Icon(
                            Icons.settings,
                            color: AccessibleColors.getTextOnGradient(),
                            size: 24,
                          ),
                          tooltip: 'settings'.tr,
                        ),
                      ),
                    ],
                  ),
                  
                  // Contenido principal
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                        // Logo/Icono principal
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_stories,
                            size: 40,
                            color: AccessibleColors.getTextOnGradient(),
                          ),
                        ),
                        
                        // Descripción principal (compacta)
                        Column(
                          children: [
                            Text(
                              'app_description'.tr,
                              style: Get.theme.textTheme.titleMedium?.copyWith(
                                color: AccessibleColors.getTextOnGradient(),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'app_tagline'.tr,
                              style: Get.theme.textTheme.bodyMedium?.copyWith(
                                color: AccessibleColors.getTextOnGradient(isSecondary: true),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                    
                        // Botones de acción principales
                        Column(
                          children: [
                            // Botón principal: Escanear texto
                            _buildActionButton(
                              onPressed: controller.escanearTexto,
                              icon: Icons.camera_alt,
                              label: 'scan_text'.tr,
                              isPrimary: true,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Botón secundario: Mi Biblioteca
                            _buildActionButton(
                              onPressed: controller.irABiblioteca,
                              icon: Icons.library_books,
                              label: 'my_library'.tr,
                              isCompact: false,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Estadísticas del usuario (si están disponibles)
                        Obx(() => controller.hasStatistics
                          ? _buildStatisticsCard()
                          : const SizedBox.shrink()),
                        
                        const SizedBox(height: 40),
                        
                        // Información de versión al final
                        _buildVersionInfo(),
                        
                        const SizedBox(height: 20),
                        
                        // Banner de anuncios para usuarios gratuitos
                        const AdBannerWidget(
                          showOnlyIfFree: true,
                          margin: EdgeInsets.only(bottom: 10),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye información de versión
  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: AccessibleColors.getTextOnGradient(isSecondary: true),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${'app_name'.tr} v${controller.appVersion}',
            style: Get.theme.textTheme.bodySmall?.copyWith(
              color: AccessibleColors.getTextOnGradient(isSecondary: true),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // Indicador de actualización si está disponible
          Obx(() => controller.hasUpdateAvailable
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'update_available'.tr,
                  style: TextStyle(
                    color: Get.theme.colorScheme.onSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const SizedBox.shrink()),
        ],
      ),
    );
  }

  /// Construye un botón de acción moderno
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return Container(
      width: isCompact ? null : double.infinity,
      height: isPrimary ? 64 : 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isPrimary ? 0.25 : 0.2),
        borderRadius: BorderRadius.circular(isPrimary ? 20 : 16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isPrimary ? 0.4 : 0.3),
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isPrimary ? 15 : 10,
            offset: Offset(0, isPrimary ? 6 : 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary 
            ? Get.theme.colorScheme.primary 
            : AccessibleColors.getTextOnGradient(),
          size: isPrimary ? 24 : 22,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isPrimary 
              ? Get.theme.colorScheme.primary 
              : AccessibleColors.getTextOnGradient(),
            fontWeight: FontWeight.w600,
            fontSize: isPrimary ? 18 : 16,
          ),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPrimary ? 20 : 16),
          ),
        ),
      ),
    );
  }

  /// Construye tarjeta de estadísticas
  Widget _buildStatisticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics,
            color: AccessibleColors.getTextOnGradient(),
            size: 32,
          ),
          const SizedBox(height: 16),
          
          Text(
            'statistics_title'.tr,
            style: Get.theme.textTheme.titleMedium?.copyWith(
              color: AccessibleColors.getTextOnGradient(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Estadísticas en fila
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.document_scanner,
                  value: controller.documentsScanned.toString(),
                  label: 'documents_scanned'.tr,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.headphones,
                  value: controller.minutesListened.toString(),
                  label: 'minutes_listened'.tr,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  value: controller.consecutiveDays.toString(),
                  label: 'consecutive_days'.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye item de estadística
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AccessibleColors.getTextOnGradient(isSecondary: true),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Get.theme.textTheme.headlineSmall?.copyWith(
            color: AccessibleColors.getTextOnGradient(),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Get.theme.textTheme.bodySmall?.copyWith(
            color: AccessibleColors.getTextOnGradient(isSecondary: true),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
