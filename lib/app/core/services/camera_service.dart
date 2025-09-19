import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'debug_console_service.dart';

/// Opciones de fuente de imagen
enum FuenteImagen {
  camara,
  galeria,
  ambas,
}

/// Configuración de calidad de imagen
class ConfiguracionImagen {
  final int calidadJPEG;
  final double? anchoMaximo;
  final double? altoMaximo;
  final bool redimensionarAutomaticamente;

  const ConfiguracionImagen({
    this.calidadJPEG = 85,
    this.anchoMaximo,
    this.altoMaximo,
    this.redimensionarAutomaticamente = true,
  });

  ConfiguracionImagen copyWith({
    int? calidadJPEG,
    double? anchoMaximo,
    double? altoMaximo,
    bool? redimensionarAutomaticamente,
  }) {
    return ConfiguracionImagen(
      calidadJPEG: calidadJPEG ?? this.calidadJPEG,
      anchoMaximo: anchoMaximo ?? this.anchoMaximo,
      altoMaximo: altoMaximo ?? this.altoMaximo,
      redimensionarAutomaticamente: redimensionarAutomaticamente ?? this.redimensionarAutomaticamente,
    );
  }
}

/// Resultado de captura de imagen
class ResultadoImagen {
  final String rutaArchivo;
  final int tamanoBytes;
  final DateTime fechaCaptura;
  final FuenteImagen fuente;
  final Map<String, dynamic>? metadatos;

  const ResultadoImagen({
    required this.rutaArchivo,
    required this.tamanoBytes,
    required this.fechaCaptura,
    required this.fuente,
    this.metadatos,
  });

  /// Convierte a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'ruta_archivo': rutaArchivo,
      'tamano_bytes': tamanoBytes,
      'fecha_captura': fechaCaptura.millisecondsSinceEpoch,
      'fuente': fuente.toString().split('.').last,
      'metadatos': metadatos,
    };
  }

  /// Crea desde Map
  factory ResultadoImagen.fromMap(Map<String, dynamic> map) {
    return ResultadoImagen(
      rutaArchivo: map['ruta_archivo'] ?? '',
      tamanoBytes: map['tamano_bytes'] ?? 0,
      fechaCaptura: DateTime.fromMillisecondsSinceEpoch(map['fecha_captura'] ?? 0),
      fuente: FuenteImagen.values.firstWhere(
        (e) => e.toString().split('.').last == map['fuente'],
        orElse: () => FuenteImagen.camara,
      ),
      metadatos: map['metadatos'],
    );
  }
}

/// Servicio de cámara e imágenes para Te Leo
/// Gestiona la captura de imágenes desde cámara y galería
class CameraService extends GetxService {
  late ImagePicker _imagePicker;
  
  /// Configuración actual de imagen
  final Rx<ConfiguracionImagen> _configuracion = const ConfiguracionImagen().obs;
  ConfiguracionImagen get configuracion => _configuracion.value;

  /// Directorio para almacenar imágenes capturadas
  late Directory _directorioImagenes;

  /// Indica si el servicio está inicializado
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  /// Indica si hay una operación de captura en progreso
  final RxBool _isCapturing = false.obs;
  bool get isCapturing => _isCapturing.value;

  /// Lista de imágenes capturadas en la sesión actual
  final RxList<ResultadoImagen> _imagenesCapturadas = <ResultadoImagen>[].obs;
  List<ResultadoImagen> get imagenesCapturadas => _imagenesCapturadas;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  /// Inicializa el servicio de cámara
  Future<void> _initializeService() async {
    try {
      _imagePicker = ImagePicker();
      
      // Crear directorio para imágenes
      final appDir = await getApplicationDocumentsDirectory();
      _directorioImagenes = Directory(path.join(appDir.path, 'te_leo_images'));
      
      if (!await _directorioImagenes.exists()) {
        await _directorioImagenes.create(recursive: true);
      }
      
      _isInitialized.value = true;
      DebugLog.service('Camera Service inicializado correctamente', serviceName: 'Camera');
    } catch (e) {
      DebugLog.camera('Error al inicializar Camera Service: $e', level: LogLevel.error);
      _isInitialized.value = false;
    }
  }

  /// Captura una imagen desde la cámara
  Future<ResultadoImagen?> capturarDesdeCamara({
    ConfiguracionImagen? config,
  }) async {
    if (!_isInitialized.value) {
      throw Exception('El servicio de cámara no está inicializado');
    }

    if (_isCapturing.value) {
      throw Exception('Ya hay una captura en progreso');
    }

    _isCapturing.value = true;

    try {
      final configActual = config ?? _configuracion.value;
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: configActual.calidadJPEG,
        maxWidth: configActual.anchoMaximo,
        maxHeight: configActual.altoMaximo,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      return await _procesarImagenCapturada(image, FuenteImagen.camara);
    } catch (e) {
      DebugLog.camera('Error capturando desde cámara: $e', level: LogLevel.error);
      throw Exception('Error al capturar imagen desde cámara: $e');
    } finally {
      _isCapturing.value = false;
    }
  }

  /// Selecciona una imagen desde la galería
  Future<ResultadoImagen?> seleccionarDesdeGaleria({
    ConfiguracionImagen? config,
  }) async {
    if (!_isInitialized.value) {
      throw Exception('El servicio de cámara no está inicializado');
    }

    if (_isCapturing.value) {
      throw Exception('Ya hay una selección en progreso');
    }

    _isCapturing.value = true;

    try {
      final configActual = config ?? _configuracion.value;
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: configActual.calidadJPEG,
        maxWidth: configActual.anchoMaximo,
        maxHeight: configActual.altoMaximo,
      );

      if (image == null) return null;

      return await _procesarImagenCapturada(image, FuenteImagen.galeria);
    } catch (e) {
      DebugLog.camera('Error seleccionando desde galería: $e', level: LogLevel.error);
      throw Exception('Error al seleccionar imagen desde galería: $e');
    } finally {
      _isCapturing.value = false;
    }
  }

  /// Selecciona múltiples imágenes desde la galería
  Future<List<ResultadoImagen>> seleccionarMultiplesDesdeGaleria({
    ConfiguracionImagen? config,
    int? limiteImagenes,
  }) async {
    if (!_isInitialized.value) {
      throw Exception('El servicio de cámara no está inicializado');
    }

    if (_isCapturing.value) {
      throw Exception('Ya hay una selección en progreso');
    }

    _isCapturing.value = true;

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: config?.calidadJPEG ?? _configuracion.value.calidadJPEG,
        maxWidth: config?.anchoMaximo ?? _configuracion.value.anchoMaximo,
        maxHeight: config?.altoMaximo ?? _configuracion.value.altoMaximo,
      );

      if (images.isEmpty) return [];

      // Aplicar límite si se especifica
      final imagenesAProcesar = limiteImagenes != null && images.length > limiteImagenes
          ? images.take(limiteImagenes).toList()
          : images;

      final resultados = <ResultadoImagen>[];
      
      for (final image in imagenesAProcesar) {
        try {
          final resultado = await _procesarImagenCapturada(image, FuenteImagen.galeria);
          resultados.add(resultado);
        } catch (e) {
          DebugLog.camera('Error procesando imagen múltiple: $e');
          // Continuar con las siguientes imágenes
        }
      }

      return resultados;
    } catch (e) {
      DebugLog.camera('Error seleccionando múltiples imágenes: $e');
      throw Exception('Error al seleccionar múltiples imágenes: $e');
    } finally {
      _isCapturing.value = false;
    }
  }

  /// Muestra opciones para seleccionar fuente de imagen
  Future<ResultadoImagen?> mostrarOpcionesFuente({
    ConfiguracionImagen? config,
    String tituloCamara = 'Tomar foto',
    String tituloGaleria = 'Seleccionar de galería',
    String tituloCancelar = 'Cancelar',
  }) async {
    final opcion = await Get.bottomSheet<FuenteImagen>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador visual
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Text(
              'Seleccionar imagen',
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Opción cámara
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Get.theme.colorScheme.primary,
              ),
              title: Text(tituloCamara),
              onTap: () => Get.back(result: FuenteImagen.camara),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            
            // Opción galería
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Get.theme.colorScheme.primary,
              ),
              title: Text(tituloGaleria),
              onTap: () => Get.back(result: FuenteImagen.galeria),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Botón cancelar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(tituloCancelar),
              ),
            ),
            
            // Espacio para navegación segura
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
    );

    if (opcion == null) return null;

    switch (opcion) {
      case FuenteImagen.camara:
        return await capturarDesdeCamara(config: config);
      case FuenteImagen.galeria:
        return await seleccionarDesdeGaleria(config: config);
      case FuenteImagen.ambas:
        // No se usa en este contexto
        return null;
    }
  }

  /// Procesa una imagen capturada
  Future<ResultadoImagen> _procesarImagenCapturada(
    XFile image, 
    FuenteImagen fuente
  ) async {
    // Generar nombre único para el archivo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(image.path);
    final nombreArchivo = 'te_leo_$timestamp$extension';
    
    // Ruta de destino
    final rutaDestino = path.join(_directorioImagenes.path, nombreArchivo);
    
    // Copiar archivo al directorio de la app
    final archivo = File(image.path);
    final archivoDestino = await archivo.copy(rutaDestino);
    
    // Obtener información del archivo
    final tamanoBytes = await archivoDestino.length();
    
    // Crear resultado
    final resultado = ResultadoImagen(
      rutaArchivo: rutaDestino,
      tamanoBytes: tamanoBytes,
      fechaCaptura: DateTime.now(),
      fuente: fuente,
      metadatos: {
        'nombre_original': path.basename(image.path),
        'extension': extension,
        'configuracion_calidad': _configuracion.value.calidadJPEG,
      },
    );
    
    // Agregar a la lista de imágenes capturadas
    _imagenesCapturadas.add(resultado);
    
    return resultado;
  }

  /// Actualiza la configuración de imagen
  void actualizarConfiguracion(ConfiguracionImagen nuevaConfig) {
    _configuracion.value = nuevaConfig;
  }

  /// Elimina una imagen capturada
  Future<bool> eliminarImagen(String rutaArchivo) async {
    try {
      final archivo = File(rutaArchivo);
      if (await archivo.exists()) {
        await archivo.delete();
        
        // Remover de la lista de imágenes capturadas
        _imagenesCapturadas.removeWhere((img) => img.rutaArchivo == rutaArchivo);
        
        return true;
      }
      return false;
    } catch (e) {
      DebugLog.camera('Error eliminando imagen: $e');
      return false;
    }
  }

  /// Limpia imágenes temporales antiguas
  Future<void> limpiarImagenesTemporales({
    Duration antiguedad = const Duration(days: 7),
  }) async {
    try {
      if (!await _directorioImagenes.exists()) return;
      
      final ahora = DateTime.now();
      final archivos = await _directorioImagenes.list().toList();
      
      for (final archivo in archivos) {
        if (archivo is File) {
          final estadisticas = await archivo.stat();
          final diferencia = ahora.difference(estadisticas.modified);
          
          if (diferencia > antiguedad) {
            try {
              await archivo.delete();
              DebugLog.camera('Imagen temporal eliminada: ${archivo.path}');
            } catch (e) {
              DebugLog.camera('Error eliminando imagen temporal: $e');
            }
          }
        }
      }
      
      // Actualizar lista de imágenes capturadas
      _imagenesCapturadas.removeWhere((img) => !File(img.rutaArchivo).existsSync());
    } catch (e) {
      DebugLog.camera('Error limpiando imágenes temporales: $e');
    }
  }

  /// Obtiene el tamaño total de imágenes almacenadas
  Future<int> obtenerTamanoTotalImagenes() async {
    try {
      if (!await _directorioImagenes.exists()) return 0;
      
      int tamanoTotal = 0;
      final archivos = await _directorioImagenes.list().toList();
      
      for (final archivo in archivos) {
        if (archivo is File) {
          final estadisticas = await archivo.stat();
          tamanoTotal += estadisticas.size;
        }
      }
      
      return tamanoTotal;
    } catch (e) {
      DebugLog.camera('Error obteniendo tamaño total: $e');
      return 0;
    }
  }

  /// Verifica si una imagen existe
  bool existeImagen(String rutaArchivo) {
    return File(rutaArchivo).existsSync();
  }

  /// Obtiene información de una imagen
  Future<Map<String, dynamic>?> obtenerInfoImagen(String rutaArchivo) async {
    try {
      final archivo = File(rutaArchivo);
      if (!await archivo.exists()) return null;
      
      final estadisticas = await archivo.stat();
      
      return {
        'ruta': rutaArchivo,
        'nombre': path.basename(rutaArchivo),
        'extension': path.extension(rutaArchivo),
        'tamano_bytes': estadisticas.size,
        'fecha_modificacion': estadisticas.modified,
        'fecha_acceso': estadisticas.accessed,
      };
    } catch (e) {
      DebugLog.camera('Error obteniendo info de imagen: $e');
      return null;
    }
  }
}
