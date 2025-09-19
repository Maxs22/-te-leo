import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/configuracion_usuario.dart';

/// Proveedor de configuraciones del usuario para Te Leo
/// Gestiona la persistencia de todas las configuraciones y preferencias
class ConfiguracionProvider {
  static const String _databaseName = 'te_leo_config.db';
  static const int _databaseVersion = 2;
  static const String _tableName = 'configuracion_usuario';
  
  // Singleton pattern
  static final ConfiguracionProvider _instance = ConfiguracionProvider._internal();
  factory ConfiguracionProvider() => _instance;
  ConfiguracionProvider._internal();
  
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
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_usuario TEXT NOT NULL,
        email TEXT,
        fecha_registro INTEGER NOT NULL,
        tema TEXT NOT NULL DEFAULT 'sistema',
        tamano_fuente REAL NOT NULL DEFAULT 1.0,
        modo_alto_contraste INTEGER NOT NULL DEFAULT 0,
        idioma_interface TEXT NOT NULL DEFAULT 'es',
        idioma_voz TEXT NOT NULL DEFAULT 'es-ES',
        voz_seleccionada TEXT,
        velocidad_voz REAL NOT NULL DEFAULT 0.5,
        tono_voz REAL NOT NULL DEFAULT 1.0,
        volumen_voz REAL NOT NULL DEFAULT 0.8,
        pausas_automaticas INTEGER NOT NULL DEFAULT 1,
        duracion_pausas INTEGER NOT NULL DEFAULT 300,
        mejora_automatica_imagen INTEGER NOT NULL DEFAULT 1,
        deteccion_automatica_idioma INTEGER NOT NULL DEFAULT 1,
        calidad_compresion REAL NOT NULL DEFAULT 0.85,
        guardado_automatico_imagenes INTEGER NOT NULL DEFAULT 1,
        sincronizacion_nube INTEGER NOT NULL DEFAULT 0,
        respaldo_automatico INTEGER NOT NULL DEFAULT 0,
        analytics_anonimos INTEGER NOT NULL DEFAULT 1,
        notificaciones_activadas INTEGER NOT NULL DEFAULT 1,
        nivel_suscripcion TEXT NOT NULL DEFAULT 'gratuito',
        fecha_expiracion_premium INTEGER,
        caracteristicas_premium_usadas TEXT DEFAULT '',
        navegacion_por_voz INTEGER NOT NULL DEFAULT 0,
        lectura_automatica_menus INTEGER NOT NULL DEFAULT 0,
        vibracion_retroalimentacion INTEGER NOT NULL DEFAULT 1,
        sensibilidad_gestos REAL NOT NULL DEFAULT 0.5,
        documentos_escaneados INTEGER NOT NULL DEFAULT 0,
        minutos_escuchados INTEGER NOT NULL DEFAULT 0,
        dias_consecutivos INTEGER NOT NULL DEFAULT 1,
        fecha_ultimo_uso INTEGER NOT NULL,
        ultimo_acceso INTEGER NOT NULL
      )
    ''');

    // Crear configuración por defecto
    await _crearConfiguracionPorDefecto(db);
  }

  /// Maneja las actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración para versión 2: agregar columnas faltantes
      await db.execute('ALTER TABLE $_tableName ADD COLUMN dias_consecutivos INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN fecha_ultimo_uso INTEGER NOT NULL DEFAULT ${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  /// Crea configuración por defecto para nuevos usuarios
  Future<void> _crearConfiguracionPorDefecto(Database db) async {
    final configuracionDefecto = ConfiguracionUsuario.nuevoUsuario('Usuario');
    await db.insert(_tableName, configuracionDefecto.toMap());
  }

  /// Obtiene la configuración del usuario
  Future<ConfiguracionUsuario> obtenerConfiguracion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      limit: 1,
      orderBy: 'id DESC',
    );

    if (maps.isNotEmpty) {
      return ConfiguracionUsuario.fromMap(maps.first);
    } else {
      // Si no hay configuración, crear una por defecto
      final configDefecto = ConfiguracionUsuario.nuevoUsuario('Usuario');
      await guardarConfiguracion(configDefecto);
      return configDefecto;
    }
  }

  /// Guarda o actualiza la configuración del usuario
  Future<void> guardarConfiguracion(ConfiguracionUsuario configuracion) async {
    final db = await database;
    final map = configuracion.copyWith(ultimoAcceso: DateTime.now()).toMap();

    // Verificar si ya existe una configuración
    final existente = await db.query(_tableName, limit: 1);
    
    if (existente.isNotEmpty) {
      // Actualizar configuración existente
      await db.update(
        _tableName,
        map,
        where: 'id = ?',
        whereArgs: [existente.first['id']],
      );
    } else {
      // Insertar nueva configuración
      await db.insert(_tableName, map);
    }
  }

  /// Actualiza un campo específico de la configuración
  Future<void> actualizarCampo(String campo, dynamic valor) async {
    final db = await database;
    await db.update(
      _tableName,
      {campo: valor, 'ultimo_acceso': DateTime.now().millisecondsSinceEpoch},
      where: 'id = (SELECT MAX(id) FROM $_tableName)',
    );
  }

  /// Actualiza el tema de la aplicación
  Future<void> actualizarTema(TipoTema tema) async {
    await actualizarCampo('tema', tema.toString().split('.').last);
  }

  /// Actualiza configuraciones de TTS
  Future<void> actualizarConfiguracionTTS({
    String? idiomaVoz,
    String? vozSeleccionada,
    double? velocidad,
    double? tono,
    double? volumen,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {
      'ultimo_acceso': DateTime.now().millisecondsSinceEpoch,
    };

    if (idiomaVoz != null) updates['idioma_voz'] = idiomaVoz;
    if (vozSeleccionada != null) updates['voz_seleccionada'] = vozSeleccionada;
    if (velocidad != null) updates['velocidad_voz'] = velocidad;
    if (tono != null) updates['tono_voz'] = tono;
    if (volumen != null) updates['volumen_voz'] = volumen;

    await db.update(
      _tableName,
      updates,
      where: 'id = (SELECT MAX(id) FROM $_tableName)',
    );
  }

  /// Actualiza información del usuario
  Future<void> actualizarInfoUsuario({
    String? nombreUsuario,
    String? email,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {
      'ultimo_acceso': DateTime.now().millisecondsSinceEpoch,
    };

    if (nombreUsuario != null) updates['nombre_usuario'] = nombreUsuario;
    if (email != null) updates['email'] = email;

    await db.update(
      _tableName,
      updates,
      where: 'id = (SELECT MAX(id) FROM $_tableName)',
    );
  }

  /// Actualiza estadísticas de uso
  Future<void> actualizarEstadisticas({
    int? documentosEscaneados,
    int? minutosEscuchados,
  }) async {
    final configuracion = await obtenerConfiguracion();
    final nuevaConfig = configuracion.copyWith(
      documentosEscaneados: documentosEscaneados ?? configuracion.documentosEscaneados,
      minutosEscuchados: minutosEscuchados ?? configuracion.minutosEscuchados,
    );
    await guardarConfiguracion(nuevaConfig);
  }

  /// Incrementa contador de documentos escaneados
  Future<void> incrementarDocumentosEscaneados() async {
    final configuracion = await obtenerConfiguracion();
    await actualizarEstadisticas(
      documentosEscaneados: configuracion.documentosEscaneados + 1,
    );
  }

  /// Incrementa minutos escuchados
  Future<void> incrementarMinutosEscuchados(int minutos) async {
    final configuracion = await obtenerConfiguracion();
    await actualizarEstadisticas(
      minutosEscuchados: configuracion.minutosEscuchados + minutos,
    );
  }

  /// Actualiza suscripción premium
  Future<void> actualizarSuscripcionPremium({
    required NivelSuscripcion nivel,
    DateTime? fechaExpiracion,
  }) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'nivel_suscripcion': nivel.toString().split('.').last,
        'fecha_expiracion_premium': fechaExpiracion?.millisecondsSinceEpoch,
        'ultimo_acceso': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = (SELECT MAX(id) FROM $_tableName)',
    );
  }

  /// Marca una característica premium como usada
  Future<void> marcarCaracteristicaPremiumUsada(String caracteristica) async {
    final configuracion = await obtenerConfiguracion();
    if (!configuracion.caracteristicasPremiumUsadas.contains(caracteristica)) {
      final nuevasCaracteristicas = [
        ...configuracion.caracteristicasPremiumUsadas,
        caracteristica,
      ];
      await actualizarCampo(
        'caracteristicas_premium_usadas',
        nuevasCaracteristicas.join(','),
      );
    }
  }

  /// Resetea configuraciones a valores por defecto
  Future<void> resetearConfiguraciones() async {
    final configuracionActual = await obtenerConfiguracion();
    final configuracionDefecto = ConfiguracionUsuario.nuevoUsuario(
      configuracionActual.nombreUsuario,
    ).copyWith(
      email: configuracionActual.email,
      fechaRegistro: configuracionActual.fechaRegistro,
      documentosEscaneados: configuracionActual.documentosEscaneados,
      minutosEscuchados: configuracionActual.minutosEscuchados,
      nivelSuscripcion: configuracionActual.nivelSuscripcion,
      fechaExpiracionPremium: configuracionActual.fechaExpiracionPremium,
    );
    
    await guardarConfiguracion(configuracionDefecto);
  }

  /// Exporta configuraciones para respaldo
  Future<Map<String, dynamic>> exportarConfiguraciones() async {
    final configuracion = await obtenerConfiguracion();
    return configuracion.toMap();
  }

  /// Importa configuraciones desde respaldo
  Future<void> importarConfiguraciones(Map<String, dynamic> configuraciones) async {
    try {
      final configuracion = ConfiguracionUsuario.fromMap(configuraciones);
      await guardarConfiguracion(configuracion);
    } catch (e) {
      throw Exception('Error importando configuraciones: $e');
    }
  }

  /// Cierra la base de datos
  Future<void> cerrarBaseDatos() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
