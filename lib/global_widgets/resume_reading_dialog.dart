import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/core/services/user_preferences_service.dart';
import '../app/core/services/debug_console_service.dart';
import 'modern_dialog.dart';

/// Dialog para resumir lectura desde donde se quedó
class ResumeReadingDialog extends StatelessWidget {
  final String documentId;
  final String documentTitle;
  final VoidCallback? onResume;
  final VoidCallback? onRestart;
  final VoidCallback? onCancel;

  const ResumeReadingDialog({
    super.key,
    required this.documentId,
    required this.documentTitle,
    this.onResume,
    this.onRestart,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final prefsService = Get.find<UserPreferencesService>();
    final progress = prefsService.getReadingProgress(documentId);
    
    if (progress == null || progress['hasProgress'] != true) {
      // No hay progreso, no mostrar dialog
      return const SizedBox.shrink();
    }

    final percentage = (progress['percentage'] as double) * 100;
    final lastReadDate = progress['date'] as DateTime?;

    return ModernDialog(
      titulo: 'continue_reading_title'.tr,
      icono: Icons.bookmark,
      colorIcono: Get.theme.colorScheme.primary,
      contenidoWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información del documento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Get.theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        documentTitle,
                        style: Get.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Barra de progreso
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'reading_progress'.tr,
                          style: Get.theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Get.theme.textTheme.bodyMedium?.copyWith(
                            color: Get.theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Get.theme.colorScheme.primary),
                    ),
                  ],
                ),
                
                // Información de última lectura
                if (lastReadDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Última lectura: ${_formatDate(lastReadDate)}',
                        style: Get.theme.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Mensaje explicativo
          Text(
            'continue_reading_message'.tr,
            style: Get.theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      textoBotonPrimario: 'continue_button'.tr,
      textoBotonSecundario: 'restart_button'.tr,
      onBotonPrimario: () {
        DebugLog.i('User chose to resume reading from ${percentage.toStringAsFixed(1)}%', 
                   category: LogCategory.ui);
        Get.back();
        onResume?.call();
      },
      onBotonSecundario: () {
        DebugLog.i('User chose to restart reading', category: LogCategory.ui);
        Get.back();
        onRestart?.call();
      },
      barrierDismissible: false,
    );
  }

  /// Formatear fecha para mostrar
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
      return '${weekdays[date.weekday - 1]} pasado';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Mostrar dialog estático
  static void show({
    required String documentId,
    required String documentTitle,
    VoidCallback? onResume,
    VoidCallback? onRestart,
    VoidCallback? onCancel,
  }) {
    final prefsService = Get.find<UserPreferencesService>();
    final progress = prefsService.getReadingProgress(documentId);
    
    if (progress == null || progress['hasProgress'] != true) {
      // No hay progreso, llamar directamente onRestart
      onRestart?.call();
      return;
    }

    Get.dialog(
      ResumeReadingDialog(
        documentId: documentId,
        documentTitle: documentTitle,
        onResume: onResume,
        onRestart: () {
          // Limpiar progreso al reiniciar
          prefsService.clearReadingProgress();
          onRestart?.call();
        },
        onCancel: onCancel,
      ),
      barrierDismissible: false,
    );
  }
}
