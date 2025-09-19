import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:te_leo/app/core/services/debug_console_service.dart';
import 'interactive_text.dart';
import '../app/core/services/enhanced_tts_service.dart';
import '../app/core/services/tts_service.dart';
import '../app/data/models/documento.dart';
import 'modern_dialog.dart';

/// Controlador para el lector de documentos
class DocumentReaderController extends GetxController {
  final EnhancedTTSService _ttsService = Get.find<EnhancedTTSService>();
  final InteractiveTextController _textController = InteractiveTextController();
  
  /// Documento actual que se está leyendo
  final Rxn<Documento> _documento = Rxn<Documento>();
  Documento? get documento => _documento.value;
  
  /// Indica si se está reproduciendo
  final RxBool _isPlaying = false.obs;
  bool get isPlaying => _isPlaying.value;
  
  /// Progreso de la reproducción
  final RxDouble _progress = 0.0.obs;
  double get progress => _progress.value;
  
  /// Información de progreso actual
  final Rxn<TTSProgressInfo> _progressInfo = Rxn<TTSProgressInfo>();
  TTSProgressInfo? get progressInfo => _progressInfo.value;
  
  /// Configuración de lectura
  final RxBool _autoScroll = true.obs;
  bool get autoScroll => _autoScroll.value;
  set autoScroll(bool value) => _autoScroll.value = value;
  
  final RxDouble _fontSize = 1.0.obs;
  double get fontSize => _fontSize.value;
  set fontSize(double value) => _fontSize.value = value;

  InteractiveTextController get textController => _textController;

  @override
  void onInit() {
    super.onInit();
    _setupTTSCallbacks();
  }

  @override
  void onClose() {
    _ttsService.clearWordProgressCallback();
    super.onClose();
  }

  /// Configura los callbacks del servicio TTS
  void _setupTTSCallbacks() {
    // Escuchar cambios en el estado del TTS
    ever(_ttsService.estado.obs, (EstadoTTS estado) {
      _isPlaying.value = estado == EstadoTTS.reproduciendo;
    });

    // Escuchar progreso del TTS
    ever(_ttsService.progreso.obs, (double progreso) {
      _progress.value = progreso;
    });

    // Configurar callback de progreso de palabras
    _ttsService.setWordProgressCallback((TTSProgressInfo info) {
      _progressInfo.value = info;
      _textController.setCurrentWord(info.currentWordIndex);
    });
  }

  /// Carga un documento para lectura
  void loadDocument(Documento doc) {
    _documento.value = doc;
    _textController.setText(doc.contenido);
    _resetPlayback();
  }

  /// Inicia o detiene la reproducción
  Future<void> togglePlayback() async {
    try {
      if (_isPlaying.value) {
        await _ttsService.detener();
      } else {
        if (_documento.value != null) {
          DebugLog.i('Starting TTS playback for document: ${_documento.value!.titulo}', category: LogCategory.tts);
          await _ttsService.reproducir(_documento.value!.contenido);
        }
      }
    } catch (e) {
      DebugLog.e('Error in togglePlayback: $e', category: LogCategory.tts);
      Get.snackbar(
        'Error',
        'Error en la reproducción: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
    }
  }

  /// Reproduce desde una palabra específica
  Future<void> playFromWord(int wordIndex, String word) async {
    try {
      await _ttsService.reproducirDesdePalabra(wordIndex);
      
      Get.snackbar(
        'Reproduciendo desde',
        '"$word"',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
      );
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error reproduciendo desde la palabra: $e',
      );
    }
  }

  /// Pausa la reproducción
  Future<void> pausePlayback() async {
    try {
      await _ttsService.pausar();
    } catch (e) {
      DebugLog.e('Error pausando reproducción: $e');
    }
  }

  /// Reanuda la reproducción
  Future<void> resumePlayback() async {
    try {
      await _ttsService.reanudar();
    } catch (e) {
      DebugLog.e('Error reanudando reproducción: $e');
    }
  }

  /// Salta a la siguiente palabra
  Future<void> skipToNextWord() async {
    try {
      await _ttsService.saltarASiguientePalabra();
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error saltando a la siguiente palabra: $e',
      );
    }
  }

  /// Vuelve a la palabra anterior
  Future<void> skipToPreviousWord() async {
    try {
      await _ttsService.volverAPalabraAnterior();
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error volviendo a la palabra anterior: $e',
      );
    }
  }

  /// Reinicia la reproducción desde el inicio
  Future<void> restartPlayback() async {
    _resetPlayback();
    if (_documento.value != null) {
      await _ttsService.reproducir(_documento.value!.contenido);
    }
  }

  /// Resetea el estado de reproducción
  void _resetPlayback() {
    _textController.reset();
    _progressInfo.value = null;
    _progress.value = 0.0;
  }

  /// Ajusta el tamaño de fuente
  void adjustFontSize(double delta) {
    final newSize = (_fontSize.value + delta).clamp(0.8, 2.0);
    _fontSize.value = newSize;
  }

  /// Obtiene información de progreso formateada
  String get formattedProgress {
    final info = _progressInfo.value;
    if (info == null) return '0%';
    
    return '${(info.progressPercentage * 100).round()}%';
  }

  /// Obtiene el tiempo transcurrido formateado
  String get formattedElapsedTime {
    final info = _progressInfo.value;
    if (info == null) return '0:00';
    
    final minutes = info.elapsedTime.inMinutes;
    final seconds = info.elapsedTime.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Widget lector de documentos con texto interactivo y controles TTS
class DocumentReader extends StatelessWidget {
  final Documento documento;
  final bool showControls;
  final bool showProgress;
  final VoidCallback? onClose;

  const DocumentReader({
    super.key,
    required this.documento,
    this.showControls = true,
    this.showProgress = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocumentReaderController>(
      init: DocumentReaderController(),
      initState: (state) {
        state.controller?.loadDocument(documento);
      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              documento.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: onClose ?? () => Get.back(),
              icon: const Icon(Icons.close),
            ),
            actions: [
              // Configuraciones de lectura
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'font_size':
                      _showFontSizeDialog(controller);
                      break;
                    case 'auto_scroll':
                      controller.autoScroll = !controller.autoScroll;
                      break;
                  }
                },
                itemBuilder: (context) => [
                 const PopupMenuItem(
                    value: 'font_size',
                    child: ListTile(
                      leading:  Icon(Icons.text_fields),
                      title:  Text('Tamaño de fuente'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'auto_scroll',
                    child: ListTile(
                      leading: Icon(
                        controller.autoScroll 
                            ? Icons.vertical_align_center
                            : Icons.lock,
                      ),
                      title: Text(
                        controller.autoScroll 
                            ? 'Desactivar auto-scroll'
                            : 'Activar auto-scroll',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Barra de progreso
              if (showProgress)
                Obx(() => _buildProgressBar(controller)),
              
              // Contenido del documento
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Obx(() => InteractiveText(
                    text: documento.contenido,
                    currentWordIndex: controller.textController.currentWordIndex,
                    completedWordIndices: controller.textController.completedWordIndices,
                    onWordTap: controller.playFromWord,
                    textStyle: Get.theme.textTheme.bodyLarge?.copyWith(
                      fontSize: Get.theme.textTheme.bodyLarge!.fontSize! * controller.fontSize,
                      height: 1.6,
                    ),
                    enableSelection: true,
                    enableHighlighting: true,
                  )),
                ),
              ),
              
              // Controles de reproducción
              if (showControls)
                _buildControls(controller),
            ],
          ),
        );
      },
    );
  }

  /// Construye la barra de progreso
  Widget _buildProgressBar(DocumentReaderController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            controller.formattedElapsedTime,
            style: Get.theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: controller.progress,
              backgroundColor: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Get.theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            controller.formattedProgress,
            style: Get.theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Construye los controles de reproducción
  Widget _buildControls(DocumentReaderController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Palabra anterior
          IconButton(
            onPressed: controller.isPlaying 
                ? controller.skipToPreviousWord
                : null,
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Palabra anterior',
          ),
          
          // Reiniciar
          IconButton(
            onPressed: controller.restartPlayback,
            icon: const Icon(Icons.replay),
            tooltip: 'Reiniciar',
          ),
          
          // Play/Pause principal
          Container(
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: controller.togglePlayback,
              icon: Icon(
                controller.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Get.theme.colorScheme.onPrimary,
              ),
              iconSize: 32,
              tooltip: controller.isPlaying ? 'Pausar' : 'Reproducir',
            ),
          ),
          
          // Siguiente palabra
          IconButton(
            onPressed: controller.isPlaying 
                ? controller.skipToNextWord
                : null,
            icon: const Icon(Icons.skip_next),
            tooltip: 'Siguiente palabra',
          ),
          
          // Configuraciones rápidas
          IconButton(
            onPressed: () => _showQuickSettings(controller),
            icon: const Icon(Icons.tune),
            tooltip: 'Configuraciones',
          ),
        ],
      )),
    );
  }

  /// Muestra diálogo de tamaño de fuente
  void _showFontSizeDialog(DocumentReaderController controller) {
    Get.dialog(
      ModernDialog(
        titulo: 'Tamaño de fuente',
        contenidoWidget: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ejemplo de texto con el tamaño actual',
              style: Get.theme.textTheme.bodyLarge?.copyWith(
                fontSize: Get.theme.textTheme.bodyLarge!.fontSize! * controller.fontSize,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Pequeño'),
                Expanded(
                  child: Slider(
                    value: controller.fontSize,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(controller.fontSize * 100).round()}%',
                    onChanged: (value) => controller.fontSize = value,
                  ),
                ),
                const Text('Grande'),
              ],
            ),
          ],
        )),
        textoBotonPrimario: 'Aceptar',
        onBotonPrimario: () => Get.back(),
      ),
    );
  }

  /// Muestra configuraciones rápidas
  void _showQuickSettings(DocumentReaderController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Configuraciones de lectura',
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Auto-scroll
            Obx(() => SwitchListTile(
              title: const Text('Auto-scroll'),
              subtitle: const Text('Seguir automáticamente el texto'),
              value: controller.autoScroll,
              onChanged: (value) => controller.autoScroll = value,
            )),
            
            // Botones de tamaño de fuente
            ListTile(
              title: const Text('Tamaño de fuente'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => controller.adjustFontSize(-0.1),
                    icon: const Icon(Icons.text_decrease),
                  ),
                  Obx(() => Text('${(controller.fontSize * 100).round()}%')),
                  IconButton(
                    onPressed: () => controller.adjustFontSize(0.1),
                    icon: const Icon(Icons.text_increase),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
