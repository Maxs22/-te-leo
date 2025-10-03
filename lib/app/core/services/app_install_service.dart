import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'debug_console_service.dart';

/// Servicio para detectar nuevas instalaciones y resetear datos
class AppInstallService extends GetxService {
  static const String _installIdKey = 'app_install_id';
  static const String _firstInstallKey = 'first_install_date';
  static const String _lastVersionKey = 'last_app_version';

  final _storage = GetStorage();

  String? _installId;
  bool _isNewInstall = false;

  String? get installId => _installId;
  bool get isNewInstall => _isNewInstall;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _checkInstallationStatus();
    DebugLog.i('AppInstallService initialized', category: LogCategory.service);
  }

  /// Verifica el estado de instalación de la app
  Future<void> _checkInstallationStatus() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Obtener o generar ID de instalación
      _installId = _storage.read<String>(_installIdKey);

      if (_installId == null) {
        // Es una nueva instalación
        _isNewInstall = true;
        _installId = _generateInstallId();
        await _storage.write(_installIdKey, _installId!);
        await _storage.write(_firstInstallKey, DateTime.now().toIso8601String());

        DebugLog.i('New app installation detected - Install ID: $_installId', category: LogCategory.service);
      } else {
        // Verificar si es una actualización importante (versión diferente)
        final lastVersion = _storage.read<String>(_lastVersionKey);

        if (lastVersion != currentVersion) {
          await _handleVersionUpdate(lastVersion, currentVersion);
        }
      }

      // Actualizar versión actual
      await _storage.write(_lastVersionKey, currentVersion);

      DebugLog.d(
        'Installation check completed - New install: $_isNewInstall, Install ID: $_installId',
        category: LogCategory.service,
      );
    } catch (e) {
      DebugLog.e('Error checking installation status: $e', category: LogCategory.service);
    }
  }

  /// Genera un ID único para esta instalación
  String _generateInstallId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'install_${random.substring(random.length - 8)}';
  }

  /// Maneja actualizaciones de versión
  Future<void> _handleVersionUpdate(String? lastVersion, String currentVersion) async {
    try {
      DebugLog.i('App version updated from $lastVersion to $currentVersion', category: LogCategory.service);

      // Aquí puedes agregar lógica específica para manejar actualizaciones
      // Por ejemplo, migrar datos, mostrar changelog, etc.

      if (lastVersion == null) {
        // Primera vez que se ejecuta después de una nueva instalación
        DebugLog.i('First run after new installation', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error handling version update: $e', category: LogCategory.service);
    }
  }

  /// Verifica si debe resetear datos (nueva instalación)
  bool shouldResetData() {
    return _isNewInstall;
  }

  /// Resetea todos los datos de la app para nueva instalación
  Future<void> resetAppData() async {
    try {
      // Lista de claves que deben mantenerse
      final keysToKeep = [
        _installIdKey,
        _firstInstallKey,
        _lastVersionKey,
        'has_seen_onboarding', // Mantener onboarding visto
      ];

      // Obtener todas las claves
      final allKeys = _storage.getKeys();

      // Eliminar todas las claves excepto las que se deben mantener
      for (final key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await _storage.remove(key);
        }
      }

      DebugLog.i('App data reset for new installation', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error resetting app data: $e', category: LogCategory.service);
    }
  }

  /// Obtiene información de debug sobre la instalación
  Map<String, dynamic> getInstallationInfo() {
    return {'installId': _installId, 'isNewInstall': _isNewInstall, 'timestamp': DateTime.now().toIso8601String()};
  }

  /// Fuerza una nueva instalación (útil para testing)
  Future<void> forceNewInstallation() async {
    try {
      await _storage.remove(_installIdKey);
      await _storage.remove(_firstInstallKey);
      await _storage.remove(_lastVersionKey);

      _installId = null;
      _isNewInstall = true;

      DebugLog.i('Forced new installation', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error forcing new installation: $e', category: LogCategory.service);
    }
  }
}
