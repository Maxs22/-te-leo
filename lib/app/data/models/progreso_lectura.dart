/// Modelo para guardar el progreso de lectura de documentos
/// Permite reanudar la reproducción desde donde se dejó
class ProgresoLectura {
  final int? id;
  final int documentoId;
  final double porcentajeProgreso; // 0.0 - 1.0
  final int posicionCaracter; // Posición del carácter en el texto
  final int posicionPalabra; // Índice de la palabra actual
  final Duration tiempoReproducido; // Tiempo total reproducido
  final DateTime ultimaActualizacion;
  final String? fragmentoActual; // Fragmento de texto donde se pausó
  final bool estaCompleto; // Si se terminó de leer completamente

  const ProgresoLectura({
    this.id,
    required this.documentoId,
    required this.porcentajeProgreso,
    required this.posicionCaracter,
    required this.posicionPalabra,
    required this.tiempoReproducido,
    required this.ultimaActualizacion,
    this.fragmentoActual,
    this.estaCompleto = false,
  });

  /// Constructor para nuevo progreso
  factory ProgresoLectura.nuevo({
    required int documentoId,
    double porcentajeProgreso = 0.0,
    int posicionCaracter = 0,
    int posicionPalabra = 0,
    Duration tiempoReproducido = Duration.zero,
    String? fragmentoActual,
  }) {
    return ProgresoLectura(
      documentoId: documentoId,
      porcentajeProgreso: porcentajeProgreso,
      posicionCaracter: posicionCaracter,
      posicionPalabra: posicionPalabra,
      tiempoReproducido: tiempoReproducido,
      ultimaActualizacion: DateTime.now(),
      fragmentoActual: fragmentoActual,
    );
  }

  /// Convierte a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documento_id': documentoId,
      'porcentaje_progreso': porcentajeProgreso,
      'posicion_caracter': posicionCaracter,
      'posicion_palabra': posicionPalabra,
      'tiempo_reproducido_ms': tiempoReproducido.inMilliseconds,
      'ultima_actualizacion': ultimaActualizacion.millisecondsSinceEpoch,
      'fragmento_actual': fragmentoActual,
      'esta_completo': estaCompleto ? 1 : 0,
    };
  }

  /// Crea desde Map
  factory ProgresoLectura.fromMap(Map<String, dynamic> map) {
    return ProgresoLectura(
      id: map['id'] as int?,
      documentoId: map['documento_id'] as int,
      porcentajeProgreso: (map['porcentaje_progreso'] as num).toDouble(),
      posicionCaracter: map['posicion_caracter'] as int,
      posicionPalabra: map['posicion_palabra'] as int,
      tiempoReproducido: Duration(
        milliseconds: map['tiempo_reproducido_ms'] as int,
      ),
      ultimaActualizacion: DateTime.fromMillisecondsSinceEpoch(
        map['ultima_actualizacion'] as int,
      ),
      fragmentoActual: map['fragmento_actual'] as String?,
      estaCompleto: (map['esta_completo'] as int) == 1,
    );
  }

  /// Crea una copia con campos modificados
  ProgresoLectura copyWith({
    int? id,
    int? documentoId,
    double? porcentajeProgreso,
    int? posicionCaracter,
    int? posicionPalabra,
    Duration? tiempoReproducido,
    DateTime? ultimaActualizacion,
    String? fragmentoActual,
    bool? estaCompleto,
  }) {
    return ProgresoLectura(
      id: id ?? this.id,
      documentoId: documentoId ?? this.documentoId,
      porcentajeProgreso: porcentajeProgreso ?? this.porcentajeProgreso,
      posicionCaracter: posicionCaracter ?? this.posicionCaracter,
      posicionPalabra: posicionPalabra ?? this.posicionPalabra,
      tiempoReproducido: tiempoReproducido ?? this.tiempoReproducido,
      ultimaActualizacion: ultimaActualizacion ?? DateTime.now(),
      fragmentoActual: fragmentoActual ?? this.fragmentoActual,
      estaCompleto: estaCompleto ?? this.estaCompleto,
    );
  }

  /// Verifica si hay progreso significativo (más del 5%)
  bool get tieneProgresoSignificativo => porcentajeProgreso > 0.05;

  /// Verifica si está cerca del final (más del 90%)
  bool get estaCercaDelFinal => porcentajeProgreso > 0.90;

  /// Obtiene el tiempo restante estimado
  Duration get tiempoRestanteEstimado {
    if (porcentajeProgreso <= 0) return Duration.zero;
    
    final tiempoTotal = Duration(
      milliseconds: (tiempoReproducido.inMilliseconds / porcentajeProgreso).round(),
    );
    
    return tiempoTotal - tiempoReproducido;
  }

  /// Obtiene descripción del progreso para mostrar al usuario
  String get descripcionProgreso {
    if (estaCompleto) return 'Lectura completada';
    if (porcentajeProgreso == 0) return 'Sin progreso';
    
    final porcentaje = (porcentajeProgreso * 100).round();
    final tiempoFormateado = _formatearDuracion(tiempoReproducido);
    
    return 'Progreso: $porcentaje% • Tiempo: $tiempoFormateado';
  }

  /// Obtiene fragmento de contexto alrededor de la posición actual
  String obtenerFragmentoContexto(String textoCompleto, {int longitudContexto = 50}) {
    if (posicionCaracter <= 0 || posicionCaracter >= textoCompleto.length) {
      return textoCompleto.substring(0, longitudContexto.clamp(0, textoCompleto.length));
    }

    final inicio = (posicionCaracter - longitudContexto ~/ 2).clamp(0, textoCompleto.length);
    final fin = (posicionCaracter + longitudContexto ~/ 2).clamp(0, textoCompleto.length);
    
    String fragmento = textoCompleto.substring(inicio, fin);
    
    // Agregar indicadores si el fragmento está cortado
    if (inicio > 0) fragmento = '...$fragmento';
    if (fin < textoCompleto.length) fragmento = '$fragmento...';
    
    return fragmento;
  }

  /// Formatea una duración para mostrar al usuario
  String _formatearDuracion(Duration duracion) {
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    final segundos = duracion.inSeconds % 60;
    
    if (horas > 0) {
      return '${horas}h ${minutos}m';
    } else if (minutos > 0) {
      return '${minutos}m ${segundos}s';
    } else {
      return '${segundos}s';
    }
  }

  @override
  String toString() {
    return 'ProgresoLectura{documentoId: $documentoId, progreso: ${(porcentajeProgreso * 100).round()}%, tiempo: ${_formatearDuracion(tiempoReproducido)}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgresoLectura &&
           other.documentoId == documentoId &&
           other.posicionCaracter == posicionCaracter;
  }

  @override
  int get hashCode {
    return documentoId.hashCode ^ posicionCaracter.hashCode;
  }
}
