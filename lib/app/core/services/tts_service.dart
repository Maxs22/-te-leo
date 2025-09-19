import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'debug_console_service.dart';

/// Estados de reproducción del TTS
enum EstadoTTS {
  detenido,
  reproduciendo,
  pausado,
  completado,
}

/// Configuración de voz para TTS
class ConfiguracionVoz {
  final String idioma;
  final double velocidad;
  final double tono;
  final double volumen;
  final String? vozSeleccionada;

  const ConfiguracionVoz({
    this.idioma = 'es-ES',
    this.velocidad = 0.5,
    this.tono = 1.0,
    this.volumen = 0.8,
    this.vozSeleccionada,
  });

  ConfiguracionVoz copyWith({
    String? idioma,
    double? velocidad,
    double? tono,
    double? volumen,
    String? vozSeleccionada,
  }) {
    return ConfiguracionVoz(
      idioma: idioma ?? this.idioma,
      velocidad: velocidad ?? this.velocidad,
      tono: tono ?? this.tono,
      volumen: volumen ?? this.volumen,
      vozSeleccionada: vozSeleccionada ?? this.vozSeleccionada,
    );
  }
}

/// Servicio de Text-to-Speech para Te Leo
/// Proporciona funcionalidades de lectura en voz alta accesibles
class TTSService extends GetxService {
  late FlutterTts _flutterTts;
  
  /// Estado actual de la reproducción
  final Rx<EstadoTTS> _estado = EstadoTTS.detenido.obs;
  EstadoTTS get estado => _estado.value;

  /// Configuración actual de la voz
  final Rx<ConfiguracionVoz> _configuracion = const ConfiguracionVoz().obs;
  ConfiguracionVoz get configuracion => _configuracion.value;

  /// Texto que se está reproduciendo actualmente
  final RxString _textoActual = ''.obs;
  String get textoActual => _textoActual.value;

  /// Progreso de la reproducción (0.0 - 1.0)
  final RxDouble _progreso = 0.0.obs;
  double get progreso => _progreso.value;

  /// Lista de voces disponibles
  final RxList<Map<String, dynamic>> _vocesDisponibles = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get vocesDisponibles => _vocesDisponibles;

  /// Lista de idiomas disponibles
  final RxList<String> _idiomasDisponibles = <String>[].obs;
  List<String> get idiomasDisponibles => _idiomasDisponibles;

  /// Indica si el servicio está inicializado
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  /// Obtiene las voces reales disponibles en el dispositivo
  Future<List<Map<String, dynamic>>> obtenerVocesReales() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        final voicesList = List<Map<String, dynamic>>.from(voices);
        _vocesDisponibles.value = voicesList;
        
        DebugLog.tts('Voces disponibles en el dispositivo: ${voicesList.length}', level: LogLevel.info);
        
        // Log de las voces para debugging
        for (final voice in voicesList) {
          DebugLog.tts('Voz: ${voice['name']} - Idioma: ${voice['locale']}', level: LogLevel.debug);
        }
        
        return voicesList;
      }
      return [];
    } catch (e) {
      DebugLog.tts('Error obteniendo voces reales: $e', level: LogLevel.error);
      return [];
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeTTS();
  }

  @override
  void onClose() {
    _dispose();
    super.onClose();
  }

  /// Inicializa el servicio TTS
  Future<void> _initializeTTS() async {
    try {
      _flutterTts = FlutterTts();
      
      // Configurar callbacks
      _flutterTts.setStartHandler(() {
        _estado.value = EstadoTTS.reproduciendo;
      });

      _flutterTts.setCompletionHandler(() {
        _estado.value = EstadoTTS.completado;
        _progreso.value = 1.0;
      });

      _flutterTts.setCancelHandler(() {
        _estado.value = EstadoTTS.detenido;
        _progreso.value = 0.0;
      });

      _flutterTts.setPauseHandler(() {
        _estado.value = EstadoTTS.pausado;
      });

      _flutterTts.setContinueHandler(() {
        _estado.value = EstadoTTS.reproduciendo;
      });

      _flutterTts.setErrorHandler((msg) {
        DebugLog.tts('Error TTS: $msg', level: LogLevel.error);
        _estado.value = EstadoTTS.detenido;
      });

      // Configurar progreso si está disponible
      _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
        if (text.isNotEmpty) {
          _progreso.value = endOffset / text.length;
        }
      });

      // Cargar configuraciones disponibles
      await _cargarConfiguracionesDisponibles();
      
      // Aplicar configuración inicial
      await _aplicarConfiguracion(_configuracion.value);
      
      _isInitialized.value = true;
      DebugLog.service('TTS Service inicializado correctamente', serviceName: 'TTS');
    } catch (e) {
      DebugLog.e('Error al inicializar TTS Service: $e', 
                 category: LogCategory.tts, 
                 stackTrace: e.toString());
      _isInitialized.value = false;
    }
  }

  /// Carga las configuraciones disponibles (voces e idiomas)
  Future<void> _cargarConfiguracionesDisponibles() async {
    try {
      // Obtener idiomas disponibles
      final idiomas = await _flutterTts.getLanguages;
      if (idiomas != null) {
        _idiomasDisponibles.value = List<String>.from(idiomas);
      }

      // Obtener voces disponibles
      final voces = await _flutterTts.getVoices;
      if (voces != null) {
        _vocesDisponibles.value = List<Map<String, dynamic>>.from(voces);
      }
    } catch (e) {
      DebugLog.tts('Error cargando configuraciones: $e', level: LogLevel.error);
    }
  }

  /// Aplica una configuración de voz
  Future<void> _aplicarConfiguracion(ConfiguracionVoz config) async {
    try {
      // Aplicar configuraciones básicas
      await _flutterTts.setLanguage(config.idioma);
      
      // Aplicar velocidad con rango validado (0.1 - 2.0)
      final velocidad = config.velocidad.clamp(0.1, 2.0);
      await _flutterTts.setSpeechRate(velocidad);
      
      // Aplicar tono con rango validado (0.5 - 2.0)
      final tono = config.tono.clamp(0.5, 2.0);
      await _flutterTts.setPitch(tono);
      
      // Aplicar volumen con rango validado (0.0 - 1.0)
      final volumen = config.volumen.clamp(0.0, 1.0);
      await _flutterTts.setVolume(volumen);
      
      // Log de configuración aplicada
      DebugLog.tts(
        'Configuración aplicada - Idioma: ${config.idioma}, Velocidad: $velocidad, Tono: $tono, Volumen: $volumen',
        level: LogLevel.info
      );
      
      if (config.vozSeleccionada != null) {
        // Intentar usar la voz específica
        final success = await _trySetSpecificVoice(config.vozSeleccionada!, config.idioma);
        if (!success) {
          DebugLog.tts('Voz específica no disponible: ${config.vozSeleccionada}, usando voz por defecto', level: LogLevel.warning);
        }
      }
      
      // Pequeña pausa para que se apliquen los cambios
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      DebugLog.tts('Error aplicando configuración: $e', level: LogLevel.error);
    }
  }

  /// Intenta configurar una voz específica
  Future<bool> _trySetSpecificVoice(String voiceName, String locale) async {
    try {
      // Obtener voces disponibles
      final availableVoices = await _flutterTts.getVoices;
      
      if (availableVoices != null) {
        // Convertir a lista tipada correctamente
        final voicesList = List<Map<String, dynamic>>.from(availableVoices);
        
        // Log de voces disponibles para debugging
        DebugLog.tts('Voces disponibles en dispositivo: ${voicesList.length}', level: LogLevel.info);
        for (final voice in voicesList) {
          DebugLog.tts('  - ${voice['name']} (${voice['locale']})', level: LogLevel.debug);
        }
        
        // Buscar la voz exacta
        try {
          final exactVoice = voicesList.firstWhere(
            (voice) => voice['name'] == voiceName && voice['locale'] == locale,
          );
          
          await _flutterTts.setVoice(Map<String, String>.from(exactVoice));
          DebugLog.tts('Voz configurada exitosamente: $voiceName', level: LogLevel.info);
          return true;
        } catch (e) {
          // No se encontró voz exacta, buscar compatible
        }
        
        // Si no se encuentra la voz exacta, buscar una compatible por idioma
        try {
          final compatibleVoice = voicesList.firstWhere(
            (voice) => voice['locale']?.toString().startsWith(locale.split('-')[0]) == true,
          );
          
          await _flutterTts.setVoice(Map<String, String>.from(compatibleVoice));
          DebugLog.tts('Usando voz compatible: ${compatibleVoice['name']} para $locale', level: LogLevel.info);
          return true;
        } catch (e) {
          // No hay voces compatibles
        }
      }
      
      return false;
    } catch (e) {
      DebugLog.tts('Error configurando voz específica: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Reproduce un texto
  Future<void> reproducir(String texto) async {
    if (!_isInitialized.value) {
      throw Exception('El servicio TTS no está inicializado');
    }

    if (texto.isEmpty) {
      throw Exception('El texto no puede estar vacío');
    }

    try {
      // Detener cualquier reproducción actual
      await detener();
      
      _textoActual.value = texto;
      _progreso.value = 0.0;
      
      await _flutterTts.speak(texto);
    } catch (e) {
      DebugLog.tts('Error reproduciendo texto: $e', 
                   level: LogLevel.error, 
                   metadata: {'texto_length': texto.length});
      _estado.value = EstadoTTS.detenido;
      throw Exception('Error al reproducir el texto: $e');
    }
  }

  /// Pausa la reproducción
  Future<void> pausar() async {
    if (_estado.value == EstadoTTS.reproduciendo) {
      await _flutterTts.pause();
    }
  }

  /// Reanuda la reproducción
  Future<void> reanudar() async {
    if (_estado.value == EstadoTTS.pausado) {
      await _flutterTts.speak(_textoActual.value);
    }
  }

  /// Detiene la reproducción
  Future<void> detener() async {
    await _flutterTts.stop();
    _estado.value = EstadoTTS.detenido;
    _progreso.value = 0.0;
  }
  
  /// Detiene completamente toda reproducción (método más agresivo)
  Future<void> stopAll() async {
    try {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _flutterTts.awaitSpeakCompletion(false);
      _estado.value = EstadoTTS.detenido;
      _progreso.value = 0.0;
    } catch (e) {
      // Forzar estado detenido aunque haya error
      _estado.value = EstadoTTS.detenido;
      _progreso.value = 0.0;
    }
  }

  /// Actualiza la configuración de voz
  Future<void> actualizarConfiguracion(ConfiguracionVoz nuevaConfig) async {
    _configuracion.value = nuevaConfig;
    await _aplicarConfiguracion(nuevaConfig);
  }

  /// Reproduce texto con configuración temporal
  Future<void> reproducirConConfiguracion(
    String texto, 
    ConfiguracionVoz configTemporal
  ) async {
    final configOriginal = _configuracion.value;
    
    try {
      await actualizarConfiguracion(configTemporal);
      await reproducir(texto);
    } finally {
      // Restaurar configuración original después de la reproducción
      await actualizarConfiguracion(configOriginal);
    }
  }

  /// Reproduce texto por fragmentos (útil para textos largos)
  Future<void> reproducirPorFragmentos(
    String texto, {
    int tamanoFragmento = 500,
    Duration pausaEntreFragmentos = const Duration(milliseconds: 500),
    Function(int fragmentoActual, int totalFragmentos)? onProgreso,
  }) async {
    if (!_isInitialized.value) {
      throw Exception('El servicio TTS no está inicializado');
    }

    final fragmentos = _dividirTextoEnFragmentos(texto, tamanoFragmento);
    
    for (int i = 0; i < fragmentos.length; i++) {
      if (_estado.value == EstadoTTS.detenido) break;
      
      await reproducir(fragmentos[i]);
      
      // Esperar a que termine el fragmento actual
      while (_estado.value == EstadoTTS.reproduciendo) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (onProgreso != null) {
        onProgreso(i + 1, fragmentos.length);
      }
      
      // Pausa entre fragmentos (excepto el último)
      if (i < fragmentos.length - 1) {
        await Future.delayed(pausaEntreFragmentos);
      }
    }
  }

  /// Divide el texto en fragmentos manejables
  List<String> _dividirTextoEnFragmentos(String texto, int tamanoMaximo) {
    if (texto.length <= tamanoMaximo) {
      return [texto];
    }

    final fragmentos = <String>[];
    final parrafos = texto.split('\n\n');
    
    String fragmentoActual = '';
    
    for (final parrafo in parrafos) {
      if ((fragmentoActual + parrafo).length <= tamanoMaximo) {
        fragmentoActual += (fragmentoActual.isEmpty ? '' : '\n\n') + parrafo;
      } else {
        if (fragmentoActual.isNotEmpty) {
          fragmentos.add(fragmentoActual);
          fragmentoActual = '';
        }
        
        // Si un párrafo es muy largo, dividirlo por oraciones
        if (parrafo.length > tamanoMaximo) {
          final oraciones = parrafo.split(RegExp(r'[.!?]+'));
          String oracionesActuales = '';
          
          for (final oracion in oraciones) {
            if ((oracionesActuales + oracion).length <= tamanoMaximo) {
              oracionesActuales += (oracionesActuales.isEmpty ? '' : '. ') + oracion;
            } else {
              if (oracionesActuales.isNotEmpty) {
                fragmentos.add(oracionesActuales);
                oracionesActuales = oracion;
              } else {
                // Si una oración es muy larga, dividirla por palabras
                fragmentos.addAll(_dividirPorPalabras(oracion, tamanoMaximo));
              }
            }
          }
          
          if (oracionesActuales.isNotEmpty) {
            fragmentoActual = oracionesActuales;
          }
        } else {
          fragmentoActual = parrafo;
        }
      }
    }
    
    if (fragmentoActual.isNotEmpty) {
      fragmentos.add(fragmentoActual);
    }
    
    return fragmentos;
  }

  /// Divide texto por palabras cuando las oraciones son muy largas
  List<String> _dividirPorPalabras(String texto, int tamanoMaximo) {
    final palabras = texto.split(' ');
    final fragmentos = <String>[];
    String fragmentoActual = '';
    
    for (final palabra in palabras) {
      if ((fragmentoActual + ' ' + palabra).length <= tamanoMaximo) {
        fragmentoActual += (fragmentoActual.isEmpty ? '' : ' ') + palabra;
      } else {
        if (fragmentoActual.isNotEmpty) {
          fragmentos.add(fragmentoActual);
          fragmentoActual = palabra;
        } else {
          // Si una palabra es más larga que el tamaño máximo
          fragmentos.add(palabra);
        }
      }
    }
    
    if (fragmentoActual.isNotEmpty) {
      fragmentos.add(fragmentoActual);
    }
    
    return fragmentos;
  }

  /// Obtiene voces filtradas por idioma
  List<Map<String, dynamic>> obtenerVocesPorIdioma(String idioma) {
    return _vocesDisponibles
        .where((voz) => voz['locale']?.startsWith(idioma.substring(0, 2)) == true)
        .toList();
  }

  /// Verifica si un idioma está disponible
  bool esIdiomaDisponible(String idioma) {
    return _idiomasDisponibles.contains(idioma);
  }

  /// Obtiene información del estado actual
  Map<String, dynamic> obtenerEstadoActual() {
    return {
      'estado': estado.toString().split('.').last,
      'texto_actual': textoActual,
      'progreso': progreso,
      'configuracion': {
        'idioma': configuracion.idioma,
        'velocidad': configuracion.velocidad,
        'tono': configuracion.tono,
        'volumen': configuracion.volumen,
        'voz_seleccionada': configuracion.vozSeleccionada,
      },
      'is_initialized': isInitialized,
    };
  }

  /// Libera los recursos del servicio
  void _dispose() {
    if (_isInitialized.value) {
      _flutterTts.stop();
      _isInitialized.value = false;
    }
  }
}
