import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/modern_dialog.dart';

/// Tipos de error para categorización
enum TipoError {
  red,           // Errores de conectividad
  database,      // Errores de base de datos
  permission,    // Errores de permisos
  validation,    // Errores de validación
  tts,           // Errores de Text-to-Speech
  ocr,           // Errores de reconocimiento de texto
  camera,        // Errores de cámara
  file,          // Errores de archivos
  premium,       // Errores relacionados con Premium
  unknown,       // Errores desconocidos
}

/// Severidad del error
enum SeveridadError {
  info,          // Información
  warning,       // Advertencia
  error,         // Error
  critical,      // Error crítico
}

/// Información detallada de un error
class ErrorInfo {
  final String mensaje;
  final TipoError tipo;
  final SeveridadError severidad;
  final String? codigoError;
  final String? stackTrace;
  final Map<String, dynamic>? contextoAdicional;
  final DateTime timestamp;
  final String? accionSugerida;

  const ErrorInfo({
    required this.mensaje,
    required this.tipo,
    required this.severidad,
    this.codigoError,
    this.stackTrace,
    this.contextoAdicional,
    required this.timestamp,
    this.accionSugerida,
  });

  /// Convierte a Map para logging
  Map<String, dynamic> toMap() {
    return {
      'mensaje': mensaje,
      'tipo': tipo.toString().split('.').last,
      'severidad': severidad.toString().split('.').last,
      'codigo_error': codigoError,
      'stack_trace': stackTrace,
      'contexto_adicional': contextoAdicional,
      'timestamp': timestamp.toIso8601String(),
      'accion_sugerida': accionSugerida,
    };
  }
}

/// Servicio global de manejo de errores para Te Leo
/// Centraliza el manejo, logging y presentación de errores
class ErrorService extends GetxService {
  /// Lista de errores recientes para debugging
  final RxList<ErrorInfo> _erroresRecientes = <ErrorInfo>[].obs;
  List<ErrorInfo> get erroresRecientes => _erroresRecientes;

  /// Límite de errores a mantener en memoria
  final int _maxErroresEnMemoria = 50;

  /// Indica si se debe mostrar información de debug
  final RxBool _debugMode = kDebugMode.obs;
  bool get debugMode => _debugMode.value;

  /// Contador de errores por tipo
  final RxMap<TipoError, int> _contadorErrores = <TipoError, int>{}.obs;
  Map<TipoError, int> get contadorErrores => _contadorErrores;

  @override
  void onInit() {
    super.onInit();
    _initializeErrorService();
  }

  /// Inicializa el servicio de errores
  void _initializeErrorService() {
    // Inicializar contadores
    for (final tipo in TipoError.values) {
      _contadorErrores[tipo] = 0;
    }
    
    if (kDebugMode) {
      print('Error Service inicializado en modo debug');
    }
  }

  /// Maneja un error de forma centralizada
  Future<void> handleError(
    dynamic error, {
    TipoError tipo = TipoError.unknown,
    SeveridadError severidad = SeveridadError.error,
    String? mensajePersonalizado,
    String? codigoError,
    Map<String, dynamic>? contexto,
    bool mostrarAlUsuario = true,
    String? accionSugerida,
  }) async {
    try {
      // Crear información del error
      final errorInfo = ErrorInfo(
        mensaje: mensajePersonalizado ?? _extraerMensajeError(error),
        tipo: tipo,
        severidad: severidad,
        codigoError: codigoError,
        stackTrace: _debugMode.value ? error.toString() : null,
        contextoAdicional: contexto,
        timestamp: DateTime.now(),
        accionSugerida: accionSugerida ?? _obtenerAccionSugerida(tipo),
      );

      // Registrar error
      _registrarError(errorInfo);

      // Mostrar al usuario si es necesario
      if (mostrarAlUsuario) {
        await _mostrarErrorAlUsuario(errorInfo);
      }

      // Log en consola para desarrollo
      _logError(errorInfo);

    } catch (e) {
      // Error en el manejo de errores - usar fallback
      if (kDebugMode) {
        print('Error en ErrorService: $e');
      }
      _mostrarErrorFallback(error.toString());
    }
  }

  /// Maneja errores específicos de TTS
  Future<void> handleTTSError(dynamic error, {String? contexto}) async {
    await handleError(
      error,
      tipo: TipoError.tts,
      mensajePersonalizado: 'Error en la reproducción de voz: ${_extraerMensajeError(error)}',
      contexto: {'contexto_tts': contexto},
      accionSugerida: 'Verifica la configuración de voz en Configuraciones',
    );
  }

  /// Maneja errores específicos de OCR
  Future<void> handleOCRError(dynamic error, {String? rutaImagen}) async {
    await handleError(
      error,
      tipo: TipoError.ocr,
      mensajePersonalizado: 'Error procesando la imagen: ${_extraerMensajeError(error)}',
      contexto: {'ruta_imagen': rutaImagen},
      accionSugerida: 'Intenta con una imagen más clara y con mejor iluminación',
    );
  }

  /// Maneja errores específicos de base de datos
  Future<void> handleDatabaseError(dynamic error, {String? operacion}) async {
    await handleError(
      error,
      tipo: TipoError.database,
      severidad: SeveridadError.critical,
      mensajePersonalizado: 'Error en la base de datos: ${_extraerMensajeError(error)}',
      contexto: {'operacion': operacion},
      accionSugerida: 'Reinicia la aplicación. Si persiste, contacta soporte',
    );
  }

  /// Maneja errores específicos de cámara
  Future<void> handleCameraError(dynamic error, {String? accion}) async {
    await handleError(
      error,
      tipo: TipoError.camera,
      mensajePersonalizado: 'Error con la cámara: ${_extraerMensajeError(error)}',
      contexto: {'accion_camara': accion},
      accionSugerida: 'Verifica los permisos de cámara en la configuración del dispositivo',
    );
  }

  /// Maneja errores específicos de permisos
  Future<void> handlePermissionError(String permiso, {String? mensaje}) async {
    await handleError(
      'Permiso denegado: $permiso',
      tipo: TipoError.permission,
      severidad: SeveridadError.warning,
      mensajePersonalizado: mensaje ?? 'Permiso necesario: $permiso',
      contexto: {'permiso_requerido': permiso},
      accionSugerida: 'Ve a Configuración del dispositivo > Aplicaciones > Te Leo > Permisos',
    );
  }

  /// Maneja errores específicos de validación
  Future<void> handleValidationError(String campo, String mensaje) async {
    await handleError(
      'Validación fallida: $campo',
      tipo: TipoError.validation,
      severidad: SeveridadError.warning,
      mensajePersonalizado: mensaje,
      contexto: {'campo': campo},
      mostrarAlUsuario: true,
    );
  }

  /// Maneja errores específicos de Premium
  Future<void> handlePremiumError(String caracteristica) async {
    await handleError(
      'Característica Premium requerida: $caracteristica',
      tipo: TipoError.premium,
      severidad: SeveridadError.info,
      mensajePersonalizado: 'Esta característica requiere Te Leo Premium',
      contexto: {'caracteristica_premium': caracteristica},
      accionSugerida: 'Obtén Te Leo Premium para desbloquear todas las características',
    );
  }

  /// Registra el error en la lista interna
  void _registrarError(ErrorInfo errorInfo) {
    _erroresRecientes.insert(0, errorInfo);
    
    // Mantener solo los errores más recientes
    if (_erroresRecientes.length > _maxErroresEnMemoria) {
      _erroresRecientes.removeRange(_maxErroresEnMemoria, _erroresRecientes.length);
    }
    
    // Actualizar contador
    _contadorErrores[errorInfo.tipo] = (_contadorErrores[errorInfo.tipo] ?? 0) + 1;
  }

  /// Muestra el error al usuario
  Future<void> _mostrarErrorAlUsuario(ErrorInfo errorInfo) async {
    final icono = _obtenerIconoError(errorInfo.tipo);
    final color = _obtenerColorError(errorInfo.severidad);
    
    switch (errorInfo.severidad) {
      case SeveridadError.info:
        await ModernDialog.mostrarInformacion(
          titulo: _obtenerTituloError(errorInfo.tipo),
          mensaje: errorInfo.mensaje,
          icono: icono,
          colorIcono: color,
        );
        break;
        
      case SeveridadError.warning:
        Get.snackbar(
          'Advertencia',
          errorInfo.mensaje,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
          icon: Icon(icono, color: Colors.orange),
          duration: const Duration(seconds: 4),
        );
        break;
        
      case SeveridadError.error:
      case SeveridadError.critical:
        await ModernDialog.mostrarError(
          titulo: _obtenerTituloError(errorInfo.tipo),
          mensaje: errorInfo.mensaje,
        );
        break;
    }
  }

  /// Muestra error de fallback si falla el servicio
  void _mostrarErrorFallback(String mensaje) {
    Get.snackbar(
      'Error',
      mensaje,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      duration: const Duration(seconds: 3),
    );
  }

  /// Registra el error en consola para desarrollo
  void _logError(ErrorInfo errorInfo) {
    if (!kDebugMode) return;
    
    final severitySymbol = _obtenerSimboloSeveridad(errorInfo.severidad);
    print('$severitySymbol [${errorInfo.tipo.toString().split('.').last.toUpperCase()}] ${errorInfo.mensaje}');
    
    if (errorInfo.stackTrace != null) {
      print('Stack trace: ${errorInfo.stackTrace}');
    }
    
    if (errorInfo.contextoAdicional != null) {
      print('Contexto: ${errorInfo.contextoAdicional}');
    }
  }

  /// Extrae mensaje legible del error
  String _extraerMensajeError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else if (error is Error) {
      return error.toString();
    } else {
      return error.toString();
    }
  }

  /// Obtiene acción sugerida basada en el tipo de error
  String _obtenerAccionSugerida(TipoError tipo) {
    switch (tipo) {
      case TipoError.red:
        return 'Verifica tu conexión a internet';
      case TipoError.database:
        return 'Reinicia la aplicación';
      case TipoError.permission:
        return 'Otorga los permisos necesarios';
      case TipoError.validation:
        return 'Verifica la información ingresada';
      case TipoError.tts:
        return 'Revisa la configuración de voz';
      case TipoError.ocr:
        return 'Usa una imagen más clara';
      case TipoError.camera:
        return 'Verifica los permisos de cámara';
      case TipoError.file:
        return 'Verifica el espacio disponible';
      case TipoError.premium:
        return 'Considera obtener Te Leo Premium';
      case TipoError.unknown:
        return 'Intenta nuevamente o contacta soporte';
    }
  }

  /// Obtiene icono para el tipo de error
  IconData _obtenerIconoError(TipoError tipo) {
    switch (tipo) {
      case TipoError.red:
        return Icons.wifi_off;
      case TipoError.database:
        return Icons.storage;
      case TipoError.permission:
        return Icons.lock;
      case TipoError.validation:
        return Icons.warning;
      case TipoError.tts:
        return Icons.volume_off;
      case TipoError.ocr:
        return Icons.text_fields;
      case TipoError.camera:
        return Icons.camera_alt;
      case TipoError.file:
        return Icons.folder;
      case TipoError.premium:
        return Icons.star;
      case TipoError.unknown:
        return Icons.error;
    }
  }

  /// Obtiene color para la severidad del error
  Color _obtenerColorError(SeveridadError severidad) {
    switch (severidad) {
      case SeveridadError.info:
        return Colors.blue;
      case SeveridadError.warning:
        return Colors.orange;
      case SeveridadError.error:
        return Colors.red;
      case SeveridadError.critical:
        return Colors.red.shade800;
    }
  }

  /// Obtiene título para el tipo de error
  String _obtenerTituloError(TipoError tipo) {
    switch (tipo) {
      case TipoError.red:
        return 'Error de conexión';
      case TipoError.database:
        return 'Error de base de datos';
      case TipoError.permission:
        return 'Permisos requeridos';
      case TipoError.validation:
        return 'Datos incorrectos';
      case TipoError.tts:
        return 'Error de voz';
      case TipoError.ocr:
        return 'Error de reconocimiento';
      case TipoError.camera:
        return 'Error de cámara';
      case TipoError.file:
        return 'Error de archivo';
      case TipoError.premium:
        return 'Característica Premium';
      case TipoError.unknown:
        return 'Error inesperado';
    }
  }

  /// Obtiene símbolo para logging
  String _obtenerSimboloSeveridad(SeveridadError severidad) {
    switch (severidad) {
      case SeveridadError.info:
        return 'ℹ️';
      case SeveridadError.warning:
        return '⚠️';
      case SeveridadError.error:
        return '❌';
      case SeveridadError.critical:
        return '🚨';
    }
  }

  /// Limpia errores antiguos
  void limpiarErroresAntiguos({Duration antiguedad = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(antiguedad);
    _erroresRecientes.removeWhere((error) => error.timestamp.isBefore(cutoff));
  }

  /// Obtiene estadísticas de errores
  Map<String, dynamic> obtenerEstadisticas() {
    final total = _erroresRecientes.length;
    final porTipo = <String, int>{};
    final porSeveridad = <String, int>{};
    
    for (final error in _erroresRecientes) {
      final tipo = error.tipo.toString().split('.').last;
      final severidad = error.severidad.toString().split('.').last;
      
      porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
      porSeveridad[severidad] = (porSeveridad[severidad] ?? 0) + 1;
    }
    
    return {
      'total_errores': total,
      'errores_por_tipo': porTipo,
      'errores_por_severidad': porSeveridad,
      'ultimo_error': _erroresRecientes.isNotEmpty 
          ? _erroresRecientes.first.timestamp.toIso8601String()
          : null,
    };
  }

  /// Exporta log de errores para soporte
  String exportarLogErrores() {
    final buffer = StringBuffer();
    buffer.writeln('=== Te Leo - Log de Errores ===');
    buffer.writeln('Fecha de exportación: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total de errores: ${_erroresRecientes.length}');
    buffer.writeln('');
    
    for (final error in _erroresRecientes) {
      buffer.writeln('--- Error ${_erroresRecientes.indexOf(error) + 1} ---');
      buffer.writeln('Fecha: ${error.timestamp.toIso8601String()}');
      buffer.writeln('Tipo: ${error.tipo.toString().split('.').last}');
      buffer.writeln('Severidad: ${error.severidad.toString().split('.').last}');
      buffer.writeln('Mensaje: ${error.mensaje}');
      
      if (error.codigoError != null) {
        buffer.writeln('Código: ${error.codigoError}');
      }
      
      if (error.accionSugerida != null) {
        buffer.writeln('Acción sugerida: ${error.accionSugerida}');
      }
      
      if (error.contextoAdicional != null) {
        buffer.writeln('Contexto: ${error.contextoAdicional}');
      }
      
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// Muestra pantalla de diagnóstico (solo en debug)
  void mostrarDiagnostico() {
    if (!kDebugMode) return;
    
    Get.dialog(
      ModernDialog(
        titulo: 'Diagnóstico de Errores',
        contenidoWidget: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total de errores: ${_erroresRecientes.length}'),
                const SizedBox(height: 16),
                
                ...TipoError.values.map((tipo) {
                  final count = _contadorErrores[tipo] ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(_obtenerIconoError(tipo), size: 16),
                        const SizedBox(width: 8),
                        Text('${tipo.toString().split('.').last}: $count'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        textoBotonPrimario: 'Cerrar',
      ),
    );
  }
}

/// Extension para facilitar el uso del ErrorService
extension ErrorHandling on Object {
  /// Maneja este error usando el servicio global
  Future<void> handleAsError({
    TipoError tipo = TipoError.unknown,
    SeveridadError severidad = SeveridadError.error,
    String? mensaje,
    Map<String, dynamic>? contexto,
    bool mostrarAlUsuario = true,
  }) async {
    final errorService = Get.find<ErrorService>();
    await errorService.handleError(
      this,
      tipo: tipo,
      severidad: severidad,
      mensajePersonalizado: mensaje,
      contexto: contexto,
      mostrarAlUsuario: mostrarAlUsuario,
    );
  }
}
