import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/debug_console_service.dart';
import '../../core/services/enhanced_tts_service.dart';
import '../../core/services/error_service.dart';
import '../../core/services/reading_progress_service.dart';
import '../../core/services/reading_reminder_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../data/models/documento.dart';
// import '../../global_widgets/interactive_text.dart';

/// Controlador para el lector de documentos simplificado
/// Maneja la lógica de reproducción TTS, seguimiento de progreso y estado de la UI
class SimpleDocumentReaderController extends GetxController {
  // Servicios inyectados
  EnhancedTTSService? _enhancedTTSService;
  TTSService? _baseTTSService;
  ReadingProgressService? _progressService;
  UserPreferencesService? _prefsService;
  ErrorService? _errorService;

  // Controlador de texto interactivo (temporalmente comentado)
  // final InteractiveTextController _textController = InteractiveTextController();
  // InteractiveTextController get textController => _textController;

  // Temporal: crear un textController dummy para compatibilidad
  dynamic get textController => null;

  // Estado del documento
  Documento? _documento;
  Documento? get documento => _documento;

  // Estados reactivos
  final RxBool isPlaying = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxDouble _fontSize = 1.0.obs;

  // Estados reactivos adicionales para compatibilidad
  final RxBool _autoScroll = true.obs;
  final RxBool progressWorking = true.obs;

  // Getters y setters para compatibilidad
  bool get autoScroll => _autoScroll.value;
  set autoScroll(bool value) => _autoScroll.value = value;

  double get fontSize => _fontSize.value;
  set fontSize(double value) => _fontSize.value = value;

  // Getters para compatibilidad
  bool get isTTSAvailable => _enhancedTTSService != null && _baseTTSService != null;
  bool get isDocumentLoaded => _documento != null && _documento!.contenido.isNotEmpty;

  // Información de progreso formateada
  // === NUEVO SISTEMA DE TIEMPO Y PROGRESO ===

  // Variables de tiempo
  DateTime? _playbackStartTime;
  Duration _totalPlaybackTime = Duration.zero;
  Timer? _uiUpdateTimer;

  // Variables de progreso
  int _totalWords = 0;
  int _currentWordIndex = 0;

  // Estados reactivos para UI
  final RxString formattedTime = '0:00'.obs;
  final RxString formattedProgressText = '0%'.obs;
  final RxInt currentWordIndexObs = 0.obs;

  @override
  void onInit() {
    super.onInit();
    DebugLog.i('SimpleDocumentReaderController onInit started', category: LogCategory.tts);

    // Solo inicializar si no está ya inicializado
    if (_enhancedTTSService == null || _baseTTSService == null) {
      // Intentar inicializar inmediatamente
      _initializeServices();
      _setupTTSCallbacks();

      // Reintentar inicialización con delays progresivos
      _retryInitializationWithDelays();
    } else {
      DebugLog.i('TTS services already initialized, skipping initialization', category: LogCategory.tts);
    }
  }

  /// Reintenta la inicialización con delays progresivos
  void _retryInitializationWithDelays() {
    const delays = [
      Duration(milliseconds: 500),
      Duration(milliseconds: 1000),
      Duration(milliseconds: 2000),
      Duration(milliseconds: 3000),
    ];

    for (int i = 0; i < delays.length; i++) {
      Future.delayed(delays[i], () {
        if (_enhancedTTSService == null || _baseTTSService == null) {
          DebugLog.w('Retry ${i + 1}/4: Attempting to initialize TTS services', category: LogCategory.tts);
          _initializeServices();
          _setupTTSCallbacks();
          update();

          if (i == delays.length - 1) {
            DebugLog.e('Failed to initialize TTS services after ${delays.length} attempts', category: LogCategory.tts);
          }
        } else {
          DebugLog.i('TTS services successfully initialized on retry ${i + 1}', category: LogCategory.tts);
        }
      });
    }
  }

  @override
  void onClose() {
    _uiUpdateTimer?.cancel();
    _saveCurrentProgress();
    super.onClose();
  }

  /// Inicializar servicios de forma segura
  void _initializeServices() {
    try {
      // Intentar obtener servicios uno por uno
      if (Get.isRegistered<EnhancedTTSService>()) {
        _enhancedTTSService = Get.find<EnhancedTTSService>();
        DebugLog.d('EnhancedTTSService found', category: LogCategory.tts);
      } else {
        DebugLog.w('EnhancedTTSService not registered', category: LogCategory.tts);
      }

      if (Get.isRegistered<TTSService>()) {
        _baseTTSService = Get.find<TTSService>();
        DebugLog.d('TTSService found', category: LogCategory.tts);
      } else {
        DebugLog.w('TTSService not registered', category: LogCategory.tts);
      }

      if (Get.isRegistered<ReadingProgressService>()) {
        _progressService = Get.find<ReadingProgressService>();
        DebugLog.d('ReadingProgressService found', category: LogCategory.tts);
      }

      if (Get.isRegistered<UserPreferencesService>()) {
        _prefsService = Get.find<UserPreferencesService>();
        DebugLog.d('UserPreferencesService found', category: LogCategory.tts);
      }

      if (Get.isRegistered<ErrorService>()) {
        _errorService = Get.find<ErrorService>();
        DebugLog.d('ErrorService found', category: LogCategory.tts);
      }

      final success = _enhancedTTSService != null && _baseTTSService != null;
      DebugLog.i(
        'Services initialization result: Enhanced=${_enhancedTTSService != null}, Base=${_baseTTSService != null}, Success=$success',
        category: LogCategory.tts,
      );
    } catch (e) {
      DebugLog.e('Error initializing services: $e', category: LogCategory.tts);
    }
  }

  /// Configura los callbacks del TTS
  void _setupTTSCallbacks() {
    DebugLog.i('Setting up TTS callbacks...', category: LogCategory.tts);
    if (_enhancedTTSService == null || _baseTTSService == null) {
      DebugLog.w('TTS Services not available for callbacks setup', category: LogCategory.tts);
      return;
    }

    try {
      // Callback para sincronizar el estado del TTS
      ever(_baseTTSService!.estado.obs, (EstadoTTS estado) {
        DebugLog.d('TTS State changed: $estado', category: LogCategory.tts);

        // Sincronizar el estado del controlador con el estado real del TTS
        final wasPlaying = isPlaying.value;
        isPlaying.value = estado == EstadoTTS.reproduciendo;

        // Log si el estado cambió
        if (wasPlaying != isPlaying.value) {
          DebugLog.d('isPlaying synchronized: $wasPlaying → ${isPlaying.value}', category: LogCategory.tts);
        }

        // Manejar casos especiales
        if (estado == EstadoTTS.completado) {
          _stopPlayback();
        }
      });

      // El progreso ahora se maneja internamente con el timer de UI

      // Callback para el seguimiento de palabras del EnhancedTTSService
      ever(_enhancedTTSService!.currentWordIndexObs, (int wordIndex) {
        if (wordIndex >= 0 && wordIndex < _totalWords) {
          _currentWordIndex = wordIndex;
          currentWordIndexObs.value = wordIndex;
          DebugLog.d('Callback - Word index updated: $wordIndex/$_totalWords', category: LogCategory.tts);
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugLog.i('TTS Callbacks configured successfully', category: LogCategory.tts);
      });
    } catch (e) {
      DebugLog.e('Error setting up TTS callbacks: $e', category: LogCategory.tts);
    }
  }

  /// Carga un documento para lectura
  void loadDocument(Documento doc) {
    _documento = doc;

    // Inicializar variables de progreso
    _totalWords = doc.contenido.split(RegExp(r'\s+')).length;

    // Intentar cargar progreso guardado
    _loadSavedProgress(doc);

    DebugLog.i('Document loaded: ${doc.titulo} - Words: $_totalWords', category: LogCategory.tts);

    // Configurar texto interactivo (temporalmente comentado)
    // _textController.setText(doc.contenido);

    // Iniciar seguimiento de progreso si está disponible
    if (doc.id != null && _progressService != null) {
      _progressService!.startTracking(doc);
    }

    update();
  }

  /// Carga el progreso guardado del documento
  void _loadSavedProgress(Documento doc) {
    DebugLog.i('Loading saved progress for document: ${doc.id}', category: LogCategory.tts);

    if (doc.id == null) {
      // No hay ID, empezar desde cero
      DebugLog.w('No document ID, starting from beginning', category: LogCategory.tts);
      _resetToBeginning();
      return;
    }

    try {
      // Intentar cargar desde UserPreferencesService
      if (_prefsService != null) {
        final savedProgress = _prefsService!.getReadingProgress(doc.id.toString());
        DebugLog.d('UserPreferencesService progress: $savedProgress', category: LogCategory.tts);

        if (savedProgress != null && savedProgress['hasProgress'] == true) {
          final percentage = savedProgress['percentage'] as double;
          final elapsedTime = savedProgress['elapsedTime'] as Duration?;

          // Calcular índice de palabra basado en el porcentaje
          _currentWordIndex = (percentage * _totalWords).round();
          currentWordIndexObs.value = _currentWordIndex;

          // Actualizar UI con progreso guardado
          progress.value = percentage;
          formattedProgressText.value = '${(percentage * 100).round()}%';

          // Restaurar tiempo si está disponible
          if (elapsedTime != null) {
            _totalPlaybackTime = elapsedTime;
            final minutes = elapsedTime.inMinutes;
            final seconds = elapsedTime.inSeconds % 60;
            formattedTime.value = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
          }

          DebugLog.i(
            'Loaded saved progress: ${(percentage * 100).round()}% at word $_currentWordIndex/$_totalWords',
            category: LogCategory.tts,
          );
          return;
        }
      }

      // Intentar cargar desde ReadingProgressService (async)
      if (_progressService != null) {
        DebugLog.d('Trying ReadingProgressService for progress...', category: LogCategory.tts);
        _progressService!
            .getProgress(doc.id!)
            .then((savedProgress) {
              DebugLog.d('ReadingProgressService result: $savedProgress', category: LogCategory.tts);

              if (savedProgress != null) {
                final percentage = savedProgress.porcentajeProgreso;

                // Calcular índice de palabra basado en el porcentaje
                _currentWordIndex = (percentage * _totalWords).round();
                currentWordIndexObs.value = _currentWordIndex;

                // Actualizar UI con progreso guardado
                progress.value = percentage;
                formattedProgressText.value = '${(percentage * 100).round()}%';

                // Restaurar tiempo si está disponible
                _totalPlaybackTime = savedProgress.tiempoReproducido;
                final minutes = savedProgress.tiempoReproducido.inMinutes;
                final seconds = savedProgress.tiempoReproducido.inSeconds % 60;
                formattedTime.value = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

                DebugLog.i(
                  'Loaded saved progress from ReadingProgressService: ${(percentage * 100).round()}% at word $_currentWordIndex/$_totalWords',
                  category: LogCategory.tts,
                );
                update(); // Actualizar UI
              } else {
                DebugLog.w('No progress found in ReadingProgressService', category: LogCategory.tts);
              }
            })
            .catchError((e) {
              DebugLog.e('Error loading progress from ReadingProgressService: $e', category: LogCategory.tts);
            });
      }

      // No hay progreso guardado, empezar desde cero
      DebugLog.w('No saved progress found, starting from beginning', category: LogCategory.tts);
      _resetToBeginning();
    } catch (e) {
      DebugLog.e('Error loading saved progress: $e', category: LogCategory.tts);
      _resetToBeginning();
    }
  }

  /// Resetea todo al principio
  void _resetToBeginning() {
    _currentWordIndex = 0;
    currentWordIndexObs.value = 0;
    progress.value = 0.0;
    formattedTime.value = '0:00';
    formattedProgressText.value = '0%';
    isPlaying.value = false;
    _totalPlaybackTime = Duration.zero;
    DebugLog.i('Reset to beginning - no saved progress found', category: LogCategory.tts);
  }

  /// Alterna reproducción (con soporte para pausa/reanudación)
  Future<void> togglePlayback() async {
    DebugLog.i('togglePlayback called', category: LogCategory.tts);

    // Verificar servicios más robustamente
    if (!Get.isRegistered<EnhancedTTSService>() || !Get.isRegistered<TTSService>()) {
      DebugLog.w('TTS services not registered', category: LogCategory.tts);
      return;
    }

    if (_documento == null) {
      DebugLog.w('No document loaded', category: LogCategory.tts);
      return;
    }

    try {
      final enhancedService = Get.find<EnhancedTTSService>();
      final baseService = Get.find<TTSService>();
      final currentEnhancedState = enhancedService.estado;
      final currentBaseState = baseService.estado;

      DebugLog.d('Current EnhancedTTSService state: $currentEnhancedState', category: LogCategory.tts);
      DebugLog.d('Current TTSService state: $currentBaseState', category: LogCategory.tts);
      DebugLog.d('Controller isPlaying: ${isPlaying.value}', category: LogCategory.tts);

      // Determinar si estamos reproduciendo basado en múltiples fuentes
      final isCurrentlyPlaying =
          isPlaying.value ||
          currentEnhancedState == EstadoTTS.reproduciendo ||
          currentBaseState == EstadoTTS.reproduciendo;

      if (isCurrentlyPlaying) {
        // Pausar
        DebugLog.d('Pausing TTS...', category: LogCategory.tts);
        _pausePlayback(); // Pausar UI primero
        await enhancedService.pausar();
        // Actualizar estado inmediatamente después de pausar
        isPlaying.value = false;
        DebugLog.d('TTS paused - isPlaying set to false', category: LogCategory.tts);
      } else {
        // Reproducir o reanudar
        DebugLog.d('Starting/resuming TTS...', category: LogCategory.tts);

        // Actualizar estado inmediatamente para feedback visual
        isPlaying.value = true;

        if (currentEnhancedState == EstadoTTS.pausado || currentBaseState == EstadoTTS.pausado) {
          DebugLog.d('Resuming from paused state', category: LogCategory.tts);
          await enhancedService.reanudar();
          // Reanudar preservando el tiempo acumulado
          Future.delayed(const Duration(milliseconds: 100), () {
            _resumePlayback();
          });
        } else {
          DebugLog.d('Starting from beginning', category: LogCategory.tts);
          await enhancedService.reproducir(_documento!.contenido);
          // Iniciar desde cero
          Future.delayed(const Duration(milliseconds: 100), () {
            _startPlayback();
          });
        }

        DebugLog.d('TTS started/resumed', category: LogCategory.tts);
      }
    } catch (e) {
      DebugLog.e('Error in togglePlayback: $e', category: LogCategory.tts);
    }
  }

  /// Reproduce desde una palabra específica (compatible con la interfaz)
  Future<void> playFromWord(int wordIndex, [String? word]) async {
    if (!Get.isRegistered<EnhancedTTSService>() || _documento == null) return;

    try {
      final enhancedService = Get.find<EnhancedTTSService>();
      final words = _documento!.contenido.split(RegExp(r'\s+'));
      if (wordIndex >= 0 && wordIndex < words.length) {
        await enhancedService.reproducirDesdePalabra(wordIndex);
        progress.value = wordIndex / words.length;
      }
    } catch (e) {
      DebugLog.e('Error playing from word: $e', category: LogCategory.tts);
    }
  }

  /// Resetea el estado de reproducción
  void resetPlayback() {
    _stopPlayback();
  }

  /// Reinicia la reproducción desde el inicio
  Future<void> restartPlayback() async {
    DebugLog.i('Restarting playback from beginning', category: LogCategory.tts);

    // Detener completamente
    _stopPlayback();

    if (_documento != null && Get.isRegistered<EnhancedTTSService>()) {
      try {
        final enhancedService = Get.find<EnhancedTTSService>();
        await enhancedService.reproducir(_documento!.contenido);

        // Actualizar estado inmediatamente para feedback visual
        isPlaying.value = true;

        // Iniciar desde cero
        Future.delayed(const Duration(milliseconds: 100), () {
          _startPlayback();
        });

        DebugLog.d('Playback restarted successfully - isPlaying set to true', category: LogCategory.tts);
      } catch (e) {
        DebugLog.e('Error restarting playback: $e', category: LogCategory.tts);
      }
    }
  }

  /// Salta a la siguiente palabra
  Future<void> skipToNextWord() async {
    if (!Get.isRegistered<EnhancedTTSService>()) return;
    try {
      final enhancedService = Get.find<EnhancedTTSService>();
      await enhancedService.saltarASiguientePalabra();
    } catch (e) {
      DebugLog.e('Error skipping to next word: $e', category: LogCategory.tts);
    }
  }

  /// Vuelve a la palabra anterior
  Future<void> skipToPreviousWord() async {
    if (!Get.isRegistered<EnhancedTTSService>()) return;
    try {
      final enhancedService = Get.find<EnhancedTTSService>();
      await enhancedService.volverAPalabraAnterior();
    } catch (e) {
      DebugLog.e('Error skipping to previous word: $e', category: LogCategory.tts);
    }
  }

  /// Pausa la reproducción
  Future<void> pausePlayback() async {
    if (!Get.isRegistered<EnhancedTTSService>()) return;
    try {
      final enhancedService = Get.find<EnhancedTTSService>();
      await enhancedService.pausar();
      _pausePlayback(); // Actualizar UI
      isPlaying.value = false; // Actualizar estado directamente
      DebugLog.d('Playback paused via pausePlayback() - isPlaying set to false', category: LogCategory.tts);
    } catch (e) {
      DebugLog.e('Error pausing playback: $e', category: LogCategory.tts);
    }
  }

  /// Reanuda la reproducción
  Future<void> resumePlayback() async {
    if (!Get.isRegistered<EnhancedTTSService>()) return;
    try {
      final enhancedService = Get.find<EnhancedTTSService>();
      await enhancedService.reanudar();
      _resumePlayback(); // Actualizar UI preservando tiempo acumulado
      isPlaying.value = true; // Actualizar estado directamente
      DebugLog.d('Playback resumed via resumePlayback() - isPlaying set to true', category: LogCategory.tts);
    } catch (e) {
      DebugLog.e('Error resuming playback: $e', category: LogCategory.tts);
    }
  }

  /// Guarda el progreso actual (método público)
  Future<void> saveCurrentProgress() async {
    DebugLog.i('Saving current progress...', category: LogCategory.tts);
    _saveCurrentProgress();
  }

  /// Guarda el progreso actual (método privado)
  void _saveCurrentProgress() {
    if (_documento?.id == null) {
      DebugLog.w('Cannot save progress - no document ID', category: LogCategory.tts);
      return;
    }

    try {
      DebugLog.i(
        'Saving progress: ${(progress.value * 100).toStringAsFixed(1)}% at word $_currentWordIndex/$_totalWords, time: $_totalPlaybackTime',
        category: LogCategory.tts,
      );

      // Guardar en ReadingProgressService
      if (_progressService != null) {
        _progressService!.updateProgress(
          documentoId: _documento!.id!,
          progressPercentage: progress.value,
          characterPosition: (progress.value * _documento!.contenido.length).round(),
          elapsedTime: _totalPlaybackTime,
        );
        DebugLog.d('Progress saved to ReadingProgressService', category: LogCategory.tts);

        // Si el documento está completo, limpiar tracking de notificaciones
        if (progress.value >= 0.99) {
          try {
            final reminderService = Get.find<ReadingReminderService>();
            reminderService.clearDocumentTracking(_documento!.id!);
          } catch (e) {
            DebugLog.w('Could not clear document tracking: $e', category: LogCategory.service);
          }
        }
      }

      // Guardar en UserPreferencesService también
      if (_prefsService != null) {
        _prefsService!.saveReadingProgress(
          documentId: _documento!.id!.toString(),
          position: (progress.value * _documento!.contenido.length).round(),
          percentage: progress.value,
          elapsedTime: _totalPlaybackTime, // Agregar tiempo transcurrido
        );
        DebugLog.d('Progress saved to UserPreferencesService', category: LogCategory.tts);
      }

      DebugLog.i('Progress saved successfully', category: LogCategory.tts);
    } catch (e) {
      DebugLog.e('Error saving progress: $e', category: LogCategory.tts);
    }
  }

  /// Inicia el timer de actualización de tiempo
  // === NUEVOS MÉTODOS DE TIEMPO Y PROGRESO ===

  /// Verifica si el timer de UI está activo
  bool get isUITimerActive => _uiUpdateTimer?.isActive ?? false;

  /// Inicia el timer de actualización de UI
  void _startUIUpdater() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateTimeAndProgress();
    });
    DebugLog.d('UI Timer started - Active: ${_uiUpdateTimer?.isActive}', category: LogCategory.tts);
  }

  /// Detiene el timer de actualización de UI
  void _stopUIUpdater() {
    _uiUpdateTimer?.cancel();
    DebugLog.d('UI Timer stopped - Active: ${_uiUpdateTimer?.isActive}', category: LogCategory.tts);
  }

  /// Actualiza tiempo y progreso
  void _updateTimeAndProgress() {
    // Verificar que estamos reproduciendo
    if (!isPlaying.value) {
      DebugLog.d('UI Update skipped - not playing', category: LogCategory.tts);
      return;
    }

    // Actualizar tiempo
    if (_playbackStartTime != null) {
      final elapsed = _totalPlaybackTime + DateTime.now().difference(_playbackStartTime!);
      final minutes = elapsed.inMinutes;
      final seconds = elapsed.inSeconds % 60;
      final newTime = '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

      if (formattedTime.value != newTime) {
        formattedTime.value = newTime;
      }
    }

    // Actualizar progreso basado en palabras
    if (_totalWords > 0) {
      final progressPercent = (_currentWordIndex / _totalWords * 100).round();
      final newProgressText = '$progressPercent%';
      final newProgressValue = _currentWordIndex / _totalWords;

      if (formattedProgressText.value != newProgressText) {
        formattedProgressText.value = newProgressText;
      }

      if ((progress.value - newProgressValue).abs() > 0.001) {
        progress.value = newProgressValue;
      }

      // Debug logging cada segundo para no spamear
      if (DateTime.now().millisecondsSinceEpoch % 1000 < 100) {
        DebugLog.d(
          'UI Update - Word: $_currentWordIndex/$_totalWords, Progress: $progressPercent%, Time: ${formattedTime.value}',
          category: LogCategory.tts,
        );
      }
    }
  }

  /// Inicia la reproducción
  void _startPlayback() {
    _playbackStartTime = DateTime.now();
    _totalPlaybackTime = Duration.zero;
    _startUIUpdater();
    // NO actualizar isPlaying aquí - el callback de estado se encarga
    DebugLog.d('Playback started - UI updater active', category: LogCategory.tts);
  }

  /// Reanuda la reproducción preservando el tiempo acumulado
  void _resumePlayback() {
    _playbackStartTime = DateTime.now();
    // NO resetear _totalPlaybackTime - mantener el tiempo acumulado
    _startUIUpdater();
    DebugLog.d(
      'Playback resumed - UI updater active, total time preserved: $_totalPlaybackTime',
      category: LogCategory.tts,
    );
  }

  /// Pausa la reproducción
  void _pausePlayback() {
    if (_playbackStartTime != null) {
      _totalPlaybackTime += DateTime.now().difference(_playbackStartTime!);
      _playbackStartTime = null;
    }
    _stopUIUpdater();
    // NO actualizar isPlaying aquí - el callback de estado se encarga
    DebugLog.d('Playback paused - UI updater stopped', category: LogCategory.tts);
  }

  /// Detiene la reproducción
  void _stopPlayback() {
    _playbackStartTime = null;
    _totalPlaybackTime = Duration.zero;
    _stopUIUpdater();
    // Actualizar isPlaying para garantizar sincronización
    isPlaying.value = false;
    _currentWordIndex = 0;
    currentWordIndexObs.value = 0;
    progress.value = 0.0;
    formattedTime.value = '0:00';
    formattedProgressText.value = '0%';
    DebugLog.d('Playback stopped - UI reset, isPlaying set to false', category: LogCategory.tts);
  }

  /// Ajusta el tamaño de fuente
  void adjustFontSize(double delta) {
    final newSize = (_fontSize.value + delta).clamp(0.8, 2.0);
    _fontSize.value = newSize;
  }

  /// Auto-reanuda desde notificación
  Future<void> autoResumeFromNotification() async {
    if (_documento != null && Get.isRegistered<EnhancedTTSService>()) {
      try {
        final enhancedService = Get.find<EnhancedTTSService>();
        await enhancedService.reanudar();
        _resumePlayback(); // Preservar tiempo acumulado
        DebugLog.d('Auto-resumed from notification', category: LogCategory.tts);
      } catch (e) {
        DebugLog.e('Error auto-resuming from notification: $e', category: LogCategory.tts);
      }
    }
  }

  /// Reproduce desde la posición guardada
  Future<void> playFromSavedPosition() async {
    DebugLog.i(
      'playFromSavedPosition called - _currentWordIndex: $_currentWordIndex, _totalWords: $_totalWords',
      category: LogCategory.tts,
    );
    DebugLog.i('Current _totalPlaybackTime: $_totalPlaybackTime', category: LogCategory.tts);
    DebugLog.i('Current formattedTime: ${formattedTime.value}', category: LogCategory.tts);

    if (_documento == null || !Get.isRegistered<EnhancedTTSService>()) {
      DebugLog.w('Cannot play from saved position - document or service not available', category: LogCategory.tts);
      return;
    }

    try {
      final enhancedService = Get.find<EnhancedTTSService>();

      // Si ya tenemos una posición cargada, reproducir desde ahí
      if (_currentWordIndex > 0) {
        DebugLog.i('Playing from saved position: word $_currentWordIndex/$_totalWords', category: LogCategory.tts);

        // Usar reproducirDesdePalabra directamente
        try {
          await enhancedService.reproducirDesdePalabra(_currentWordIndex);
          DebugLog.d(
            'Successfully called reproducirDesdePalabra with index $_currentWordIndex',
            category: LogCategory.tts,
          );
        } catch (e) {
          DebugLog.w(
            'reproducirDesdePalabra failed, falling back to normal reproduction: $e',
            category: LogCategory.tts,
          );
          // Fallback: reproducir normalmente
          await enhancedService.reproducir(_documento!.contenido);
        }

        // Actualizar estado inmediatamente para feedback visual
        isPlaying.value = true;

        // Para posición guardada, usar _startPlayback() pero preservando el tiempo acumulado
        _playbackStartTime = DateTime.now();
        // NO resetear _totalPlaybackTime - mantener el tiempo acumulado
        _startUIUpdater();

        DebugLog.i(
          'Started playback from saved position with preserved time: $_totalPlaybackTime',
          category: LogCategory.tts,
        );
      } else {
        // No hay posición guardada, empezar desde el principio
        DebugLog.i('No saved position found, starting from beginning', category: LogCategory.tts);
        await togglePlayback();
      }
    } catch (e) {
      DebugLog.e('Error playing from saved position: $e', category: LogCategory.tts);
      // Fallback: empezar desde el principio
      await togglePlayback();
    }
  }

  /// Información de debug del estado actual
  Map<String, dynamic> get debugInfo {
    return {
      'documentLoaded': _documento != null,
      'documentTitle': _documento?.titulo ?? 'None',
      'isPlaying': isPlaying.value,
      'progress': progress.value,
      'currentWordIndex': _enhancedTTSService?.currentWordIndex ?? -1,
    };
  }

  /// Tiempo transcurrido formateado (reactivo)
  String get formattedElapsedTime => formattedTime.value;

  /// Progreso formateado (reactivo)
  String get formattedProgress => formattedProgressText.value;

  /// Índice de palabra actual (reactivo)
  int get currentWordIndex => currentWordIndexObs.value;

  /// Total de palabras en el documento
  int get totalWords {
    if (_documento?.contenido == null) return 0;
    return _documento!.contenido.split(RegExp(r'\s+')).length;
  }

  /// Verifica el estado de los servicios y muestra información de debug
  void checkServicesStatus() {
    DebugLog.i('=== SERVICES STATUS ===', category: LogCategory.tts);
    DebugLog.i('EnhancedTTSService: ${_enhancedTTSService != null}', category: LogCategory.tts);
    DebugLog.i('TTSService: ${_baseTTSService != null}', category: LogCategory.tts);
    DebugLog.i('ReadingProgressService: ${_progressService != null}', category: LogCategory.tts);
    DebugLog.i('UserPreferencesService: ${_prefsService != null}', category: LogCategory.tts);
    DebugLog.i('ErrorService: ${_errorService != null}', category: LogCategory.tts);

    DebugLog.i('=== GETX REGISTRATION STATUS ===', category: LogCategory.tts);
    DebugLog.i('EnhancedTTSService registered: ${Get.isRegistered<EnhancedTTSService>()}', category: LogCategory.tts);
    DebugLog.i('TTSService registered: ${Get.isRegistered<TTSService>()}', category: LogCategory.tts);
    DebugLog.i(
      'ReadingProgressService registered: ${Get.isRegistered<ReadingProgressService>()}',
      category: LogCategory.tts,
    );
    DebugLog.i(
      'UserPreferencesService registered: ${Get.isRegistered<UserPreferencesService>()}',
      category: LogCategory.tts,
    );
    DebugLog.i('Document: ${_documento?.titulo ?? "No cargado"}', category: LogCategory.tts);
    DebugLog.i('Is Playing: ${isPlaying.value}', category: LogCategory.tts);
    DebugLog.i('Progress: ${progress.value}', category: LogCategory.tts);
    DebugLog.i('Current Word: $currentWordIndex', category: LogCategory.tts);
    DebugLog.i('Formatted Time: $formattedElapsedTime', category: LogCategory.tts);
    DebugLog.i('Formatted Progress: $formattedProgress', category: LogCategory.tts);

    if (_baseTTSService != null) {
      DebugLog.i('Current TTS State: ${_baseTTSService!.estado}', category: LogCategory.tts);
      DebugLog.i('Current TTS Progress: ${_baseTTSService!.progreso}', category: LogCategory.tts);
    }

    DebugLog.i('=== UI STATE ===', category: LogCategory.tts);
    DebugLog.i('isPlaying: ${isPlaying.value}', category: LogCategory.tts);
    DebugLog.i('progress: ${progress.value}', category: LogCategory.tts);
    DebugLog.i('currentWordIndex: ${_enhancedTTSService?.currentWordIndex ?? -1}', category: LogCategory.tts);
    DebugLog.i('UI Timer Active: $isUITimerActive', category: LogCategory.tts);
    DebugLog.i('Playback Start Time: $_playbackStartTime', category: LogCategory.tts);
    DebugLog.i('Total Playback Time: $_totalPlaybackTime', category: LogCategory.tts);
    DebugLog.i('========================', category: LogCategory.tts);
  }

  /// Fuerza la actualización del progreso manualmente (para debug)
  void forceUpdateProgress() {
    if (_baseTTSService != null) {
      final currentProgress = _baseTTSService!.progreso;
      DebugLog.d('Force updating progress: ${(currentProgress * 100).toStringAsFixed(1)}%', category: LogCategory.tts);
      progress.value = currentProgress;
    } else {
      DebugLog.w('BaseTTSService not available for progress update', category: LogCategory.tts);
    }
  }

  /// Fuerza la re-inicialización de servicios
  void forceReinitializeServices() {
    DebugLog.i('Force reinitializing all services...', category: LogCategory.tts);
    _enhancedTTSService = null;
    _baseTTSService = null;
    _progressService = null;
    _prefsService = null;
    _errorService = null;

    _initializeServices();
    _setupTTSCallbacks();
    update();
  }
}
