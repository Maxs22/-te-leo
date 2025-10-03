import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Niveles de log para la consola de debug
enum LogLevel {
  debug, // Información de desarrollo
  info, // Información general
  warning, // Advertencias
  error, // Errores
  critical, // Errores críticos
}

/// Categorías de logs para organización
enum LogCategory {
  app, // Aplicación general
  database, // Base de datos
  tts, // Text-to-Speech
  ocr, // Reconocimiento de texto
  camera, // Cámara e imágenes
  navigation, // Navegación
  ui, // Interfaz de usuario
  service, // Servicios generales
  network, // Red (futuro)
  storage, // Almacenamiento
  security, // Seguridad y validaciones
  notification, // Notificaciones
}

/// Entrada individual de log
class LogEntry {
  final String message;
  final LogLevel level;
  final LogCategory category;
  final DateTime timestamp;
  final String? tag;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;

  const LogEntry({
    required this.message,
    required this.level,
    required this.category,
    required this.timestamp,
    this.tag,
    this.metadata,
    this.stackTrace,
  });

  /// Convierte a Map para exportación
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'level': level.toString().split('.').last,
      'category': category.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'tag': tag,
      'metadata': metadata,
      'stack_trace': stackTrace,
    };
  }

  /// Obtiene el color para el nivel de log
  Color get color {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.red.shade900;
    }
  }

  /// Obtiene el icono para el nivel de log
  IconData get icon {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.critical:
        return Icons.dangerous;
    }
  }

  /// Obtiene el prefijo para la consola
  String get prefix {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

/// Servicio de consola de debug integrada para Te Leo
/// Reemplaza todos los print statements con un sistema de logging profesional
class DebugConsoleService extends GetxService {
  /// Lista de entradas de log
  final RxList<LogEntry> _logs = <LogEntry>[].obs;
  List<LogEntry> get logs => _logs;

  /// Límite máximo de logs en memoria
  final int _maxLogs = 1000;

  /// Filtros activos
  final RxSet<LogLevel> _levelFilters = <LogLevel>{}.obs;
  final RxSet<LogCategory> _categoryFilters = <LogCategory>{}.obs;
  final RxString _searchFilter = ''.obs;

  /// Configuraciones
  final RxBool _isEnabled = kDebugMode.obs;
  final RxBool _logToConsole = kDebugMode.obs;
  final RxBool _autoScroll = true.obs;

  /// Getters para configuraciones
  bool get isEnabled => _isEnabled.value;
  bool get logToConsole => _logToConsole.value;
  bool get autoScroll => _autoScroll.value;
  String get searchFilter => _searchFilter.value;
  Set<LogLevel> get levelFilters => _levelFilters;
  Set<LogCategory> get categoryFilters => _categoryFilters;

  /// Estadísticas de logs
  final RxMap<LogLevel, int> _levelCounts = <LogLevel, int>{}.obs;
  final RxMap<LogCategory, int> _categoryCounts = <LogCategory, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  /// Inicializa el servicio
  void _initializeService() {
    // Inicializar contadores
    for (final level in LogLevel.values) {
      _levelCounts[level] = 0;
    }
    for (final category in LogCategory.values) {
      _categoryCounts[category] = 0;
    }

    // Habilitar todos los filtros por defecto
    _levelFilters.addAll(LogLevel.values);
    _categoryFilters.addAll(LogCategory.values);

    // Log después de que el servicio esté completamente inicializado
    if (kDebugMode) {
      print('🐛 Debug Console Service initialized');
    }
  }

  /// Método principal de logging
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    if (!_isEnabled.value) return;

    final entry = LogEntry(
      message: message,
      level: level,
      category: category,
      timestamp: DateTime.now(),
      tag: tag,
      metadata: metadata,
      stackTrace: stackTrace,
    );

    // Agregar a la lista de forma asíncrona para evitar ciclos de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logs.insert(0, entry);

      // Mantener límite de logs
      if (_logs.length > _maxLogs) {
        _logs.removeRange(_maxLogs, _logs.length);
      }

      // Actualizar contadores
      _levelCounts[level] = (_levelCounts[level] ?? 0) + 1;
      _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    });

    // Log a consola del sistema si está habilitado
    if (_logToConsole.value) {
      _logToSystemConsole(entry);
    }
  }

  /// Métodos de conveniencia para diferentes niveles
  void debug(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.debug, category: category, tag: tag, metadata: metadata);
  }

  void info(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.info, category: category, tag: tag, metadata: metadata);
  }

  void warning(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.warning, category: category, tag: tag, metadata: metadata);
  }

  void error(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    log(message, level: LogLevel.error, category: category, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  void critical(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    log(message, level: LogLevel.critical, category: category, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  /// Métodos específicos por categoría
  void logTTS(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    log(message, level: level, category: LogCategory.tts, tag: 'TTS', metadata: metadata);
  }

  void logOCR(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    log(message, level: level, category: LogCategory.ocr, tag: 'OCR', metadata: metadata);
  }

  void logDatabase(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    log(message, level: level, category: LogCategory.database, tag: 'DB', metadata: metadata);
  }

  void logCamera(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    log(message, level: level, category: LogCategory.camera, tag: 'CAM', metadata: metadata);
  }

  void logNavigation(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    log(message, level: level, category: LogCategory.navigation, tag: 'NAV', metadata: metadata);
  }

  void logService(
    String message, {
    LogLevel level = LogLevel.info,
    String? serviceName,
    Map<String, dynamic>? metadata,
  }) {
    log(message, level: level, category: LogCategory.service, tag: serviceName, metadata: metadata);
  }

  /// Log a la consola del sistema
  void _logToSystemConsole(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String().substring(11, 19);
    final category = entry.category.toString().split('.').last.toUpperCase();
    final levelStr = entry.level.toString().split('.').last.toUpperCase();
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';

    final logLine = '${entry.prefix} $timestamp [$levelStr] [$category] $tag${entry.message}';

    if (kDebugMode) {
      print(logLine);

      if (entry.metadata != null) {
        print('  └─ Metadata: ${entry.metadata}');
      }

      if (entry.stackTrace != null) {
        print('  └─ Stack: ${entry.stackTrace}');
      }
    }
  }

  /// Obtiene logs filtrados
  List<LogEntry> getFilteredLogs() {
    return _logs.where((entry) {
      // Filtro por nivel
      if (_levelFilters.isNotEmpty && !_levelFilters.contains(entry.level)) {
        return false;
      }

      // Filtro por categoría
      if (_categoryFilters.isNotEmpty && !_categoryFilters.contains(entry.category)) {
        return false;
      }

      // Filtro por búsqueda
      if (_searchFilter.value.isNotEmpty) {
        final searchLower = _searchFilter.value.toLowerCase();
        return entry.message.toLowerCase().contains(searchLower) ||
            (entry.tag?.toLowerCase().contains(searchLower) ?? false);
      }

      return true;
    }).toList();
  }

  /// Actualiza filtros
  void updateLevelFilter(LogLevel level, bool enabled) {
    if (enabled) {
      _levelFilters.add(level);
    } else {
      _levelFilters.remove(level);
    }
  }

  void updateCategoryFilter(LogCategory category, bool enabled) {
    if (enabled) {
      _categoryFilters.add(category);
    } else {
      _categoryFilters.remove(category);
    }
  }

  void updateSearchFilter(String search) {
    _searchFilter.value = search;
  }

  /// Limpia todos los logs
  void clearLogs() {
    _logs.clear();
    for (final level in LogLevel.values) {
      _levelCounts[level] = 0;
    }
    for (final category in LogCategory.values) {
      _categoryCounts[category] = 0;
    }
    // Log a consola del sistema para evitar recursión
    if (kDebugMode) {
      print('🐛 Debug Console: Logs cleared');
    }
  }

  /// Exporta logs como texto
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== Te Leo - Debug Console Export ===');
    buffer.writeln('Fecha de exportación: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total de logs: ${_logs.length}');
    buffer.writeln('');

    // Estadísticas
    buffer.writeln('--- Estadísticas ---');
    for (final level in LogLevel.values) {
      final count = _levelCounts[level] ?? 0;
      if (count > 0) {
        buffer.writeln('${level.toString().split('.').last}: $count');
      }
    }
    buffer.writeln('');

    // Logs
    buffer.writeln('--- Logs ---');
    for (final entry in _logs.reversed) {
      final timestamp = entry.timestamp.toIso8601String();
      final category = entry.category.toString().split('.').last;
      final level = entry.level.toString().split('.').last;
      final tag = entry.tag != null ? '[${entry.tag}] ' : '';

      buffer.writeln('$timestamp [$level] [$category] $tag${entry.message}');

      if (entry.metadata != null) {
        buffer.writeln('  Metadata: ${entry.metadata}');
      }
    }

    return buffer.toString();
  }

  /// Obtiene estadísticas de logs
  Map<String, dynamic> getStats() {
    return {
      'total_logs': _logs.length,
      'by_level': Map.fromEntries(_levelCounts.entries.where((e) => e.value > 0)),
      'by_category': Map.fromEntries(_categoryCounts.entries.where((e) => e.value > 0)),
      'oldest_log': _logs.isNotEmpty ? _logs.last.timestamp.toIso8601String() : null,
      'newest_log': _logs.isNotEmpty ? _logs.first.timestamp.toIso8601String() : null,
    };
  }

  /// Configuraciones del servicio
  void setEnabled(bool enabled) => _isEnabled.value = enabled;
  void setLogToConsole(bool enabled) => _logToConsole.value = enabled;
  void setAutoScroll(bool enabled) => _autoScroll.value = enabled;
}

/// Extension global para logging fácil
extension DebugLogging on Object {
  /// Log de debug
  void logDebug(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    if (Get.isRegistered<DebugConsoleService>()) {
      Get.find<DebugConsoleService>().debug(message, category: category, tag: tag, metadata: metadata);
    }
  }

  /// Log de información
  void logInfo(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    if (Get.isRegistered<DebugConsoleService>()) {
      Get.find<DebugConsoleService>().info(message, category: category, tag: tag, metadata: metadata);
    }
  }

  /// Log de advertencia
  void logWarning(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    if (Get.isRegistered<DebugConsoleService>()) {
      Get.find<DebugConsoleService>().warning(message, category: category, tag: tag, metadata: metadata);
    }
  }

  /// Log de error
  void logError(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    if (Get.isRegistered<DebugConsoleService>()) {
      Get.find<DebugConsoleService>().error(
        message,
        category: category,
        tag: tag,
        metadata: metadata,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log crítico
  void logCritical(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    if (Get.isRegistered<DebugConsoleService>()) {
      Get.find<DebugConsoleService>().critical(
        message,
        category: category,
        tag: tag,
        metadata: metadata,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Funciones globales de logging para uso directo
class DebugLog {
  static DebugConsoleService? _service;

  static DebugConsoleService? get _console {
    try {
      _service ??= Get.find<DebugConsoleService>();
      return _service;
    } catch (e) {
      // Si el servicio no está disponible, simplemente retornamos null
      // Los logs se perderán pero la app no crasheará
      return null;
    }
  }

  /// Logs por nivel
  static void d(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    _console?.debug(message, category: category, tag: tag, metadata: metadata);
  }

  static void i(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    _console?.info(message, category: category, tag: tag, metadata: metadata);
  }

  static void w(String message, {LogCategory category = LogCategory.app, String? tag, Map<String, dynamic>? metadata}) {
    _console?.warning(message, category: category, tag: tag, metadata: metadata);
  }

  static void e(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    _console?.error(message, category: category, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  static void c(
    String message, {
    LogCategory category = LogCategory.app,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    _console?.critical(message, category: category, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  /// Logs por categoría
  static void tts(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    _console?.logTTS(message, level: level, metadata: metadata);
  }

  static void ocr(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    _console?.logOCR(message, level: level, metadata: metadata);
  }

  static void db(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    _console?.logDatabase(message, level: level, metadata: metadata);
  }

  static void camera(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    _console?.logCamera(message, level: level, metadata: metadata);
  }

  static void nav(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? metadata}) {
    _console?.logNavigation(message, level: level, metadata: metadata);
  }

  static void service(
    String message, {
    LogLevel level = LogLevel.info,
    String? serviceName,
    Map<String, dynamic>? metadata,
  }) {
    _console?.logService(message, level: level, serviceName: serviceName, metadata: metadata);
  }
}
