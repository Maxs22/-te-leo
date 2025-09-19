/// Modelo de datos para licencias de Te Leo
class Licencia {
  final String id;
  final TipoLicencia tipo;
  final DateTime fechaInicio;
  final DateTime fechaExpiracion;
  final EstadoLicencia estado;
  final String? usuarioId;
  final Map<String, dynamic>? metadata;
  final List<String> caracteristicasHabilitadas;
  final String? tokenValidacion;
  final DateTime? ultimaValidacion;

  const Licencia({
    required this.id,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaExpiracion,
    required this.estado,
    this.usuarioId,
    this.metadata,
    this.caracteristicasHabilitadas = const [],
    this.tokenValidacion,
    this.ultimaValidacion,
  });

  /// Crear licencia gratuita
  factory Licencia.gratuita() {
    final ahora = DateTime.now();
    return Licencia(
      id: 'free_${ahora.millisecondsSinceEpoch}',
      tipo: TipoLicencia.gratuita,
      fechaInicio: ahora,
      fechaExpiracion: ahora.add(const Duration(days: 365 * 10)), // 10 años
      estado: EstadoLicencia.activa,
      caracteristicasHabilitadas: [
        'ocr_basico',
        'tts_basico',
        'biblioteca_local',
        'configuraciones_basicas',
      ],
    );
  }

  /// Crear licencia premium mensual
  factory Licencia.premiumMensual({
    required String usuarioId,
    String? tokenValidacion,
  }) {
    final ahora = DateTime.now();
    return Licencia(
      id: 'premium_monthly_${ahora.millisecondsSinceEpoch}',
      tipo: TipoLicencia.premiumMensual,
      fechaInicio: ahora,
      fechaExpiracion: ahora.add(const Duration(days: 30)),
      estado: EstadoLicencia.activa,
      usuarioId: usuarioId,
      tokenValidacion: tokenValidacion,
      ultimaValidacion: ahora,
      caracteristicasHabilitadas: [
        'ocr_basico',
        'ocr_avanzado',
        'tts_basico',
        'tts_premium',
        'biblioteca_local',
        'biblioteca_nube',
        'configuraciones_basicas',
        'configuraciones_avanzadas',
        'exportar_documentos',
        'sin_anuncios',
        'soporte_prioritario',
      ],
    );
  }

  /// Crear licencia premium anual
  factory Licencia.premiumAnual({
    required String usuarioId,
    String? tokenValidacion,
  }) {
    final ahora = DateTime.now();
    return Licencia(
      id: 'premium_yearly_${ahora.millisecondsSinceEpoch}',
      tipo: TipoLicencia.premiumAnual,
      fechaInicio: ahora,
      fechaExpiracion: ahora.add(const Duration(days: 365)),
      estado: EstadoLicencia.activa,
      usuarioId: usuarioId,
      tokenValidacion: tokenValidacion,
      ultimaValidacion: ahora,
      caracteristicasHabilitadas: [
        'ocr_basico',
        'ocr_avanzado',
        'ocr_batch',
        'tts_basico',
        'tts_premium',
        'tts_voces_adicionales',
        'biblioteca_local',
        'biblioteca_nube',
        'configuraciones_basicas',
        'configuraciones_avanzadas',
        'exportar_documentos',
        'exportar_formatos_premium',
        'sin_anuncios',
        'soporte_prioritario',
        'funciones_beta',
      ],
    );
  }

  /// Crear licencia demo
  factory Licencia.demo() {
    final ahora = DateTime.now();
    return Licencia(
      id: 'demo_${ahora.millisecondsSinceEpoch}',
      tipo: TipoLicencia.demo,
      fechaInicio: ahora,
      fechaExpiracion: ahora.add(const Duration(days: 7)), // 7 días
      estado: EstadoLicencia.activa,
      caracteristicasHabilitadas: [
        'ocr_basico',
        'ocr_avanzado', // Limitado
        'tts_basico',
        'tts_premium', // Limitado
        'biblioteca_local',
        'configuraciones_basicas',
        'exportar_documentos', // Limitado
      ],
      metadata: {
        'limite_documentos': 10,
        'limite_exportaciones': 3,
        'limite_ocr_diario': 20,
      },
    );
  }

  /// Verificar si la licencia está activa
  bool get esActiva {
    final ahora = DateTime.now();
    return estado == EstadoLicencia.activa && 
           ahora.isBefore(fechaExpiracion) &&
           ahora.isAfter(fechaInicio);
  }

  /// Verificar si la licencia ha expirado
  bool get haExpirado {
    return DateTime.now().isAfter(fechaExpiracion);
  }

  /// Verificar si es licencia premium
  bool get esPremium {
    return tipo == TipoLicencia.premiumMensual || 
           tipo == TipoLicencia.premiumAnual;
  }

  /// Verificar si es licencia gratuita
  bool get esGratuita {
    return tipo == TipoLicencia.gratuita;
  }

  /// Verificar si es modo demo
  bool get esDemo {
    return tipo == TipoLicencia.demo;
  }

  /// Días restantes hasta expiración
  int get diasRestantes {
    if (haExpirado) return 0;
    return fechaExpiracion.difference(DateTime.now()).inDays;
  }

  /// Verificar si tiene una característica específica
  bool tieneCaracteristica(String caracteristica) {
    return esActiva && caracteristicasHabilitadas.contains(caracteristica);
  }

  /// Obtener límite para una característica (si existe)
  int? obtenerLimite(String caracteristica) {
    if (!esActiva) return 0;
    return metadata?['limite_$caracteristica'] as int?;
  }

  /// Verificar si necesita renovación pronto (menos de 3 días)
  bool get necesitaRenovacion {
    return esActiva && diasRestantes <= 3;
  }

  /// Convertir a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.toString(),
      'fechaInicio': fechaInicio.millisecondsSinceEpoch,
      'fechaExpiracion': fechaExpiracion.millisecondsSinceEpoch,
      'estado': estado.toString(),
      'usuarioId': usuarioId,
      'metadata': metadata,
      'caracteristicasHabilitadas': caracteristicasHabilitadas,
      'tokenValidacion': tokenValidacion,
      'ultimaValidacion': ultimaValidacion?.millisecondsSinceEpoch,
    };
  }

  /// Crear desde Map
  factory Licencia.fromMap(Map<String, dynamic> map) {
    return Licencia(
      id: map['id'] ?? '',
      tipo: TipoLicencia.values.firstWhere(
        (e) => e.toString() == map['tipo'],
        orElse: () => TipoLicencia.gratuita,
      ),
      fechaInicio: DateTime.fromMillisecondsSinceEpoch(map['fechaInicio'] ?? 0),
      fechaExpiracion: DateTime.fromMillisecondsSinceEpoch(map['fechaExpiracion'] ?? 0),
      estado: EstadoLicencia.values.firstWhere(
        (e) => e.toString() == map['estado'],
        orElse: () => EstadoLicencia.inactiva,
      ),
      usuarioId: map['usuarioId'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      caracteristicasHabilitadas: List<String>.from(map['caracteristicasHabilitadas'] ?? []),
      tokenValidacion: map['tokenValidacion'],
      ultimaValidacion: map['ultimaValidacion'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['ultimaValidacion'])
          : null,
    );
  }

  /// Crear copia con cambios
  Licencia copyWith({
    String? id,
    TipoLicencia? tipo,
    DateTime? fechaInicio,
    DateTime? fechaExpiracion,
    EstadoLicencia? estado,
    String? usuarioId,
    Map<String, dynamic>? metadata,
    List<String>? caracteristicasHabilitadas,
    String? tokenValidacion,
    DateTime? ultimaValidacion,
  }) {
    return Licencia(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      estado: estado ?? this.estado,
      usuarioId: usuarioId ?? this.usuarioId,
      metadata: metadata ?? this.metadata,
      caracteristicasHabilitadas: caracteristicasHabilitadas ?? this.caracteristicasHabilitadas,
      tokenValidacion: tokenValidacion ?? this.tokenValidacion,
      ultimaValidacion: ultimaValidacion ?? this.ultimaValidacion,
    );
  }

  @override
  String toString() {
    return 'Licencia(id: $id, tipo: $tipo, estado: $estado, expira: $fechaExpiracion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Licencia && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Tipos de licencia disponibles
enum TipoLicencia {
  gratuita,
  demo,
  premiumMensual,
  premiumAnual,
}

/// Estados de licencia
enum EstadoLicencia {
  activa,
  inactiva,
  suspendida,
  expirada,
  cancelada,
}

/// Extensiones para tipos de licencia
extension TipoLicenciaExtension on TipoLicencia {
  String get nombre {
    switch (this) {
      case TipoLicencia.gratuita:
        return 'Gratuita';
      case TipoLicencia.demo:
        return 'Demo';
      case TipoLicencia.premiumMensual:
        return 'Premium Mensual';
      case TipoLicencia.premiumAnual:
        return 'Premium Anual';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoLicencia.gratuita:
        return 'Funciones básicas sin límite de tiempo';
      case TipoLicencia.demo:
        return 'Acceso completo por tiempo limitado';
      case TipoLicencia.premiumMensual:
        return 'Todas las funciones, renovación mensual';
      case TipoLicencia.premiumAnual:
        return 'Todas las funciones, renovación anual con descuento';
    }
  }

  double get precio {
    switch (this) {
      case TipoLicencia.gratuita:
        return 0.0;
      case TipoLicencia.demo:
        return 0.0;
      case TipoLicencia.premiumMensual:
        return 2.99;
      case TipoLicencia.premiumAnual:
        return 29.99;
    }
  }
}
