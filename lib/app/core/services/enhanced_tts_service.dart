import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:te_leo/app/core/services/debug_console_service.dart';
import 'tts_service.dart';

/// Información de progreso de TTS con seguimiento de palabras
class TTSProgressInfo {
  final String fullText;
  final int currentCharacterIndex;
  final int currentWordIndex;
  final String currentWord;
  final double progressPercentage;
  final Duration elapsedTime;

  const TTSProgressInfo({
    required this.fullText,
    required this.currentCharacterIndex,
    required this.currentWordIndex,
    required this.currentWord,
    required this.progressPercentage,
    required this.elapsedTime,
  });
}

/// Servicio TTS mejorado con seguimiento de palabras y control granular
class EnhancedTTSService extends GetxService {
  final TTSService _baseTTSService = Get.find<TTSService>();
  
  /// Callback para progreso de palabras
  Function(TTSProgressInfo)? _onWordProgress;
  Function(TTSProgressInfo)? get onWordProgress => _onWordProgress;

  /// Texto completo que se está reproduciendo
  final RxString _currentFullText = ''.obs;
  String get currentFullText => _currentFullText.value;

  /// Índice de palabra actual
  final RxInt _currentWordIndex = (-1).obs;
  int get currentWordIndex => _currentWordIndex.value;
  RxInt get currentWordIndexObs => _currentWordIndex;

  /// Total de palabras en el texto actual
  int get totalWords => _words.length;

  /// Lista de palabras del texto actual
  List<String> _words = [];
  List<String> get words => _words;

  /// Estado del TTS (delega al servicio base)
  EstadoTTS get estado => _baseTTSService.estado;

  /// Tiempo de inicio de la reproducción
  DateTime? _startTime;

  /// Timer para simular progreso
  Timer? _progressTimer;
  
  /// Progreso actual
  double get progreso => _baseTTSService.progreso;

  @override
  void onInit() {
    super.onInit();
    DebugLog.i('EnhancedTTSService initializing', category: LogCategory.tts);
    _setupCallbacks();
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    super.onClose();
  }

  /// Configura callbacks para seguimiento
  void _setupCallbacks() {
    // Escuchar cambios en el estado del TTS base
    ever(_baseTTSService.estado.obs, (EstadoTTS nuevoEstado) {
      switch (nuevoEstado) {
        case EstadoTTS.reproduciendo:
          DebugLog.d('TTS started/resumed, beginning word tracking simulation', category: LogCategory.tts);
          _startTime ??= DateTime.now();
          _startProgressSimulation();
          break;
        case EstadoTTS.detenido:
        case EstadoTTS.completado:
          DebugLog.d('TTS stopped/completed, stopping word tracking', category: LogCategory.tts);
          _stopProgressSimulation();
          _currentWordIndex.value = -1;
          // Asegurar que el progreso llegue al 100% cuando se completa
          if (nuevoEstado == EstadoTTS.completado) {
            Future.delayed(const Duration(milliseconds: 100), () {
              // Forzar progreso al 100% si no está ya
              if (_baseTTSService.progreso < 1.0) {
                DebugLog.d('Forcing progress to 100% on completion', category: LogCategory.tts);
              }
            });
          }
          break;
        case EstadoTTS.pausado:
          DebugLog.d('TTS paused, pausing word tracking (maintaining position)', category: LogCategory.tts);
          _stopProgressSimulation();
          // NO resetear _currentWordIndex para mantener la posición
          break;
      }
    });
  }

  /// Reproduce texto con seguimiento mejorado
  Future<void> reproducir(String texto) async {
    _prepareTextForTracking(texto);
    _startTime = DateTime.now();
    
    // Iniciar seguimiento de progreso INMEDIATAMENTE
    _startProgressSimulation();
    
    await _baseTTSService.reproducir(texto);
    
    // Respaldo adicional por si acaso
    Future.delayed(const Duration(milliseconds: 200), () {
      if (estado == EstadoTTS.reproduciendo && _progressTimer == null) {
        DebugLog.w('Auto-starting word tracking as backup', category: LogCategory.tts);
        _startProgressSimulation();
      }
    });
  }

  /// Reproduce desde una palabra específica
  Future<void> reproducirDesdePalabra(int wordIndex) async {
    DebugLog.d('Attempting to play from word $wordIndex (total: ${_words.length})', category: LogCategory.tts);
    
    // Validar y corregir índice si es necesario
    if (_words.isEmpty) {
      DebugLog.w('No words available for playback', category: LogCategory.tts);
      return;
    }
    
    // Corregir índice si está fuera de rango
    final correctedIndex = wordIndex.clamp(0, _words.length - 1);
    if (correctedIndex != wordIndex) {
      DebugLog.w('Word index $wordIndex corrected to $correctedIndex (valid range: 0-${_words.length - 1})', category: LogCategory.tts);
    }

    // Actualizar el índice actual ANTES de reproducir
    _currentWordIndex.value = correctedIndex;
    
    // Construir texto desde la palabra especificada (usando índice corregido)
    final remainingWords = _words.sublist(correctedIndex);
    final remainingText = remainingWords.join(' ');
    
    DebugLog.d('Playing from word "${_words[correctedIndex]}" (${remainingWords.length} words remaining)', category: LogCategory.tts);
    
    // Reproducir sin llamar a _prepareTextForTracking de nuevo
    await _baseTTSService.reproducir(remainingText);
    
    // El seguimiento se iniciará automáticamente a través del callback cuando el estado cambie a 'reproduciendo'
    // Pero iniciamos manualmente como respaldo
    Future.delayed(const Duration(milliseconds: 200), () {
      if (estado == EstadoTTS.reproduciendo && _progressTimer == null) {
        DebugLog.w('Auto-starting word tracking from position $correctedIndex as backup', category: LogCategory.tts);
        _startProgressSimulation();
      }
    });
  }

  /// Detiene la reproducción
  Future<void> detener() async {
    await _baseTTSService.detener();
  }
  
  /// Detiene completamente toda reproducción (método más agresivo)
  Future<void> stopAll() async {
    await _baseTTSService.stopAll();
    // Resetear estado interno
    _currentWordIndex.value = -1;
    // El progreso se resetea automáticamente a través del servicio base
  }

  /// Pausa la reproducción (guardando la posición actual)
  Future<void> pausar() async {
    DebugLog.d('Pausing at word index: ${_currentWordIndex.value}', category: LogCategory.tts);
    await _baseTTSService.pausar();
    // La posición se mantiene automáticamente en _currentWordIndex
  }

  /// Reanuda la reproducción desde la posición actual
  Future<void> reanudar() async {
    // Si tenemos una posición válida guardada, reanudar desde ahí
    if (_currentWordIndex.value >= 0 && _words.isNotEmpty) {
      final resumeIndex = _currentWordIndex.value;
      DebugLog.i('Resuming from word index: $resumeIndex ("${_words[resumeIndex]}")', category: LogCategory.tts);
      
      // Forzar notificación inmediata de la posición actual para sincronizar UI
      _notifyWordProgress(resumeIndex);
      
      await reproducirDesdePalabra(resumeIndex);
    } else {
      // Fallback: usar el método base (aunque reinicie desde el principio)
      DebugLog.w('No valid word position found, falling back to base resume', category: LogCategory.tts);
      await _baseTTSService.reanudar();
    }
  }

  /// Prepara el texto para seguimiento de palabras
  /// Prepara texto para seguimiento (sincronizado con InteractiveText)
  void _prepareTextForTracking(String texto) {
    _currentFullText.value = texto;
    
    // Usar el mismo algoritmo que InteractiveText para sincronización perfecta
    _words = [];
    final words = texto.split(RegExp(r'\s+'));
    int currentIndex = 0;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isNotEmpty) {
        // Encontrar la posición real de la palabra en el texto original
        final wordStart = texto.indexOf(word, currentIndex);
        if (wordStart != -1) {
          _words.add(word);
          currentIndex = wordStart + word.length;
        }
      }
    }
    
    _currentWordIndex.value = -1;
    DebugLog.d('Text prepared: ${_words.length} words detected', category: LogCategory.tts);
  }

  /// Inicia tracking de progreso basado en progreso real del TTS
  void _startProgressSimulation() {
    _progressTimer?.cancel();
    
    if (_words.isEmpty) {
      DebugLog.w('No words to track, skipping real-time tracking', category: LogCategory.tts);
      return;
    }
    
    // Obtener el índice de inicio (puede ser > 0 si estamos reanudando)
    final startWordIndex = _currentWordIndex.value.clamp(0, _words.length - 1);
    DebugLog.i('Starting real-time word tracking from index $startWordIndex (${_words.length} total words)', category: LogCategory.tts);
    
    // NO resetear el índice si ya tenemos una posición válida (reanudación)
    if (_currentWordIndex.value < 0) {
      _currentWordIndex.value = 0;
      _notifyWordProgress(0);
    } else {
      // Notificar la posición actual para mantener sincronización
      _notifyWordProgress(_currentWordIndex.value);
    }
    
    // Usar timer frecuente para sincronizar con progreso real del TTS
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 100), // Actualizar cada 100ms para mejor responsividad
      (timer) {
        // Continuar hasta que se detenga explícitamente o termine
        if (estado == EstadoTTS.detenido || estado == EstadoTTS.completado) {
          DebugLog.d('Stopping word tracking - TTS state: $estado', category: LogCategory.tts);
          timer.cancel();
          _progressTimer = null;
          return;
        }
        
        // Calcular índice de palabra basado en progreso real del TTS
        final ttsProgress = _baseTTSService.progreso; // 0.0 a 1.0
        
        // Si estamos reanudando desde una posición específica, ajustar el cálculo
        final totalWordsRemaining = _words.length - startWordIndex;
        final calculatedWordIndex = startWordIndex + (ttsProgress * totalWordsRemaining).floor();
        final clampedWordIndex = calculatedWordIndex.clamp(startWordIndex, _words.length - 1);
        
        // Solo actualizar si cambió el índice de palabra
        if (clampedWordIndex != _currentWordIndex.value && clampedWordIndex >= startWordIndex) {
          final oldIndex = _currentWordIndex.value;
          
          // Usar post frame callback para evitar setState durante build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _currentWordIndex.value = clampedWordIndex;
            _notifyWordProgress(clampedWordIndex);
            
            DebugLog.d('Word highlight: $oldIndex → $clampedWordIndex (${(ttsProgress * 100).toStringAsFixed(1)}%)', 
                      category: LogCategory.tts);
          });
        }
      },
    );
    
    DebugLog.i('Word tracking timer started successfully from position $startWordIndex', category: LogCategory.tts);
  }
  
  /// Notificar progreso de palabra
  void _notifyWordProgress(int wordIndex) {
    if (wordIndex < 0 || wordIndex >= _words.length) return;
    
    final progressInfo = TTSProgressInfo(
      fullText: _currentFullText.value,
      currentCharacterIndex: _getCharacterOffsetFromWordIndex(wordIndex),
      currentWordIndex: wordIndex,
      currentWord: _words[wordIndex],
      progressPercentage: wordIndex / _words.length,
      elapsedTime: _startTime != null 
          ? DateTime.now().difference(_startTime!)
          : Duration.zero,
    );
    
    DebugLog.d('Word progress: ${wordIndex}/${_words.length} - "${_words[wordIndex]}"', category: LogCategory.tts);
    _onWordProgress?.call(progressInfo);
  }

  /// Detiene la simulación de progreso
  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }


  /// Obtiene el offset de caracteres basado en el índice de palabra
  int _getCharacterOffsetFromWordIndex(int wordIndex) {
    if (wordIndex < 0 || wordIndex >= _words.length) return 0;
    
    int offset = 0;
    for (int i = 0; i < wordIndex; i++) {
      final wordStart = _currentFullText.value.indexOf(_words[i], offset);
      offset = wordStart + _words[i].length;
    }
    
    return _currentFullText.value.indexOf(_words[wordIndex], offset);
  }

  /// Configura callback de progreso de palabras
  void setWordProgressCallback(Function(TTSProgressInfo) callback) {
    _onWordProgress = callback;
  }

  /// Limpia callback de progreso de palabras
  void clearWordProgressCallback() {
    _onWordProgress = null;
  }

  /// Salta a la siguiente palabra
  Future<void> saltarASiguientePalabra() async {
    if (_currentWordIndex.value < _words.length - 1) {
      await reproducirDesdePalabra(_currentWordIndex.value + 1);
    }
  }

  /// Vuelve a la palabra anterior
  Future<void> volverAPalabraAnterior() async {
    if (_currentWordIndex.value > 0) {
      await reproducirDesdePalabra(_currentWordIndex.value - 1);
    }
  }
}