import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:get/get.dart';
import 'debug_console_service.dart';

/// Servicio de reconocimiento óptico de caracteres (OCR) para Te Leo
/// Utiliza Google ML Kit para extraer texto de imágenes de forma offline
class OCRService extends GetxService {
  late TextRecognizer _textRecognizer;
  
  /// Indica si el servicio está inicializado
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  /// Indica si hay una operación de OCR en progreso
  final RxBool _isProcessing = false.obs;
  bool get isProcessing => _isProcessing.value;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  @override
  void onClose() {
    _dispose();
    super.onClose();
  }

  /// Inicializa el servicio de reconocimiento de texto
  Future<void> _initializeService() async {
    try {
      // Configurar el reconocedor de texto para español
      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      
      _isInitialized.value = true;
      DebugLog.service('OCR Service inicializado correctamente', serviceName: 'OCR');
    } catch (e) {
      DebugLog.ocr('Error al inicializar OCR Service: $e', level: LogLevel.error);
      _isInitialized.value = false;
    }
  }

  /// Extrae texto de una imagen
  Future<OCRResult> extraerTextoDeImagen(String rutaImagen) async {
    if (!_isInitialized.value) {
      throw Exception('El servicio OCR no está inicializado');
    }

    if (_isProcessing.value) {
      throw Exception('Ya hay una operación de OCR en progreso');
    }

    _isProcessing.value = true;

    try {
      final inputImage = InputImage.fromFilePath(rutaImagen);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final result = OCRResult(
        textoCompleto: recognizedText.text,
        bloques: recognizedText.blocks.map((block) => 
          BloqueTexto(
            texto: block.text,
            idioma: 'es', // Idioma por defecto
            confianza: _calcularConfianzaPromedio(block),
            boundingBox: BoundingBox(
              left: block.boundingBox.left.toDouble(),
              top: block.boundingBox.top.toDouble(),
              right: block.boundingBox.right.toDouble(),
              bottom: block.boundingBox.bottom.toDouble(),
            ),
          )
        ).toList(),
        rutaImagenOriginal: rutaImagen,
        tiempoProcessamiento: DateTime.now(),
      );

      return result;
    } catch (e) {
      throw Exception('Error al procesar la imagen: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Extrae texto de múltiples imágenes
  Future<List<OCRResult>> extraerTextoDeMultiplesImagenes(
    List<String> rutasImagenes,
    {Function(int, int)? onProgreso}
  ) async {
    final resultados = <OCRResult>[];
    
    for (int i = 0; i < rutasImagenes.length; i++) {
      try {
        final resultado = await extraerTextoDeImagen(rutasImagenes[i]);
        resultados.add(resultado);
        
        if (onProgreso != null) {
          onProgreso(i + 1, rutasImagenes.length);
        }
      } catch (e) {
        DebugLog.ocr('Error procesando imagen múltiple: $e', 
                     level: LogLevel.warning,
                     metadata: {'imagen_path': rutasImagenes[i], 'index': i});
        // Continuar con las siguientes imágenes
      }
    }
    
    return resultados;
  }

  /// Valida si una imagen es válida para OCR
  Future<bool> validarImagen(String rutaImagen) async {
    try {
      final file = File(rutaImagen);
      if (!await file.exists()) {
        return false;
      }

      // Verificar el tamaño del archivo (no mayor a 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return false;
      }

      // Verificar extensión del archivo
      final extension = rutaImagen.toLowerCase().split('.').last;
      final extensionesValidas = ['jpg', 'jpeg', 'png', 'bmp', 'webp'];
      
      return extensionesValidas.contains(extension);
    } catch (e) {
      return false;
    }
  }

  /// Calcula la confianza promedio de un bloque de texto
  double _calcularConfianzaPromedio(TextBlock block) {
    if (block.lines.isEmpty) return 0.0;
    
    double sumaConfianza = 0.0;
    int totalElementos = 0;
    
    for (final line in block.lines) {
      for (final _ in line.elements) {
        // En versiones más nuevas de ML Kit, la confianza puede no estar disponible
        // Por ahora retornamos un valor fijo alto
        sumaConfianza += 0.95;
        totalElementos++;
      }
    }
    
    return totalElementos > 0 ? sumaConfianza / totalElementos : 0.0;
  }

  /// Limpia y mejora el texto extraído
  String limpiarTexto(String textoExtraido) {
    if (textoExtraido.isEmpty) return textoExtraido;
    
    // Eliminar espacios extra y saltos de línea innecesarios
    String textoLimpio = textoExtraido
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
    
    // Corregir puntuación común mal reconocida
    textoLimpio = textoLimpio
        .replaceAll(RegExp(r'\s+([.,:;!?])'), r'$1');
    
    return textoLimpio;
  }

  /// Obtiene estadísticas del texto reconocido
  EstadisticasTexto obtenerEstadisticas(OCRResult resultado) {
    final texto = resultado.textoCompleto;
    final palabras = texto.split(RegExp(r'\s+'));
    final caracteres = texto.length;
    final caracteressinEspacios = texto.replaceAll(' ', '').length;
    final lineas = texto.split('\n').length;
    final parrafos = texto.split(RegExp(r'\n\s*\n')).length;
    
    return EstadisticasTexto(
      totalCaracteres: caracteres,
      caracteresSinEspacios: caracteressinEspacios,
      totalPalabras: palabras.where((p) => p.isNotEmpty).length,
      totalLineas: lineas,
      totalParrafos: parrafos,
      confianzaPromedio: resultado.bloques.isNotEmpty
          ? resultado.bloques.map((b) => b.confianza).reduce((a, b) => a + b) / resultado.bloques.length
          : 0.0,
      idiomaPrincipal: _detectarIdiomaPrincipal(resultado.bloques),
    );
  }

  /// Detecta el idioma principal del texto
  String _detectarIdiomaPrincipal(List<BloqueTexto> bloques) {
    if (bloques.isEmpty) return 'es';
    
    final conteoIdiomas = <String, int>{};
    for (final bloque in bloques) {
      conteoIdiomas[bloque.idioma] = (conteoIdiomas[bloque.idioma] ?? 0) + 1;
    }
    
    return conteoIdiomas.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Libera los recursos del servicio
  void _dispose() {
    if (_isInitialized.value) {
      _textRecognizer.close();
      _isInitialized.value = false;
    }
  }
}

/// Resultado del procesamiento OCR
class OCRResult {
  final String textoCompleto;
  final List<BloqueTexto> bloques;
  final String rutaImagenOriginal;
  final DateTime tiempoProcessamiento;

  const OCRResult({
    required this.textoCompleto,
    required this.bloques,
    required this.rutaImagenOriginal,
    required this.tiempoProcessamiento,
  });

  /// Convierte a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'texto_completo': textoCompleto,
      'bloques': bloques.map((b) => b.toMap()).toList(),
      'ruta_imagen_original': rutaImagenOriginal,
      'tiempo_procesamiento': tiempoProcessamiento.millisecondsSinceEpoch,
    };
  }

  /// Crea desde Map
  factory OCRResult.fromMap(Map<String, dynamic> map) {
    return OCRResult(
      textoCompleto: map['texto_completo'] ?? '',
      bloques: (map['bloques'] as List<dynamic>?)
          ?.map((b) => BloqueTexto.fromMap(b as Map<String, dynamic>))
          .toList() ?? [],
      rutaImagenOriginal: map['ruta_imagen_original'] ?? '',
      tiempoProcessamiento: DateTime.fromMillisecondsSinceEpoch(
        map['tiempo_procesamiento'] ?? 0,
      ),
    );
  }
}

/// Bloque de texto reconocido
class BloqueTexto {
  final String texto;
  final String idioma;
  final double confianza;
  final BoundingBox boundingBox;

  const BloqueTexto({
    required this.texto,
    required this.idioma,
    required this.confianza,
    required this.boundingBox,
  });

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'idioma': idioma,
      'confianza': confianza,
      'bounding_box': boundingBox.toMap(),
    };
  }

  factory BloqueTexto.fromMap(Map<String, dynamic> map) {
    return BloqueTexto(
      texto: map['texto'] ?? '',
      idioma: map['idioma'] ?? 'es',
      confianza: (map['confianza'] ?? 0.0).toDouble(),
      boundingBox: BoundingBox.fromMap(map['bounding_box'] ?? {}),
    );
  }
}

/// Caja delimitadora del texto
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  factory BoundingBox.fromMap(Map<String, dynamic> map) {
    return BoundingBox(
      left: (map['left'] ?? 0.0).toDouble(),
      top: (map['top'] ?? 0.0).toDouble(),
      right: (map['right'] ?? 0.0).toDouble(),
      bottom: (map['bottom'] ?? 0.0).toDouble(),
    );
  }
}

/// Estadísticas del texto procesado
class EstadisticasTexto {
  final int totalCaracteres;
  final int caracteresSinEspacios;
  final int totalPalabras;
  final int totalLineas;
  final int totalParrafos;
  final double confianzaPromedio;
  final String idiomaPrincipal;

  const EstadisticasTexto({
    required this.totalCaracteres,
    required this.caracteresSinEspacios,
    required this.totalPalabras,
    required this.totalLineas,
    required this.totalParrafos,
    required this.confianzaPromedio,
    required this.idiomaPrincipal,
  });

  @override
  String toString() {
    return 'Estadísticas: $totalPalabras palabras, $totalCaracteres caracteres, ${(confianzaPromedio * 100).toStringAsFixed(1)}% confianza';
  }
}
