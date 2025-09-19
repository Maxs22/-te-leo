/// Modelo de datos para representar un documento escaneado en Te Leo
/// Contiene toda la información necesaria para almacenar y gestionar documentos
class Documento {
  final int? id;
  final String titulo;
  final String contenido;
  final String? rutaImagen;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final String? etiquetas;
  final bool esFavorito;

  const Documento({
    this.id,
    required this.titulo,
    required this.contenido,
    this.rutaImagen,
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.etiquetas,
    this.esFavorito = false,
  });

  /// Constructor para crear un nuevo documento
  factory Documento.nuevo({
    required String titulo,
    required String contenido,
    String? rutaImagen,
    String? etiquetas,
    bool esFavorito = false,
  }) {
    final ahora = DateTime.now();
    return Documento(
      titulo: titulo,
      contenido: contenido,
      rutaImagen: rutaImagen,
      fechaCreacion: ahora,
      fechaModificacion: ahora,
      etiquetas: etiquetas,
      esFavorito: esFavorito,
    );
  }

  /// Convertir desde Map (útil para base de datos)
  factory Documento.fromMap(Map<String, dynamic> map) {
    return Documento(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      contenido: map['contenido'] as String,
      rutaImagen: map['ruta_imagen'] as String?,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion'] as int),
      fechaModificacion: DateTime.fromMillisecondsSinceEpoch(map['fecha_modificacion'] as int),
      etiquetas: map['etiquetas'] as String?,
      esFavorito: (map['es_favorito'] as int) == 1,
    );
  }

  /// Convertir a Map (útil para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'ruta_imagen': rutaImagen,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
      'fecha_modificacion': fechaModificacion.millisecondsSinceEpoch,
      'etiquetas': etiquetas,
      'es_favorito': esFavorito ? 1 : 0,
    };
  }

  /// Crear una copia del documento con algunos campos modificados
  Documento copyWith({
    int? id,
    String? titulo,
    String? contenido,
    String? rutaImagen,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    String? etiquetas,
    bool? esFavorito,
  }) {
    return Documento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      rutaImagen: rutaImagen ?? this.rutaImagen,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? DateTime.now(),
      etiquetas: etiquetas ?? this.etiquetas,
      esFavorito: esFavorito ?? this.esFavorito,
    );
  }

  /// Obtener un resumen corto del contenido (primeras 100 caracteres)
  String get resumen {
    if (contenido.length <= 100) return contenido;
    return '${contenido.substring(0, 100)}...';
  }

  /// Obtener lista de etiquetas individuales
  List<String> get listaEtiquetas {
    if (etiquetas == null || etiquetas!.isEmpty) return [];
    return etiquetas!.split(',').map((e) => e.trim()).toList();
  }

  /// Verificar si el documento contiene una palabra clave
  bool contienePalabra(String palabra) {
    final palabraBusqueda = palabra.toLowerCase();
    return titulo.toLowerCase().contains(palabraBusqueda) ||
           contenido.toLowerCase().contains(palabraBusqueda) ||
           (etiquetas?.toLowerCase().contains(palabraBusqueda) ?? false);
  }

  @override
  String toString() {
    return 'Documento{id: $id, titulo: $titulo, fechaCreacion: $fechaCreacion, esFavorito: $esFavorito}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Documento &&
           other.id == id &&
           other.titulo == titulo &&
           other.contenido == contenido;
  }

  @override
  int get hashCode {
    return id.hashCode ^ titulo.hashCode ^ contenido.hashCode;
  }
}
