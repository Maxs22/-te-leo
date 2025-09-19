import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'debug_console_service.dart';

/// Servicio para gestión de versiones de la aplicación
class VersionService extends GetxService {
  static VersionService get to => Get.find();

  // Información de la aplicación
  late PackageInfo _packageInfo;
  
  // Estado reactivo
  final RxString _version = ''.obs;
  final RxString _buildNumber = ''.obs;
  final RxString _appName = ''.obs;
  final RxString _packageName = ''.obs;

  // Getters reactivos
  String get version => _version.value;
  String get buildNumber => _buildNumber.value;
  String get appName => _appName.value;
  String get packageName => _packageName.value;
  String get fullVersion => '${_version.value}+${_buildNumber.value}';

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadPackageInfo();
  }

  /// Cargar información del paquete
  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      
      _version.value = _packageInfo.version;
      _buildNumber.value = _packageInfo.buildNumber;
      _appName.value = _packageInfo.appName;
      _packageName.value = _packageInfo.packageName;

      DebugLog.i('Version service initialized - ${_packageInfo.appName} v$fullVersion', 
                 category: LogCategory.app);

    } catch (e) {
      DebugLog.e('Error loading package info: $e', category: LogCategory.app);
      
      // Valores por defecto en caso de error
      _version.value = '1.0.0';
      _buildNumber.value = '1';
      _appName.value = 'Te Leo';
      _packageName.value = 'com.teleo.te_leo';
    }
  }

  /// Obtener información completa de la versión
  Map<String, dynamic> getVersionInfo() {
    return {
      'appName': _packageInfo.appName,
      'packageName': _packageInfo.packageName,
      'version': _packageInfo.version,
      'buildNumber': _packageInfo.buildNumber,
      'buildSignature': _packageInfo.buildSignature,
      'installerStore': _packageInfo.installerStore,
    };
  }

  /// Comparar versiones (útil para actualizaciones)
  int compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // Asegurar que ambas listas tengan la misma longitud
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    return 0;
  }

  /// Verificar si una versión es más nueva
  bool isNewerVersion(String currentVersion, String newVersion) {
    return compareVersions(currentVersion, newVersion) < 0;
  }

  /// Obtener información para debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'fullVersion': fullVersion,
      'appName': appName,
      'packageName': packageName,
      'packageInfo': getVersionInfo(),
    };
  }
}
