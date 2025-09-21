import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/error_service.dart';
import '../../core/services/debug_console_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/services/usage_limits_service.dart';
import '../../core/services/ads_service.dart';
import '../../data/providers/database_provider.dart';
import '../../data/models/documento.dart';
import '../../../global_widgets/global_widgets.dart';

/// Estados del proceso de escaneo
enum EstadoEscaneo {
  inicial,
  seleccionandoImagen,
  procesandoOCR,
  mostrandoResultado,
  guardando,
  completado,
  error,
}

/// Controlador para el módulo de escaneo de texto
class ScanController extends GetxController {
  // Servicios
  final CameraService _cameraService = Get.find<CameraService>();
  final OCRService _ocrService = Get.find<OCRService>();
  final TTSService _ttsService = Get.find<TTSService>();
  final ErrorService _errorService = Get.find<ErrorService>();
  final UserPreferencesService _prefsService = Get.find<UserPreferencesService>();
  final DatabaseProvider _databaseProvider = DatabaseProvider();

  /// Estado actual del proceso de escaneo
  final Rx<EstadoEscaneo> _estado = EstadoEscaneo.inicial.obs;
  EstadoEscaneo get estado => _estado.value;

  /// Resultado del OCR actual
  final Rxn<OCRResult> _resultadoOCR = Rxn<OCRResult>();
  OCRResult? get resultadoOCR => _resultadoOCR.value;

  /// Imagen seleccionada/capturada
  final Rxn<ResultadoImagen> _imagenActual = Rxn<ResultadoImagen>();
  ResultadoImagen? get imagenActual => _imagenActual.value;

  /// Texto extraído (editable)
  final RxString _textoExtraido = ''.obs;
  String get textoExtraido => _textoExtraido.value;
  set textoExtraido(String value) => _textoExtraido.value = value;

  /// Título del documento (editable)
  final RxString _tituloDocumento = ''.obs;
  String get tituloDocumento => _tituloDocumento.value;
  set tituloDocumento(String value) => _tituloDocumento.value = value;

  /// Progreso del procesamiento
  final RxDouble _progreso = 0.0.obs;
  double get progreso => _progreso.value;

  /// Mensaje de estado actual
  final RxString _mensajeEstado = ''.obs;
  String get mensajeEstado => _mensajeEstado.value;

  /// Indica si el TTS está reproduciéndose
  final RxBool _isPlaying = false.obs;
  bool get isPlaying => _isPlaying.value;

  /// Estadísticas del texto procesado
  final Rxn<EstadisticasTexto> _estadisticas = Rxn<EstadisticasTexto>();
  EstadisticasTexto? get estadisticas => _estadisticas.value;

  @override
  void onInit() {
    super.onInit();
    _inicializarControlador();
  }

  @override
  void onClose() {
    _detenerReproduccion();
    super.onClose();
  }

  /// Inicializa el controlador
  void _inicializarControlador() {
    // Escuchar cambios en el estado del TTS
    ever(_ttsService.estado.obs, (EstadoTTS estadoTTS) {
      _isPlaying.value = estadoTTS == EstadoTTS.reproduciendo;
    });
  }

  /// Inicia el proceso de escaneo mostrando opciones de fuente
  Future<void> iniciarEscaneo() async {
    try {
      // Verificar límites antes de escanear
      final limitsService = Get.find<UsageLimitsService>();
      if (!limitsService.canScanDocument()) {
        await limitsService.showLimitReachedDialog();
        return;
      }

      _estado.value = EstadoEscaneo.seleccionandoImagen;
      _progreso.value = 0.0;
      _mensajeEstado.value = 'Selecciona una imagen...';

      final imagen = await _cameraService.mostrarOpcionesFuente(
        tituloCamara: 'Tomar foto del texto',
        tituloGaleria: 'Seleccionar imagen',
      );

      if (imagen == null) {
        _estado.value = EstadoEscaneo.inicial;
        return;
      }

      _imagenActual.value = imagen;
      await _procesarImagen();
    } catch (e) {
      await _manejarError(e, tipo: TipoError.camera);
    }
  }

  /// Procesa la imagen seleccionada con OCR
  Future<void> _procesarImagen() async {
    if (_imagenActual.value == null) return;

    try {
      _estado.value = EstadoEscaneo.procesandoOCR;
      _progreso.value = 0.2;
      _mensajeEstado.value = 'Analizando imagen...';

      // Mostrar loading overlay
      LoadingOverlay.mostrar(
        mensaje: 'Extrayendo texto de la imagen...',
        mostrarProgreso: true,
        progreso: _progreso.value,
      );

      // Simular progreso
      _progreso.value = 0.4;
      await Future.delayed(const Duration(milliseconds: 500));

      // Procesar con OCR
      final resultado = await _ocrService.extraerTextoDeImagen(_imagenActual.value!.rutaArchivo);
      
      _progreso.value = 0.8;
      await Future.delayed(const Duration(milliseconds: 300));

      if (resultado.textoCompleto.trim().isEmpty) {
        LoadingOverlay.ocultar();
        await ModernDialog.mostrarInformacion(
          titulo: 'No se detectó texto',
          mensaje: 'No se pudo extraer texto de la imagen seleccionada. Intenta con una imagen más clara.',
          icono: Icons.text_fields_outlined,
        );
        _estado.value = EstadoEscaneo.inicial;
        return;
      }

      _resultadoOCR.value = resultado;
      _textoExtraido.value = _ocrService.limpiarTexto(resultado.textoCompleto);
      _estadisticas.value = _ocrService.obtenerEstadisticas(resultado);
      _tituloDocumento.value = _generarTituloAutomatico(_textoExtraido.value);

      _progreso.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 200));

      LoadingOverlay.ocultar();
      _estado.value = EstadoEscaneo.mostrandoResultado;
      _mensajeEstado.value = 'Texto extraído correctamente';

      // Mostrar mensaje de éxito
      Get.snackbar(
        'Éxito',
        'Texto extraído: ${_estadisticas.value?.totalPalabras} palabras detectadas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      LoadingOverlay.ocultar();
      await _manejarError(e, tipo: TipoError.ocr);
    }
  }

  /// Reproduce el texto extraído
  Future<void> reproducirTexto() async {
    if (_textoExtraido.value.isEmpty) {
      Get.snackbar(
        'Sin texto',
        'No hay texto para reproducir',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      if (_isPlaying.value) {
        await _ttsService.detener();
      } else {
        await _ttsService.reproducir(_textoExtraido.value);
      }
    } catch (e) {
      await _errorService.handleTTSError(e, contexto: 'Reproducción desde escaneo');
    }
  }

  /// Pausa/reanuda la reproducción
  Future<void> pausarReanudarReproduccion() async {
    try {
      if (_ttsService.estado == EstadoTTS.reproduciendo) {
        await _ttsService.pausar();
      } else if (_ttsService.estado == EstadoTTS.pausado) {
        await _ttsService.reanudar();
      }
    } catch (e) {
      DebugLog.e('Error pausando/reanudando TTS: $e', category: LogCategory.tts);
    }
  }

  /// Detiene la reproducción
  Future<void> _detenerReproduccion() async {
    try {
      await _ttsService.detener();
    } catch (e) {
      DebugLog.e('Error deteniendo reproducción TTS: $e', category: LogCategory.tts);
    }
  }

  /// Guarda el documento en la base de datos
  Future<void> guardarDocumento() async {
    if (_textoExtraido.value.trim().isEmpty) {
      await ModernDialog.mostrarError(
        mensaje: 'No hay texto para guardar',
      );
      return;
    }

    if (_tituloDocumento.value.trim().isEmpty) {
      await ModernDialog.mostrarError(
        mensaje: 'Por favor ingresa un título para el documento',
      );
      return;
    }

    try {
      _estado.value = EstadoEscaneo.guardando;
      _mensajeEstado.value = 'Guardando documento...';

      LoadingOverlay.mostrar(mensaje: 'Guardando documento...');

      // Crear documento
      final documento = Documento.nuevo(
        titulo: _tituloDocumento.value.trim(),
        contenido: _textoExtraido.value.trim(),
        rutaImagen: _imagenActual.value?.rutaArchivo,
        etiquetas: _generarEtiquetasAutomaticas(_textoExtraido.value),
      );

      // Guardar en base de datos
      await _databaseProvider.insertarDocumento(documento);
      
      // Registrar el uso en el servicio de límites
      final limitsService = Get.find<UsageLimitsService>();
      await limitsService.registerDocumentScanned();
      
      // Incrementar contador de documentos escaneados
      await _prefsService.incrementDocumentsScanned();

      LoadingOverlay.ocultar();
      _estado.value = EstadoEscaneo.completado;
      _mensajeEstado.value = 'Documento guardado correctamente';

      // Mostrar confirmación
      await ModernDialog.mostrarExito(
        mensaje: 'El documento "${_tituloDocumento.value}" ha sido guardado en tu biblioteca.',
      );

      DebugLog.i('Document scanned and saved successfully: ${_tituloDocumento.value}', 
                 category: LogCategory.database);

      // Mostrar anuncio intersticial ocasionalmente (cada 3 documentos)
      _tryShowInterstitialAd();

      // Volver a la biblioteca
      Get.back();
      Get.toNamed('/library');

    } catch (e) {
      LoadingOverlay.ocultar();
      await _manejarError(e, tipo: TipoError.database);
    }
  }

  /// Reinicia el proceso de escaneo
  void reiniciarEscaneo() {
    _detenerReproduccion();
    _estado.value = EstadoEscaneo.inicial;
    _resultadoOCR.value = null;
    _imagenActual.value = null;
    _textoExtraido.value = '';
    _tituloDocumento.value = '';
    _estadisticas.value = null;
    _progreso.value = 0.0;
    _mensajeEstado.value = '';
  }

  /// Genera un título automático basado en el texto
  String _generarTituloAutomatico(String texto) {
    if (texto.trim().isEmpty) return 'Documento sin título';
    
    // Tomar las primeras palabras significativas
    final palabras = texto.trim().split(RegExp(r'\s+'));
    final palabrasSignificativas = palabras
        .where((palabra) => palabra.length > 2)
        .take(4)
        .join(' ');
    
    if (palabrasSignificativas.isEmpty) {
      return 'Documento ${DateTime.now().day}/${DateTime.now().month}';
    }
    
    // Capitalizar primera letra
    return palabrasSignificativas.substring(0, 1).toUpperCase() + 
           palabrasSignificativas.substring(1);
  }

  /// Genera etiquetas automáticas basadas en el contenido
  String _generarEtiquetasAutomaticas(String texto) {
    final etiquetas = <String>[];
    final textoLower = texto.toLowerCase();
    
    // Detectar tipos de documento comunes
    if (textoLower.contains(RegExp(r'\b(factura|recibo|ticket)\b'))) {
      etiquetas.add('factura');
    }
    if (textoLower.contains(RegExp(r'\b(carta|estimado|saludo)\b'))) {
      etiquetas.add('carta');
    }
    if (textoLower.contains(RegExp(r'\b(artículo|capítulo|sección)\b'))) {
      etiquetas.add('artículo');
    }
    if (textoLower.contains(RegExp(r'\b(receta|ingredientes|preparación)\b'))) {
      etiquetas.add('receta');
    }
    if (textoLower.contains(RegExp(r'\b(nota|recordatorio|importante)\b'))) {
      etiquetas.add('nota');
    }
    
    // Agregar etiqueta por fuente
    if (_imagenActual.value?.fuente == FuenteImagen.camara) {
      etiquetas.add('escaneado');
    } else {
      etiquetas.add('galería');
    }
    
    // Agregar fecha
    final fecha = DateTime.now();
    etiquetas.add('${fecha.day}-${fecha.month}-${fecha.year}');
    
    return etiquetas.join(', ');
  }

  /// Maneja errores del proceso usando el servicio global
  Future<void> _manejarError(dynamic error, {TipoError? tipo}) async {
    _estado.value = EstadoEscaneo.error;
    
    await _errorService.handleError(
      error,
      tipo: tipo ?? TipoError.unknown,
      contexto: {
        'controlador': 'ScanController',
        'estado_anterior': _estado.value.toString(),
      },
    );
    
    _mensajeEstado.value = error.toString();
  }

  /// Valida si se puede guardar el documento
  bool get puedeGuardar => 
      _textoExtraido.value.trim().isNotEmpty && 
      _tituloDocumento.value.trim().isNotEmpty &&
      _estado.value == EstadoEscaneo.mostrandoResultado;

  /// Obtiene el progreso como porcentaje
  String get progresoTexto => '${(_progreso.value * 100).round()}%';

  /// Intenta mostrar anuncio intersticial (para usuarios gratuitos)
  Future<void> _tryShowInterstitialAd() async {
    try {
      final adsService = Get.find<AdsService>();
      final limitsService = Get.find<UsageLimitsService>();
      
      // Solo mostrar para usuarios gratuitos
      if (!adsService.shouldShowAds) return;
      
      // Mostrar cada 3 documentos escaneados
      final documentsThisMonth = limitsService.documentosUsadosEstesMes;
      if (documentsThisMonth > 0 && documentsThisMonth % 3 == 0) {
        DebugLog.d('Showing interstitial ad after $documentsThisMonth documents', 
                   category: LogCategory.service);
        
        // Esperar un poco para que se complete la navegación
        await Future.delayed(const Duration(seconds: 2));
        await adsService.showInterstitialAd();
      }
    } catch (e) {
      DebugLog.w('Error trying to show interstitial ad: $e', category: LogCategory.service);
    }
  }
}
