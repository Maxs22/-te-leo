/// Tipos de tema disponibles
enum TipoTema {
  sistema,
  claro,
  oscuro,
}

/// Niveles de suscripción
enum NivelSuscripcion {
  gratuito,
  premium,
}

/// Configuración completa del usuario para Te Leo
class ConfiguracionUsuario {
  // Información personal
  final String nombreUsuario;
  final String? email;
  final DateTime fechaRegistro;
  
  // Configuraciones de tema y apariencia
  final TipoTema tema;
  final double tamanoFuente; // 0.8 a 1.5
  final bool modoAltoContraste;
  final String idiomaInterface;
  
  // Configuraciones de TTS
  final String idiomaVoz;
  final String? vozSeleccionada;
  final double velocidadVoz; // 0.1 a 2.0
  final double tonoVoz; // 0.5 a 2.0
  final double volumenVoz; // 0.0 a 1.0
  final bool pausasAutomaticas;
  final int duracionPausas; // en milisegundos
  
  // Configuraciones de OCR
  final bool mejoraAutomaticaImagen;
  final bool deteccionAutomaticaIdioma;
  final double calidadCompresion; // 0.1 a 1.0
  final bool guardadoAutomaticoImagenes;
  
  // Configuraciones de privacidad y datos
  final bool sincronizacionNube; // Premium
  final bool respaldoAutomatico; // Premium
  final bool analiticsAnonimos;
  final bool notificacionesActivadas;
  
  // Configuraciones premium
  final NivelSuscripcion nivelSuscripcion;
  final DateTime? fechaExpiracionPremium;
  final List<String> caracteristicasPremiumUsadas;
  
  // Configuraciones de accesibilidad
  final bool navegacionPorVoz; // Premium
  final bool lecturaAutomaticaMenus;
  final bool vibracionRetroalimentacion;
  final double sensibilidadGestos;
  
  // Estadísticas de uso
  final int documentosEscaneados;
  final int minutosEscuchados;
  final int diasConsecutivos;
  final DateTime fechaUltimoUso;
  final DateTime ultimoAcceso;

  const ConfiguracionUsuario({
    required this.nombreUsuario,
    this.email,
    required this.fechaRegistro,
    this.tema = TipoTema.sistema,
    this.tamanoFuente = 1.0,
    this.modoAltoContraste = false,
    this.idiomaInterface = 'es',
    this.idiomaVoz = 'es-ES',
    this.vozSeleccionada,
    this.velocidadVoz = 0.5,
    this.tonoVoz = 1.0,
    this.volumenVoz = 0.8,
    this.pausasAutomaticas = true,
    this.duracionPausas = 300,
    this.mejoraAutomaticaImagen = true,
    this.deteccionAutomaticaIdioma = true,
    this.calidadCompresion = 0.85,
    this.guardadoAutomaticoImagenes = true,
    this.sincronizacionNube = false,
    this.respaldoAutomatico = false,
    this.analiticsAnonimos = true,
    this.notificacionesActivadas = true,
    this.nivelSuscripcion = NivelSuscripcion.gratuito,
    this.fechaExpiracionPremium,
    this.caracteristicasPremiumUsadas = const [],
    this.navegacionPorVoz = false,
    this.lecturaAutomaticaMenus = false,
    this.vibracionRetroalimentacion = true,
    this.sensibilidadGestos = 0.5,
    this.documentosEscaneados = 0,
    this.minutosEscuchados = 0,
    this.diasConsecutivos = 1,
    required this.fechaUltimoUso,
    required this.ultimoAcceso,
  });

  /// Constructor para nuevo usuario
  factory ConfiguracionUsuario.nuevoUsuario(String nombre) {
    final now = DateTime.now();
    return ConfiguracionUsuario(
      nombreUsuario: nombre,
      fechaRegistro: now,
      fechaUltimoUso: now,
      ultimoAcceso: now,
    );
  }

  /// Convierte a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'nombre_usuario': nombreUsuario,
      'email': email,
      'fecha_registro': fechaRegistro.millisecondsSinceEpoch,
      'tema': tema.toString().split('.').last,
      'tamano_fuente': tamanoFuente,
      'modo_alto_contraste': modoAltoContraste ? 1 : 0,
      'idioma_interface': idiomaInterface,
      'idioma_voz': idiomaVoz,
      'voz_seleccionada': vozSeleccionada,
      'velocidad_voz': velocidadVoz,
      'tono_voz': tonoVoz,
      'volumen_voz': volumenVoz,
      'pausas_automaticas': pausasAutomaticas ? 1 : 0,
      'duracion_pausas': duracionPausas,
      'mejora_automatica_imagen': mejoraAutomaticaImagen ? 1 : 0,
      'deteccion_automatica_idioma': deteccionAutomaticaIdioma ? 1 : 0,
      'calidad_compresion': calidadCompresion,
      'guardado_automatico_imagenes': guardadoAutomaticoImagenes ? 1 : 0,
      'sincronizacion_nube': sincronizacionNube ? 1 : 0,
      'respaldo_automatico': respaldoAutomatico ? 1 : 0,
      'analytics_anonimos': analiticsAnonimos ? 1 : 0,
      'notificaciones_activadas': notificacionesActivadas ? 1 : 0,
      'nivel_suscripcion': nivelSuscripcion.toString().split('.').last,
      'fecha_expiracion_premium': fechaExpiracionPremium?.millisecondsSinceEpoch,
      'caracteristicas_premium_usadas': caracteristicasPremiumUsadas.join(','),
      'navegacion_por_voz': navegacionPorVoz ? 1 : 0,
      'lectura_automatica_menus': lecturaAutomaticaMenus ? 1 : 0,
      'vibracion_retroalimentacion': vibracionRetroalimentacion ? 1 : 0,
      'sensibilidad_gestos': sensibilidadGestos,
      'documentos_escaneados': documentosEscaneados,
      'minutos_escuchados': minutosEscuchados,
      'dias_consecutivos': diasConsecutivos,
      'fecha_ultimo_uso': fechaUltimoUso.millisecondsSinceEpoch,
      'ultimo_acceso': ultimoAcceso.millisecondsSinceEpoch,
    };
  }

  /// Crea desde Map
  factory ConfiguracionUsuario.fromMap(Map<String, dynamic> map) {
    return ConfiguracionUsuario(
      nombreUsuario: map['nombre_usuario'] ?? '',
      email: map['email'],
      fechaRegistro: DateTime.fromMillisecondsSinceEpoch(map['fecha_registro'] ?? 0),
      tema: TipoTema.values.firstWhere(
        (e) => e.toString().split('.').last == map['tema'],
        orElse: () => TipoTema.sistema,
      ),
      tamanoFuente: (map['tamano_fuente'] ?? 1.0).toDouble(),
      modoAltoContraste: (map['modo_alto_contraste'] ?? 0) == 1,
      idiomaInterface: map['idioma_interface'] ?? 'es',
      idiomaVoz: map['idioma_voz'] ?? 'es-ES',
      vozSeleccionada: map['voz_seleccionada'],
      velocidadVoz: (map['velocidad_voz'] ?? 0.5).toDouble(),
      tonoVoz: (map['tono_voz'] ?? 1.0).toDouble(),
      volumenVoz: (map['volumen_voz'] ?? 0.8).toDouble(),
      pausasAutomaticas: (map['pausas_automaticas'] ?? 1) == 1,
      duracionPausas: map['duracion_pausas'] ?? 300,
      mejoraAutomaticaImagen: (map['mejora_automatica_imagen'] ?? 1) == 1,
      deteccionAutomaticaIdioma: (map['deteccion_automatica_idioma'] ?? 1) == 1,
      calidadCompresion: (map['calidad_compresion'] ?? 0.85).toDouble(),
      guardadoAutomaticoImagenes: (map['guardado_automatico_imagenes'] ?? 1) == 1,
      sincronizacionNube: (map['sincronizacion_nube'] ?? 0) == 1,
      respaldoAutomatico: (map['respaldo_automatico'] ?? 0) == 1,
      analiticsAnonimos: (map['analytics_anonimos'] ?? 1) == 1,
      notificacionesActivadas: (map['notificaciones_activadas'] ?? 1) == 1,
      nivelSuscripcion: NivelSuscripcion.values.firstWhere(
        (e) => e.toString().split('.').last == map['nivel_suscripcion'],
        orElse: () => NivelSuscripcion.gratuito,
      ),
      fechaExpiracionPremium: map['fecha_expiracion_premium'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_expiracion_premium'])
          : null,
      caracteristicasPremiumUsadas: map['caracteristicas_premium_usadas'] != null
          ? (map['caracteristicas_premium_usadas'] as String).split(',')
          : [],
      navegacionPorVoz: (map['navegacion_por_voz'] ?? 0) == 1,
      lecturaAutomaticaMenus: (map['lectura_automatica_menus'] ?? 0) == 1,
      vibracionRetroalimentacion: (map['vibracion_retroalimentacion'] ?? 1) == 1,
      sensibilidadGestos: (map['sensibilidad_gestos'] ?? 0.5).toDouble(),
      documentosEscaneados: map['documentos_escaneados'] ?? 0,
      minutosEscuchados: map['minutos_escuchados'] ?? 0,
      diasConsecutivos: map['dias_consecutivos'] ?? 1,
      fechaUltimoUso: DateTime.fromMillisecondsSinceEpoch(
        map['fecha_ultimo_uso'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      ultimoAcceso: DateTime.fromMillisecondsSinceEpoch(
        map['ultimo_acceso'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Crea una copia con campos modificados
  ConfiguracionUsuario copyWith({
    String? nombreUsuario,
    String? email,
    DateTime? fechaRegistro,
    TipoTema? tema,
    double? tamanoFuente,
    bool? modoAltoContraste,
    String? idiomaInterface,
    String? idiomaVoz,
    String? vozSeleccionada,
    double? velocidadVoz,
    double? tonoVoz,
    double? volumenVoz,
    bool? pausasAutomaticas,
    int? duracionPausas,
    bool? mejoraAutomaticaImagen,
    bool? deteccionAutomaticaIdioma,
    double? calidadCompresion,
    bool? guardadoAutomaticoImagenes,
    bool? sincronizacionNube,
    bool? respaldoAutomatico,
    bool? analiticsAnonimos,
    bool? notificacionesActivadas,
    NivelSuscripcion? nivelSuscripcion,
    DateTime? fechaExpiracionPremium,
    List<String>? caracteristicasPremiumUsadas,
    bool? navegacionPorVoz,
    bool? lecturaAutomaticaMenus,
    bool? vibracionRetroalimentacion,
    double? sensibilidadGestos,
    int? documentosEscaneados,
    int? minutosEscuchados,
    int? diasConsecutivos,
    DateTime? fechaUltimoUso,
    DateTime? ultimoAcceso,
  }) {
    return ConfiguracionUsuario(
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      email: email ?? this.email,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      tema: tema ?? this.tema,
      tamanoFuente: tamanoFuente ?? this.tamanoFuente,
      modoAltoContraste: modoAltoContraste ?? this.modoAltoContraste,
      idiomaInterface: idiomaInterface ?? this.idiomaInterface,
      idiomaVoz: idiomaVoz ?? this.idiomaVoz,
      vozSeleccionada: vozSeleccionada ?? this.vozSeleccionada,
      velocidadVoz: velocidadVoz ?? this.velocidadVoz,
      tonoVoz: tonoVoz ?? this.tonoVoz,
      volumenVoz: volumenVoz ?? this.volumenVoz,
      pausasAutomaticas: pausasAutomaticas ?? this.pausasAutomaticas,
      duracionPausas: duracionPausas ?? this.duracionPausas,
      mejoraAutomaticaImagen: mejoraAutomaticaImagen ?? this.mejoraAutomaticaImagen,
      deteccionAutomaticaIdioma: deteccionAutomaticaIdioma ?? this.deteccionAutomaticaIdioma,
      calidadCompresion: calidadCompresion ?? this.calidadCompresion,
      guardadoAutomaticoImagenes: guardadoAutomaticoImagenes ?? this.guardadoAutomaticoImagenes,
      sincronizacionNube: sincronizacionNube ?? this.sincronizacionNube,
      respaldoAutomatico: respaldoAutomatico ?? this.respaldoAutomatico,
      analiticsAnonimos: analiticsAnonimos ?? this.analiticsAnonimos,
      notificacionesActivadas: notificacionesActivadas ?? this.notificacionesActivadas,
      nivelSuscripcion: nivelSuscripcion ?? this.nivelSuscripcion,
      fechaExpiracionPremium: fechaExpiracionPremium ?? this.fechaExpiracionPremium,
      caracteristicasPremiumUsadas: caracteristicasPremiumUsadas ?? this.caracteristicasPremiumUsadas,
      navegacionPorVoz: navegacionPorVoz ?? this.navegacionPorVoz,
      lecturaAutomaticaMenus: lecturaAutomaticaMenus ?? this.lecturaAutomaticaMenus,
      vibracionRetroalimentacion: vibracionRetroalimentacion ?? this.vibracionRetroalimentacion,
      sensibilidadGestos: sensibilidadGestos ?? this.sensibilidadGestos,
      documentosEscaneados: documentosEscaneados ?? this.documentosEscaneados,
      minutosEscuchados: minutosEscuchados ?? this.minutosEscuchados,
      diasConsecutivos: diasConsecutivos ?? this.diasConsecutivos,
      fechaUltimoUso: fechaUltimoUso ?? this.fechaUltimoUso,
      ultimoAcceso: ultimoAcceso ?? DateTime.now(),
    );
  }

  /// Verifica si el usuario tiene premium activo
  bool get tienePremiumActivo {
    if (nivelSuscripcion != NivelSuscripcion.premium) return false;
    if (fechaExpiracionPremium == null) return false;
    return fechaExpiracionPremium!.isAfter(DateTime.now());
  }

  /// Verifica si una característica premium está disponible
  bool puedeUsarCaracteristicaPremium(String caracteristica) {
    return tienePremiumActivo || caracteristicasPremiumUsadas.contains(caracteristica);
  }

  /// Obtiene días restantes de premium
  int get diasRestantesPremium {
    if (fechaExpiracionPremium == null) return 0;
    final diferencia = fechaExpiracionPremium!.difference(DateTime.now());
    return diferencia.inDays.clamp(0, double.infinity).toInt();
  }

  @override
  String toString() {
    return 'ConfiguracionUsuario{nombre: $nombreUsuario, tema: $tema, premium: $tienePremiumActivo}';
  }
}
