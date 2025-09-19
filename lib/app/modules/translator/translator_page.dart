import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'translator_controller.dart';
import '../../../global_widgets/global_widgets.dart';
import '../../core/services/translation_service.dart';
import '../../core/services/tts_service.dart';

/// Página del traductor con OCR
class TranslatorPage extends GetView<TranslatorController> {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('translator_title'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showTranslationHistory(),
            tooltip: 'translation_history'.tr,
          ),
        ],
      ),
      body: Obx(() => _buildBody()),
      floatingActionButton: Obx(() => _buildFloatingActionButton()),
    );
  }

  /// Construye el cuerpo principal según el estado
  Widget _buildBody() {
    switch (controller.state) {
      case TranslatorState.initial:
        return _buildInitialState();
      case TranslatorState.takingPhoto:
      case TranslatorState.extractingText:
      case TranslatorState.translating:
        return _buildLoadingState();
      case TranslatorState.completed:
        return _buildCompletedState();
      case TranslatorState.error:
        return _buildErrorState();
    }
  }

  /// Estado inicial - botones para empezar
  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 80,
              color: Get.theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            
            Text(
              'translator_welcome_title'.tr,
              style: Get.theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'translator_welcome_subtitle'.tr,
              style: Get.theme.textTheme.bodyLarge?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Botón de cámara
            ModernButton(
              text: 'take_photo'.tr,
              onPressed: controller.startTranslationFromCamera,
              icon: Icons.camera_alt,
              type: ModernButtonType.primary,
            ),
            const SizedBox(height: 16),
            
            // Botón de galería
            ModernButton(
              text: 'select_from_gallery'.tr,
              onPressed: controller.startTranslationFromGallery,
              icon: Icons.photo_library,
              type: ModernButtonType.outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            
            Text(
              controller.statusMessage,
              style: Get.theme.textTheme.titleMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (controller.capturedImage != null) ...[
              const SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Get.theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    controller.capturedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Estado completado - mostrar resultados
  Widget _buildCompletedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen capturada
          if (controller.capturedImage != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Get.theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  controller.capturedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Selector de idioma objetivo
          _buildLanguageSelector(),
          const SizedBox(height: 20),

          // Texto original
          _buildTextCard(
            title: 'original_text'.tr,
            subtitle: controller.detectedLanguage != null 
              ? 'detected_language'.trParams({'language': controller.detectedLanguage!.name})
              : null,
            text: controller.originalText,
            language: controller.detectedLanguage,
            onPlay: controller.playOriginalText,
            icon: Icons.source,
          ),
          const SizedBox(height: 16),

          // Texto traducido
          _buildTextCard(
            title: 'translated_text'.tr,
            subtitle: 'confidence'.trParams({'confidence': '${(controller.confidence * 100).round()}%'}),
            text: controller.translatedText,
            language: controller.targetLanguage,
            onPlay: controller.playTranslatedText,
            icon: Icons.translate,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  /// Estado de error
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Get.theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            
            Text(
              'translation_error'.tr,
              style: Get.theme.textTheme.titleLarge?.copyWith(
                color: Get.theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              controller.statusMessage,
              style: Get.theme.textTheme.bodyLarge?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            ModernButton(
              text: 'try_again'.tr,
              onPressed: controller.restart,
              icon: Icons.refresh,
              type: ModernButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye tarjeta de texto
  Widget _buildTextCard({
    required String title,
    String? subtitle,
    required String text,
    required SupportedLanguage? language,
    required VoidCallback onPlay,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return ModernCard(
      child: Container(
        decoration: isPrimary ? BoxDecoration(
          color: Get.theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(
                icon,
                color: isPrimary 
                  ? Get.theme.colorScheme.primary 
                  : Get.theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Get.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPrimary 
                          ? Get.theme.colorScheme.primary 
                          : Get.theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: Get.theme.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              // Botón de reproducir
              IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow),
                style: IconButton.styleFrom(
                  backgroundColor: isPrimary 
                    ? Get.theme.colorScheme.primary 
                    : Get.theme.colorScheme.secondary,
                  foregroundColor: isPrimary 
                    ? Get.theme.colorScheme.onPrimary 
                    : Get.theme.colorScheme.onSecondary,
                ),
                tooltip: 'play_text'.tr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Texto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Get.theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              text,
              style: Get.theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Construye selector de idioma objetivo
  Widget _buildLanguageSelector() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: Get.theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'target_language'.tr,
                style: Get.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botones de idioma
          Row(
            children: SupportedLanguage.values.map((language) {
              final isSelected = language == controller.targetLanguage;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ModernButton(
                    text: '${language.flag} ${language.name}',
                    onPressed: () => controller.changeTargetLanguage(language),
                    type: isSelected 
                      ? ModernButtonType.primary 
                      : ModernButtonType.outlined,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Botón flotante según el estado
  Widget _buildFloatingActionButton() {
    switch (controller.state) {
      case TranslatorState.completed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para guardar como documento
            FloatingActionButton.extended(
              onPressed: controller.saveTranslationAsDocument,
              icon: const Icon(Icons.save),
              label: Text('save_translation'.tr),
              backgroundColor: Get.theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            // Botón para nueva traducción
            FloatingActionButton(
              onPressed: controller.restart,
              child: const Icon(Icons.add),
              backgroundColor: Get.theme.colorScheme.primary,
              tooltip: 'new_translation'.tr,
            ),
          ],
        );
      case TranslatorState.error:
        return FloatingActionButton(
          onPressed: controller.restart,
          child: const Icon(Icons.refresh),
          backgroundColor: Get.theme.colorScheme.error,
          tooltip: 'try_again'.tr,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Muestra historial de traducciones
  void _showTranslationHistory() {
    final translationService = Get.find<TranslationService>();
    final history = translationService.translationHistory;
    
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              'translation_history'.tr,
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            
            if (history.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_translation_history'.tr,
                        style: Get.theme.textTheme.bodyLarge?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final translation = history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(
                          '${translation.sourceLanguage.flag}→${translation.targetLanguage.flag}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          translation.translatedText.length > 50
                            ? '${translation.translatedText.substring(0, 50)}...'
                            : translation.translatedText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${translation.timestamp.day}/${translation.timestamp.month} ${translation.timestamp.hour}:${translation.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            // Reproducir traducción del historial
                            final ttsService = Get.find<TTSService>();
                            final config = ConfiguracionVoz(
                              idioma: '${translation.targetLanguage.code}-${translation.targetLanguage.code.toUpperCase()}',
                            );
                            ttsService.reproducirConConfiguracion(
                              translation.translatedText,
                              config,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
