import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:te_leo/app/data/providers/database_provider.dart';
import '../app/data/models/documento.dart';
import '../app/core/services/tts_service.dart';
import '../app/core/services/enhanced_tts_service.dart';
import '../app/core/services/reading_progress_service.dart';
import '../app/core/services/user_preferences_service.dart';
import '../app/core/services/error_service.dart';
import '../app/core/services/debug_console_service.dart';
import 'resume_reading_dialog.dart';
import 'interactive_text.dart';

/// Lector de documentos simplificado pero funcional
class SimpleDocumentReader extends StatelessWidget {
  final Documento documento;
  final bool showControls;
  final VoidCallback? onClose;
  final bool autoResumeFromNotification;

  const SimpleDocumentReader({
    super.key,
    required this.documento,
    this.showControls = true,
    this.onClose,
    this.autoResumeFromNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SimpleDocumentReaderController>(
      init: SimpleDocumentReaderController(),
      initState: (state) {
        // Cargar documento después de que el controller esté completamente inicializado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.controller?.loadDocument(documento);
          
          // Si viene desde notificación, auto-reanudar
          if (autoResumeFromNotification) {
            state.controller?.autoResumeFromNotification();
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
            title: Text(
              documento.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => _handleExit(controller),
              icon: const Icon(Icons.close),
            ),
            actions: const [
              
            ],
          ),
          body: Column(
            children: [
              // Barra de progreso
              if (showControls)
                _buildProgressBar(controller),
              
              // Contenido del documento con texto interactivo
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GetBuilder<SimpleDocumentReaderController>(
                    builder: (controller) => controller.isDocumentLoaded 
                      ? Obx(() {
                          // Forzar reactividad del currentWordIndex
                          final wordIndex = controller.currentWordIndex;
                          return InteractiveText(
                            text: controller.documento!.contenido,
                            currentWordIndex: wordIndex,
                            textStyle: Get.theme.textTheme.bodyLarge?.copyWith(
                              fontSize: Get.theme.textTheme.bodyLarge!.fontSize! * controller.fontSize.value,
                              height: 1.6,
                            ),
                            onWordTap: (wordIndex, word) {
                              controller.jumpToWord(wordIndex);
                            },
                            enableSelection: true,
                            enableHighlighting: true,
                          );
                        })
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Cargando documento...'),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
              
              // Controles de reproducción
              if (showControls)
                _buildControls(controller),
                
              // Mensaje si TTS no está disponible
              if (showControls && !controller.isTTSAvailable)
                _buildTTSUnavailableMessage(controller),
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
        border: Border(
          bottom: BorderSide(
            color: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Obx(() => Row(
        children: [
          Text(
            controller.formattedElapsedTime,
            style: Get.theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: controller.progress.value,
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
      )),
    );
  }

  /// Construye los controles de reproducción
  Widget _buildControls(SimpleDocumentReaderController controller) {
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
          // Reiniciar
          IconButton(
            onPressed: controller.restartPlayback,
            icon: const Icon(Icons.replay),
            tooltip: 'restart'.tr,
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
                controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                color: Get.theme.colorScheme.onPrimary,
              ),
              iconSize: 32,
              tooltip: controller.isPlaying.value ? 'pause'.tr : 'play'.tr,
            ),
          ),
          
          // Configuraciones rápidas
          IconButton(
            onPressed: () => _showQuickSettings(controller),
            icon: const Icon(Icons.tune),
            tooltip: 'settings'.tr,
          ),
        ],
      )),
    );
  }


  /// Muestra configuraciones rápidas
  void _showQuickSettings(SimpleDocumentReaderController controller) {
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
            
            // Progreso de lectura
            Obx(() => ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Progreso de lectura'),
              subtitle: Text('${(controller.progress.value * 100).round()}% completado'),
              trailing: Text(
                '${controller.currentWordIndex + 1}/${controller.totalWords}',
                style: Get.theme.textTheme.bodySmall,
              ),
            )),
            
            const Divider(),
            
            // Botones de tamaño de fuente
            ListTile(
              leading: const Icon(Icons.format_size),
              title: const Text('Tamaño de fuente'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => controller.adjustFontSize(-0.1),
                    icon: const Icon(Icons.remove),
                    tooltip: 'Reducir texto',
                  ),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(controller.fontSize.value * 100).round()}%',
                      style: TextStyle(
                        color: Get.theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  IconButton(
                    onPressed: () => controller.adjustFontSize(0.1),
                    icon: const Icon(Icons.add),
                    tooltip: 'Aumentar texto',
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

  /// Construye mensaje cuando TTS no está disponible
  Widget _buildTTSUnavailableMessage(SimpleDocumentReaderController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.volume_off,
            color: Get.theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'error_tts_not_available'.tr,
            style: Get.theme.textTheme.titleMedium?.copyWith(
              color: Get.theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              controller.reinitializeServices();
            },
            icon: const Icon(Icons.refresh),
            label: Text('retry'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  /// Maneja la salida del lector
  Future<void> _handleExit(SimpleDocumentReaderController controller) async {
    // SIEMPRE detener TTS al salir (incluso si no está reproduciendo visualmente)
    await controller.stopTTSOnExit();
    
    // Pequeña pausa para asegurar que el TTS se detenga completamente
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Ejecutar callback personalizado o navegar atrás
    if (onClose != null) {
      onClose!();
    } else {
      Get.back();
    }
  }
}

/// Controlador simplificado para el lector de documentos
class SimpleDocumentReaderController extends GetxController {
  EnhancedTTSService? _enhancedTTSService;
  TTSService? _baseTTSService;
  ReadingProgressService? _progressService;
  UserPreferencesService? _prefsService;
  ErrorService? _errorService;
  
  /// Documento actual
  Documento? _documento;
  Documento? get documento => _documento;
  
  /// Estados reactivos
  final RxBool isPlaying = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxDouble fontSize = 1.0.obs;
  
  /// Getter para el índice de palabra actual (reactivo)
  int get currentWordIndex {
    // Acceder al RxInt directamente para que Obx detecte cambios
    final index = _enhancedTTSService?.currentWordIndexObs.value ?? -1;
    // Logging para debugging (solo si cambió)
    if (index != _lastLoggedWordIndex) {
      _lastLoggedWordIndex = index;
      DebugLog.d('Current word index: $index', category: LogCategory.tts);
    }
    return index;
  }
  
  int _lastLoggedWordIndex = -2; // Para detectar cambios
  
  /// Tiempo de inicio y progreso
  DateTime? _startTime;
  Duration _totalElapsedTime = Duration.zero;
  
  /// Timer para actualizar el tiempo transcurrido
  Timer? _timeUpdateTimer;
  
  /// Tiempo transcurrido reactivo
  final RxString _formattedTime = '0:00'.obs;

  /// Tiempo ya guardado en estadísticas (para evitar duplicados)
  Duration _savedListeningTime = Duration.zero;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _setupTTSCallbacks();
    
    // Reintentar inicialización después de un delay si es necesario
    if (_enhancedTTSService == null || _baseTTSService == null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _initializeServices();
        _setupTTSCallbacks();
        forceUpdateUI(); // Forzar actualización de la UI
      });
      
      // Segundo intento si aún no están disponibles
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (_enhancedTTSService == null || _baseTTSService == null) {
          _initializeServices();
          _setupTTSCallbacks();
          forceUpdateUI();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DebugLog.w('Second attempt to initialize TTS services', category: LogCategory.tts);
          });
        }
      });
    }
  }

  @override
  void onClose() {
    // Detener timer y TTS cuando se cierra el controller
    _stopTimeUpdater();
    stopTTSOnExit();
    super.onClose();
  }

  /// Detiene el TTS al salir del lector
  Future<void> stopTTSOnExit() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i('Stopping TTS on document reader exit...', category: LogCategory.tts);
      });

      // Guardar progreso final antes de salir
      await _saveCurrentProgress();
      
      // Usar métodos más agresivos para detener COMPLETAMENTE
      if (_baseTTSService != null) {
        await _baseTTSService!.stopAll();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DebugLog.d('Base TTS service stopped completely', category: LogCategory.tts);
        });
      }
      
      if (_enhancedTTSService != null) {
        await _enhancedTTSService!.stopAll();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DebugLog.d('Enhanced TTS service stopped completely', category: LogCategory.tts);
        });
      }
      
      // Detener timer y forzar actualización del estado local
      _stopTimeUpdater();
      isPlaying.value = false;
      progress.value = 0.0;
      _startTime = null;
      _totalElapsedTime = Duration.zero;
      _formattedTime.value = '0:00';
      
      // Pausa adicional para asegurar que se detenga
      await Future.delayed(const Duration(milliseconds: 200));
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i('TTS COMPLETELY stopped on document reader exit', category: LogCategory.tts);
      });
      
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.e('Error stopping TTS on exit: $e', category: LogCategory.tts);
      });
      
      // Forzar estado detenido aunque haya error
      isPlaying.value = false;
      progress.value = 0.0;
      _startTime = null;
    }
  }

  /// Inicializar servicios de forma segura
  void _initializeServices() {
    try {
      _enhancedTTSService = Get.find<EnhancedTTSService>();
      _baseTTSService = Get.find<TTSService>();
      _progressService = Get.find<ReadingProgressService>();
      _prefsService = Get.find<UserPreferencesService>();
      _errorService = Get.find<ErrorService>();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.w('Some services not available yet in SimpleDocumentReader', category: LogCategory.app);
      });
    }
  }

  /// Configura los callbacks del TTS
  void _setupTTSCallbacks() {
    if (_enhancedTTSService == null || _baseTTSService == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.w('TTS Services not available for callbacks setup', category: LogCategory.tts);
      });
      return;
    }
    
    try {
      // Usar el servicio base para el estado general
      ever(_baseTTSService!.estado.obs, (EstadoTTS estado) {
        DebugLog.d('TTS State changed: $estado', category: LogCategory.tts);
        
        // Actualizar inmediatamente el estado de reproducción
        isPlaying.value = estado == EstadoTTS.reproduciendo;
        
        if (estado == EstadoTTS.reproduciendo) {
          if (_startTime == null) {
            _startTime = DateTime.now();
          }
          _startTimeUpdater(); // Iniciar timer de actualización
        } else if (estado == EstadoTTS.detenido) {
          _stopTimeUpdater(); // Detener timer
          _saveCurrentProgress();
          if (_startTime != null) {
            _totalElapsedTime += DateTime.now().difference(_startTime!);
            _startTime = null;
          }
          _updateFormattedTime(); // Actualizar tiempo final
        } else if (estado == EstadoTTS.pausado) {
          _stopTimeUpdater(); // Detener timer pero mantener _startTime para reanudar
          _saveCurrentProgress();
          if (_startTime != null) {
            _totalElapsedTime += DateTime.now().difference(_startTime!);
            // NO resetear _startTime para poder reanudar correctamente
          }
          _updateFormattedTime(); // Actualizar tiempo actual
        } else if (estado == EstadoTTS.completado) {
          _stopTimeUpdater(); // Detener timer
          _markAsCompleted();
          _startTime = null;
          progress.value = 1.0;
          _updateFormattedTime(); // Actualizar tiempo final
        }
      });

      // Usar el servicio avanzado para el progreso detallado
      ever(_enhancedTTSService!.progreso.obs, (double progreso) {
        DebugLog.d('TTS Progress: ${(progreso * 100).toStringAsFixed(1)}%', category: LogCategory.tts);
        progress.value = progreso;
        _saveCurrentProgress(); // Guardar progreso en tiempo real
      });
      
      // Callback adicional para el progreso de palabras del EnhancedTTSService
      ever(_enhancedTTSService!.currentWordIndexObs, (int wordIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DebugLog.d('Current word index: $wordIndex', category: LogCategory.tts);
        });
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i('TTS Callbacks configured successfully', category: LogCategory.tts);
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.e('Error setting up TTS callbacks: $e', category: LogCategory.tts);
      });
    }
  }

  /// Guarda el progreso actual
  Future<void> _saveCurrentProgress() async {
    if (_documento?.id == null || _progressService?.isActive != true) return;
    
    try {
      final currentElapsed = _totalElapsedTime + 
          (_startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero);
      
      // Guardar en ReadingProgressService (tradicional)
      if (_progressService != null) {
        await _progressService!.updateProgress(
          documentoId: _documento!.id!,
          progressPercentage: progress.value,
          characterPosition: (progress.value * _documento!.contenido.length).round(),
          elapsedTime: currentElapsed,
        );
      }
      
      // Guardar en SharedPreferences (persistente)
      if (_prefsService != null) {
        await _prefsService!.saveReadingProgress(
          documentId: _documento!.id?.toString() ?? '',
          position: (progress.value * _documento!.contenido.length).round(),
          percentage: progress.value,
        );
      }
      
      // Actualizar tiempo total de escucha con solo el tiempo nuevo
      if (currentElapsed.inSeconds > 30 && _prefsService != null) {
        final tiempoNuevo = currentElapsed - _savedListeningTime;
        final minutosNuevos = tiempoNuevo.inMinutes;
        
        if (minutosNuevos > 0) {
          await _prefsService!.addListeningTime(minutosNuevos);
          _savedListeningTime = currentElapsed; // Actualizar tiempo guardado
          DebugLog.i('Added $minutosNuevos new minutes to listening stats (total: ${currentElapsed.inMinutes})', category: LogCategory.service);
        }
      }
      
    } catch (e) {
      DebugLog.e('Error guardando progreso: $e', category: LogCategory.service);
    }
  }

  /// Marca el documento como completado
  Future<void> _markAsCompleted() async {
    if (_documento?.id == null || _progressService == null) return;
    
    try {
      await _progressService!.markAsCompleted(_documento!.id!);
    } catch (e) {
      DebugLog.e('Error marcando como completado: $e');
    }
  }

  /// Carga un documento e inicia seguimiento de progreso
  Future<void> loadDocument(Documento doc) async {
    if (doc.titulo.isEmpty || doc.contenido.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.e('Cannot load document: title or content is empty', category: LogCategory.ui);
      });
      return;
    }
    
    _documento = doc;
    progress.value = 0.0;
    _startTime = null;
    _totalElapsedTime = Duration.zero;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLog.i('Document loaded successfully: ${doc.titulo} (${doc.contenido.length} chars)', category: LogCategory.ui);
    });
    
    // Forzar actualización del widget
    update();
    
    // Verificar progreso en SharedPreferences
    final savedProgress = _prefsService?.getReadingProgress(doc.id?.toString() ?? '');
    if (savedProgress != null && savedProgress['hasProgress'] == true) {
      // Mostrar dialog para resumir o reiniciar
      ResumeReadingDialog.show(
        documentId: doc.id?.toString() ?? '',
        documentTitle: doc.titulo,
        onResume: () {
          final percentage = savedProgress['percentage'] as double;
          progress.value = percentage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DebugLog.i('Resuming from ${(percentage * 100).toStringAsFixed(1)}%', category: LogCategory.ui);
          });
        },
        onRestart: () {
          progress.value = 0.0;
          _prefsService?.clearReadingProgress();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DebugLog.i('Starting from beginning', category: LogCategory.ui);
          });
        },
      );
    }
    
    // También iniciar seguimiento tradicional
    if (doc.id != null && _progressService != null) {
      await _progressService!.startTracking(doc);
    }
  }

  /// Alterna reproducción (con soporte para pausa/reanudación)
  Future<void> togglePlayback() async {
    if (_enhancedTTSService == null || _baseTTSService == null) {
      DebugLog.e('TTS Services not available for playback', category: LogCategory.tts);
      return;
    }
    
    try {
      final currentState = _baseTTSService!.estado;
      DebugLog.d('BEFORE Toggle - isPlaying: ${isPlaying.value}, TTS State: $currentState', category: LogCategory.tts);
      
      if (isPlaying.value || currentState == EstadoTTS.reproduciendo) {
        // Pausar (no detener completamente)
        DebugLog.d('Pausing TTS...', category: LogCategory.tts);
        await _enhancedTTSService!.pausar();
        
        // Actualizar estado UI
        isPlaying.value = false;
        _stopTimeUpdater();
        _updateFormattedTime();
        
        DebugLog.d('TTS paused - state updated', category: LogCategory.tts);
      } else {
        // Reproducir o reanudar
        if (_documento != null) {
          // Verificar si hay contenido pausado para reanudar
          if (currentState == EstadoTTS.pausado) {
            DebugLog.d('Resuming TTS from pause...', category: LogCategory.tts);
            await _enhancedTTSService!.reanudar();
          } else {
            DebugLog.d('Starting TTS playback from beginning...', category: LogCategory.tts);
            await _enhancedTTSService!.reproducir(_documento!.contenido);
          }
          
          // Actualizar estado UI
          isPlaying.value = true;
          // Reiniciar el tiempo cuando se reanuda (se había pausado el timer)
          _startTime = DateTime.now();
          _startTimeUpdater();
          
          DebugLog.d('TTS playback started/resumed - state updated', category: LogCategory.tts);
        } else {
          DebugLog.e('No document available for playback', category: LogCategory.tts);
        }
      }
      
      DebugLog.d('AFTER Toggle - isPlaying: ${isPlaying.value}, TTS State: ${_baseTTSService!.estado}', category: LogCategory.tts);
      
    } catch (e) {
      DebugLog.e('Error in TTS playback: $e', category: LogCategory.tts);
      if (_errorService != null) {
        await _errorService!.handleTTSError(e, contexto: 'Lector de documentos');
      }
    }
  }

  /// Reinicia la reproducción
  Future<void> restartPlayback() async {
    if (_enhancedTTSService == null || _documento == null) return;
    
    // Detener primero
    await _baseTTSService?.detener();
    
    // Resetear progreso y tiempo
    _stopTimeUpdater();
    progress.value = 0.0;
    _startTime = null;
    _totalElapsedTime = Duration.zero;
    _formattedTime.value = '0:00';
    
    // Iniciar desde el principio
    await _enhancedTTSService!.reproducir(_documento!.contenido);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLog.d('Playbook restarted', category: LogCategory.tts);
    });
  }
  
  /// Fuerza la actualización del estado del UI
  void forceUpdateUI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update(); // Forzar rebuild del GetBuilder
    });
  }
  
  /// Auto-reanuda la lectura cuando viene desde una notificación
  Future<void> autoResumeFromNotification() async {
    if (_documento?.id == null) return;
    
    try {
      // Buscar progreso guardado
      final progreso = await DatabaseProvider().obtenerProgresoLectura(_documento!.id!);
      
      if (progreso != null && progreso.porcentajeProgreso > 0.05) {
        DebugLog.i('Auto-resuming from notification at ${(progreso.porcentajeProgreso * 100).toStringAsFixed(1)}%', 
                  category: LogCategory.navigation);
        
        // Calcular índice de palabra desde el progreso
        final words = _documento!.contenido.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
        final wordIndex = (progreso.porcentajeProgreso * words.length).floor().clamp(0, words.length - 1);
        
        // Pequeña pausa para asegurar que todo esté inicializado
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Saltar a la posición guardada y comenzar reproducción
        await jumpToWord(wordIndex);
        
        DebugLog.i('Auto-resumed from word $wordIndex', category: LogCategory.navigation);
      }
    } catch (e) {
      DebugLog.e('Error auto-resuming from notification: $e', category: LogCategory.service);
    }
  }

  /// Ajusta el tamaño de fuente
  void adjustFontSize(double delta) {
    final newSize = (fontSize.value + delta).clamp(0.8, 2.0);
    fontSize.value = newSize;
  }

  /// Salta a una palabra específica en el texto
  Future<void> jumpToWord(int wordIndex) async {
    if (_enhancedTTSService == null || _documento == null) return;
    
    try {
      DebugLog.d('Jumping to word $wordIndex', category: LogCategory.tts);
      
      // Detener reproducción actual
      await _baseTTSService?.detener();
      
      // Calcular progreso y tiempo basado en la palabra
      final words = _documento!.contenido.split(' ');
      if (words.isNotEmpty && wordIndex < words.length) {
        // Calcular progreso
        progress.value = wordIndex / words.length;
        
        // Estimar tiempo transcurrido basado en progreso
        // Asumiendo velocidad promedio de lectura: ~150 palabras por minuto
        const wordsPerMinute = 150.0;
        const secondsPerWord = 60.0 / wordsPerMinute; // ~0.4 segundos por palabra
        
        final estimatedSeconds = (wordIndex * secondsPerWord).round();
        _totalElapsedTime = Duration(seconds: estimatedSeconds);
        
        // Resetear tiempo de inicio para continuar desde este punto
        _startTime = DateTime.now();
        
        // Forzar actualización inmediata del estado
        isPlaying.value = true;
        _startTimeUpdater(); // Iniciar timer desde el nuevo tiempo
        
        DebugLog.d('Time adjusted to ${_totalElapsedTime.inMinutes}:${(_totalElapsedTime.inSeconds % 60).toString().padLeft(2, '0')}', category: LogCategory.tts);
      }
      
      // Reproducir desde la palabra específica
      await _enhancedTTSService!.reproducirDesdePalabra(wordIndex);
      
      // Forzar actualización del UI para highlighting inmediato
      forceUpdateUI();
      
      DebugLog.i('Jumped to word $wordIndex, time: ${formattedElapsedTime}', category: LogCategory.tts);
      
    } catch (e) {
      DebugLog.e('Error jumping to word: $e', category: LogCategory.tts);
    }
  }

  /// Reinicializar servicios si no están disponibles
  void reinitializeServices() {
    _initializeServices();
    if (_enhancedTTSService != null && _baseTTSService != null) {
      _setupTTSCallbacks();
    }
  }

  /// Verificar si el TTS está disponible
  bool get isTTSAvailable => _enhancedTTSService != null && _baseTTSService != null;

  /// Verificar si el documento está cargado
  bool get isDocumentLoaded => _documento != null && _documento!.contenido.isNotEmpty;

  /// Información de debug del estado actual
  Map<String, dynamic> get debugInfo => {
    'documentLoaded': isDocumentLoaded,
    'documentTitle': _documento?.titulo ?? 'null',
    'documentContentLength': _documento?.contenido.length ?? 0,
    'enhancedTTSAvailable': _enhancedTTSService != null,
    'baseTTSAvailable': _baseTTSService != null,
    'ttsAvailable': isTTSAvailable,
    'progressServiceAvailable': _progressService != null,
    'prefsServiceAvailable': _prefsService != null,
    'errorServiceAvailable': _errorService != null,
    'isPlaying': isPlaying.value,
    'progress': progress.value,
    'currentWordIndex': _enhancedTTSService?.currentWordIndex ?? -1,
  };

  /// Progreso formateado
  String get formattedProgress {
    return '${(progress.value * 100).round()}%';
  }

  /// Tiempo transcurrido formateado (reactivo)
  String get formattedElapsedTime => _formattedTime.value;

  /// Total de palabras en el documento
  int get totalWords => _enhancedTTSService?.totalWords ?? 0;

  
  /// Inicia el timer para actualizar el tiempo
  void _startTimeUpdater() {
    _stopTimeUpdater(); // Detener timer anterior si existe
    
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateFormattedTime();
    });
    
    // Actualizar inmediatamente
    _updateFormattedTime();
  }
  
  /// Detiene el timer de actualización de tiempo
  void _stopTimeUpdater() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = null;
  }
  
  /// Actualiza el tiempo formateado
  void _updateFormattedTime() {
    if (_startTime == null) {
      _formattedTime.value = '0:00';
      return;
    }
    
    final elapsed = _totalElapsedTime + DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    _formattedTime.value = '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  
  /// Fuerza la actualización del resaltado de palabras
  void forceWordHighlightUpdate() {
    if (_enhancedTTSService != null) {
      final currentIndex = _enhancedTTSService!.currentWordIndex;
      DebugLog.d('Forcing word highlight update - current index: $currentIndex', category: LogCategory.tts);
      // Esto forzará la reactividad del getter currentWordIndex
      update();
    }
  }
}
