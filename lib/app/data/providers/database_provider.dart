import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/documento.dart';
import '../models/progreso_lectura.dart';

/// Proveedor de base de datos local para Te Leo
/// Gestiona la persistencia de documentos usando SQLite
class DatabaseProvider {
  static const String _databaseName = 'te_leo.db';
  static const int _databaseVersion = 2;
  
  static const String _tableName = 'documentos';
  static const String _progressTableName = 'progreso_lectura';
  
  // Singleton pattern
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();
  
  Database? _database;

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas de la base de datos
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de documentos
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        contenido TEXT NOT NULL,
        ruta_imagen TEXT,
        fecha_creacion INTEGER NOT NULL,
        fecha_modificacion INTEGER NOT NULL,
        etiquetas TEXT,
        es_favorito INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de progreso de lectura
    await db.execute('''
      CREATE TABLE $_progressTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documento_id INTEGER NOT NULL,
        porcentaje_progreso REAL NOT NULL DEFAULT 0.0,
        posicion_caracter INTEGER NOT NULL DEFAULT 0,
        posicion_palabra INTEGER NOT NULL DEFAULT 0,
        tiempo_reproducido_ms INTEGER NOT NULL DEFAULT 0,
        ultima_actualizacion INTEGER NOT NULL,
        fragmento_actual TEXT,
        esta_completo INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (documento_id) REFERENCES $_tableName (id) ON DELETE CASCADE,
        UNIQUE(documento_id)
      )
    ''');

    // Crear índices para mejorar el rendimiento de búsquedas
    await db.execute('CREATE INDEX idx_titulo ON $_tableName(titulo)');
    await db.execute('CREATE INDEX idx_fecha_creacion ON $_tableName(fecha_creacion)');
    await db.execute('CREATE INDEX idx_es_favorito ON $_tableName(es_favorito)');
    await db.execute('CREATE INDEX idx_progreso_documento ON $_progressTableName(documento_id)');
    await db.execute('CREATE INDEX idx_progreso_actualizacion ON $_progressTableName(ultima_actualizacion)');
  }

  /// Maneja las actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar tabla de progreso de lectura en versión 2
      await db.execute('''
        CREATE TABLE $_progressTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          documento_id INTEGER NOT NULL,
          porcentaje_progreso REAL NOT NULL DEFAULT 0.0,
          posicion_caracter INTEGER NOT NULL DEFAULT 0,
          posicion_palabra INTEGER NOT NULL DEFAULT 0,
          tiempo_reproducido_ms INTEGER NOT NULL DEFAULT 0,
          ultima_actualizacion INTEGER NOT NULL,
          fragmento_actual TEXT,
          esta_completo INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (documento_id) REFERENCES $_tableName (id) ON DELETE CASCADE,
          UNIQUE(documento_id)
        )
      ''');
      
      // Crear índices para la nueva tabla
      await db.execute('CREATE INDEX idx_progreso_documento ON $_progressTableName(documento_id)');
      await db.execute('CREATE INDEX idx_progreso_actualizacion ON $_progressTableName(ultima_actualizacion)');
    }
  }

  /// Inserta un nuevo documento
  Future<int> insertarDocumento(Documento documento) async {
    final db = await database;
    final map = documento.toMap();
    map.remove('id'); // Remover ID para auto-incremento
    
    return await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todos los documentos
  Future<List<Documento>> obtenerTodosLosDocumentos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'fecha_modificacion DESC',
    );

    return List.generate(maps.length, (i) => Documento.fromMap(maps[i]));
  }

  /// Obtiene un documento por ID
  Future<Documento?> obtenerDocumentoPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Documento.fromMap(maps.first);
    }
    return null;
  }

  /// Actualiza un documento existente
  Future<int> actualizarDocumento(Documento documento) async {
    final db = await database;
    final map = documento.copyWith(fechaModificacion: DateTime.now()).toMap();
    
    return await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [documento.id],
    );
  }

  /// Elimina un documento
  Future<int> eliminarDocumento(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca documentos por palabra clave
  Future<List<Documento>> buscarDocumentos(String palabraClave) async {
    final db = await database;
    final palabraBusqueda = '%${palabraClave.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'LOWER(titulo) LIKE ? OR LOWER(contenido) LIKE ? OR LOWER(etiquetas) LIKE ?',
      whereArgs: [palabraBusqueda, palabraBusqueda, palabraBusqueda],
      orderBy: 'fecha_modificacion DESC',
    );

    return List.generate(maps.length, (i) => Documento.fromMap(maps[i]));
  }

  /// Obtiene documentos favoritos
  Future<List<Documento>> obtenerDocumentosFavoritos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'es_favorito = ?',
      whereArgs: [1],
      orderBy: 'fecha_modificacion DESC',
    );

    return List.generate(maps.length, (i) => Documento.fromMap(maps[i]));
  }

  /// Obtiene el número total de documentos
  Future<int> contarDocumentos() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtiene documentos por rango de fechas
  Future<List<Documento>> obtenerDocumentosPorFecha({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (fechaInicio != null) {
      where += 'fecha_creacion >= ?';
      whereArgs.add(fechaInicio.millisecondsSinceEpoch);
    }

    if (fechaFin != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'fecha_creacion <= ?';
      whereArgs.add(fechaFin.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'fecha_creacion DESC',
    );

    return List.generate(maps.length, (i) => Documento.fromMap(maps[i]));
  }

  // ========== MÉTODOS PARA PROGRESO DE LECTURA ==========

  /// Guarda o actualiza el progreso de lectura de un documento
  Future<void> guardarProgresoLectura(ProgresoLectura progreso) async {
    final db = await database;
    final map = progreso.toMap();
    map.remove('id'); // Remover ID para manejo automático
    
    await db.insert(
      _progressTableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene el progreso de lectura de un documento
  Future<ProgresoLectura?> obtenerProgresoLectura(int documentoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _progressTableName,
      where: 'documento_id = ?',
      whereArgs: [documentoId],
    );

    if (maps.isNotEmpty) {
      return ProgresoLectura.fromMap(maps.first);
    }
    return null;
  }

  /// Actualiza el progreso de lectura de un documento
  Future<void> actualizarProgresoLectura({
    required int documentoId,
    double? porcentajeProgreso,
    int? posicionCaracter,
    int? posicionPalabra,
    Duration? tiempoReproducido,
    String? fragmentoActual,
    bool? estaCompleto,
  }) async {
    final db = await database;
    
    // Obtener progreso existente o crear uno nuevo
    final progresoExistente = await obtenerProgresoLectura(documentoId);
    
    final Map<String, dynamic> updates = {
      'ultima_actualizacion': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (porcentajeProgreso != null) updates['porcentaje_progreso'] = porcentajeProgreso;
    if (posicionCaracter != null) updates['posicion_caracter'] = posicionCaracter;
    if (posicionPalabra != null) updates['posicion_palabra'] = posicionPalabra;
    if (tiempoReproducido != null) updates['tiempo_reproducido_ms'] = tiempoReproducido.inMilliseconds;
    if (fragmentoActual != null) updates['fragmento_actual'] = fragmentoActual;
    if (estaCompleto != null) updates['esta_completo'] = estaCompleto ? 1 : 0;

    if (progresoExistente != null) {
      // Actualizar progreso existente
      await db.update(
        _progressTableName,
        updates,
        where: 'documento_id = ?',
        whereArgs: [documentoId],
      );
    } else {
      // Crear nuevo progreso
      updates['documento_id'] = documentoId;
      updates['porcentaje_progreso'] = porcentajeProgreso ?? 0.0;
      updates['posicion_caracter'] = posicionCaracter ?? 0;
      updates['posicion_palabra'] = posicionPalabra ?? 0;
      updates['tiempo_reproducido_ms'] = tiempoReproducido?.inMilliseconds ?? 0;
      updates['esta_completo'] = estaCompleto == true ? 1 : 0;
      
      await db.insert(_progressTableName, updates);
    }
  }

  /// Elimina el progreso de lectura de un documento
  Future<void> eliminarProgresoLectura(int documentoId) async {
    final db = await database;
    await db.delete(
      _progressTableName,
      where: 'documento_id = ?',
      whereArgs: [documentoId],
    );
  }

  /// Obtiene todos los documentos con su progreso de lectura
  Future<List<Map<String, dynamic>>> obtenerDocumentosConProgreso() async {
    final db = await database;
    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT 
        d.*,
        p.porcentaje_progreso,
        p.posicion_caracter,
        p.posicion_palabra,
        p.tiempo_reproducido_ms,
        p.ultima_actualizacion as progreso_actualizacion,
        p.fragmento_actual,
        p.esta_completo
      FROM $_tableName d
      LEFT JOIN $_progressTableName p ON d.id = p.documento_id
      ORDER BY d.fecha_modificacion DESC
    ''');
    
    return resultado;
  }

  /// Obtiene documentos con progreso parcial (no completados)
  Future<List<Map<String, dynamic>>> obtenerDocumentosEnProgreso() async {
    final db = await database;
    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT 
        d.*,
        p.porcentaje_progreso,
        p.posicion_caracter,
        p.posicion_palabra,
        p.tiempo_reproducido_ms,
        p.ultima_actualizacion as progreso_actualizacion,
        p.fragmento_actual
      FROM $_tableName d
      INNER JOIN $_progressTableName p ON d.id = p.documento_id
      WHERE p.porcentaje_progreso > 0.05 AND p.esta_completo = 0
      ORDER BY p.ultima_actualizacion DESC
    ''');
    
    return resultado;
  }

  /// Marca un documento como completamente leído
  Future<void> marcarDocumentoComoCompleto(int documentoId) async {
    await actualizarProgresoLectura(
      documentoId: documentoId,
      porcentajeProgreso: 1.0,
      estaCompleto: true,
    );
  }

  /// Reinicia el progreso de un documento
  Future<void> reiniciarProgresoLectura(int documentoId) async {
    await actualizarProgresoLectura(
      documentoId: documentoId,
      porcentajeProgreso: 0.0,
      posicionCaracter: 0,
      posicionPalabra: 0,
      tiempoReproducido: Duration.zero,
      fragmentoActual: null,
      estaCompleto: false,
    );
  }

  /// Obtiene estadísticas de progreso de lectura
  Future<Map<String, int>> obtenerEstadisticasProgreso() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM $_progressTableName');
    final completosResult = await db.rawQuery('SELECT COUNT(*) FROM $_progressTableName WHERE esta_completo = 1');
    final enProgresoResult = await db.rawQuery('SELECT COUNT(*) FROM $_progressTableName WHERE porcentaje_progreso > 0.05 AND esta_completo = 0');
    
    return {
      'total_con_progreso': Sqflite.firstIntValue(totalResult) ?? 0,
      'documentos_completos': Sqflite.firstIntValue(completosResult) ?? 0,
      'documentos_en_progreso': Sqflite.firstIntValue(enProgresoResult) ?? 0,
    };
  }

  /// Limpia toda la base de datos (útil para desarrollo/testing)
  Future<void> limpiarBaseDatos() async {
    final db = await database;
    await db.delete(_tableName);
    await db.delete(_progressTableName);
  }

  /// Cierra la base de datos
  Future<void> cerrarBaseDatos() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Obtiene estadísticas de la base de datos
  Future<Map<String, int>> obtenerEstadisticas() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    final favoritosResult = await db.rawQuery('SELECT COUNT(*) FROM $_tableName WHERE es_favorito = 1');
    final hoyResult = await db.rawQuery(
      'SELECT COUNT(*) FROM $_tableName WHERE fecha_creacion >= ?',
      [DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'favoritos': Sqflite.firstIntValue(favoritosResult) ?? 0,
      'hoy': Sqflite.firstIntValue(hoyResult) ?? 0,
    };
  }
}
