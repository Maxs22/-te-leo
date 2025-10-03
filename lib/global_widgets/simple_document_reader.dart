import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/core/config/app_config.dart';
import '../app/data/models/documento.dart';
import '../app/modules/document_reader/simple_document_reader_controller.dart';
import 'ads/ads_exports.dart';
import 'interactive_text.dart';
import '../app/core/services/ads_strategy_service.dart';

/// Lector de documentos simplificado pero funcional
class SimpleDocumentReader extends StatelessWidget {
  final Documento documento;
  final bool showControls;
  final VoidCallback? onClose;
  final bool autoResumeFromNotification;
  final bool autoResumeFromSavedPosition;

  const SimpleDocumentReader({
    super.key,
    required this.documento,
    this.showControls = true,
    this.onClose,
    this.autoResumeFromNotification = false,
    this.autoResumeFromSavedPosition = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SimpleDocumentReaderController>(
      init: Get.put(SimpleDocumentReaderController(), permanent: true),
      initState: (state) {
        // Cargar documento después de que el controller esté completamente inicializado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.controller?.loadDocument(documento);

          // Si viene desde notificación, auto-reanudar
          if (autoResumeFromNotification) {
            state.controller?.autoResumeFromNotification();
          }

          // Si viene desde modal de continuar lectura, auto-reanudar desde posición guardada
          if (autoResumeFromSavedPosition) {
            Future.delayed(const Duration(milliseconds: 500), () {
              state.controller?.playFromSavedPosition();
            });
          }
        });
      },
      builder: (controller) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _handleExit(controller);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(documento.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
              centerTitle: true,
              leading: IconButton(onPressed: () => _handleExit(controller), icon: const Icon(Icons.close)),
              actions: [
                // Botones de debug solo en desarrollo
                if (AppConfig.showDebugButtons) ...[
                  // Botón de debug
                  IconButton(
                    onPressed: () => controller.checkServicesStatus(),
                    icon: const Icon(Icons.bug_report),
                    tooltip: 'debug_info'.tr,
                  ),
                ],
                // Configuraciones de lectura
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'font_size':
                        _showFontSizeDialog(controller);
                        break;
                      case 'debug':
                        if (AppConfig.showDebugButtons) {
                          controller.checkServicesStatus();
                        }
                        break;
                      case 'reinit':
                        if (AppConfig.showDebugButtons) {
                          controller.forceReinitializeServices();
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'font_size',
                      child: ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text('font_size'.tr),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    // Elementos de debug solo en desarrollo
                    if (AppConfig.showDebugButtons) ...[
                      PopupMenuItem(
                        value: 'debug',
                        child: ListTile(
                          leading: const Icon(Icons.bug_report),
                          title: Text('debug_info'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reinit',
                        child: ListTile(
                          leading: const Icon(Icons.refresh),
                          title: Text('reinitialize_services'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Barra de progreso
                _buildProgressBar(controller),

                // Contenido del documento
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Obx(
                      () => InteractiveText(
                        text: documento.contenido,
                        currentWordIndex: controller.currentWordIndex,
                        completedWordIndices: const <int>{},
                        onWordTap: (wordIndex, word) => controller.playFromWord(wordIndex),
                        textStyle: Get.theme.textTheme.bodyLarge?.copyWith(
                          fontSize: Get.theme.textTheme.bodyLarge!.fontSize! * controller.fontSize,
                          height: 1.6,
                        ),
                        enableSelection: true,
                        enableHighlighting: true,
                      ),
                    ),
                  ),
                ),

                // Banner Ad antes de los controles
                const BannerAdWidget(margin: EdgeInsets.symmetric(vertical: 8)),

                // Controles de reproducción
                if (showControls) _buildControls(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye la barra de progreso
  Widget _buildProgressBar(SimpleDocumentReaderController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: Get.theme.colorScheme.outline.withValues(alpha: 0.2))),
      ),
      child: Obx(() {
        final progressValue = controller.progress.value;
        final formattedProgress = controller.formattedProgress;
        final formattedTime = controller.formattedElapsedTime;

        return Row(
          children: [
            Text(formattedTime, style: Get.theme.textTheme.bodySmall),
            const SizedBox(width: 12),
            Expanded(
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Get.theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(formattedProgress, style: Get.theme.textTheme.bodySmall),
          ],
        );
      }),
    );
  }

  /// Construye los controles de reproducción
  Widget _buildControls(SimpleDocumentReaderController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Get.theme.colorScheme.outline.withValues(alpha: 0.2))),
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Palabra anterior
            IconButton(
              onPressed: controller.isPlaying.value ? controller.skipToPreviousWord : null,
              icon: const Icon(Icons.skip_previous),
              tooltip: 'previous_word'.tr,
            ),

            // Reiniciar
            IconButton(
              onPressed: () => controller.restartPlayback(),
              icon: const Icon(Icons.replay),
              tooltip: 'restart_button'.tr,
            ),

            // Play/Pause principal
            Container(
              decoration: BoxDecoration(color: Get.theme.colorScheme.primary, shape: BoxShape.circle),
              child: IconButton(
                onPressed: controller.togglePlayback,
                icon: Icon(
                  controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                  color: Get.theme.colorScheme.onPrimary,
                ),
                iconSize: 32,
                tooltip: controller.isPlaying.value ? 'pause'.tr : 'play'.tr,
              ),
            ),

            // Palabra siguiente
            IconButton(
              onPressed: controller.isPlaying.value ? controller.skipToNextWord : null,
              icon: const Icon(Icons.skip_next),
              tooltip: 'next_word'.tr,
            ),

            // Configuraciones rápidas
            IconButton(
              onPressed: () => _showQuickSettings(controller),
              icon: const Icon(Icons.tune),
              tooltip: 'settings'.tr,
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra diálogo de tamaño de fuente
  void _showFontSizeDialog(SimpleDocumentReaderController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('font_size'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => Slider(
                value: controller.fontSize,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                label: '${(controller.fontSize * 100).round()}%',
                onChanged: (value) {
                  controller.fontSize = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: () => controller.adjustFontSize(-0.1), icon: const Icon(Icons.remove)),
                Obx(() => Text('${(controller.fontSize * 100).round()}%')),
                IconButton(onPressed: () => controller.adjustFontSize(0.1), icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Get.back(), child: Text('close'.tr))],
      ),
    );
  }

  /// Muestra configuraciones rápidas
  void _showQuickSettings(SimpleDocumentReaderController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('settings'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text('font_size'.tr),
              onTap: () {
                Get.back();
                _showFontSizeDialog(controller);
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Get.back(), child: Text('close'.tr))],
      ),
    );
  }

  /// Maneja la salida del lector
  Future<void> _handleExit(SimpleDocumentReaderController controller) async {
    // Pausar reproducción antes de salir
    if (controller.isPlaying.value) {
      await controller.togglePlayback();
    }

    // Guardar progreso antes de salir
    await controller.saveCurrentProgress();

    // Mostrar anuncio intersticial si el usuario terminó de leer (progreso > 90%)
    if (controller.progress.value > 0.9) {
      try {
        final adsStrategy = Get.find<AdsStrategyService>();
        await adsStrategy.showInterstitialOnChapterComplete();
      } catch (e) {
        // Si no está disponible el servicio, continuar sin mostrar anuncio
        debugPrint('AdsStrategyService not available: $e');
      }
    }

    if (onClose != null) {
      onClose!();
    } else {
      Get.back();
    }
  }
}
