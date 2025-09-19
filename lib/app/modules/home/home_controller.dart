import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../../app/core/services/user_preferences_service.dart';
import '../../../app/core/services/version_service.dart';
import '../../../app/core/services/app_update_service.dart';
import '../../../app/data/providers/database_provider.dart';

/// Controlador para la página principal (Home) de Te Leo
/// Gestiona la lógica de navegación y estado de la pantalla principal
class HomeController extends GetxController {
  // Servicios
  UserPreferencesService? _prefsService;
  VersionService? _versionService;
  AppUpdateService? _updateService;
  final DatabaseProvider _databaseProvider = DatabaseProvider();
  
  // Estados reactivos
  final RxString _appVersion = '1.0.0'.obs;
  final RxBool _hasUpdateAvailable = false.obs;
  final RxInt _documentsScanned = 0.obs;
  final RxInt _minutesListened = 0.obs;
  final RxInt _consecutiveDays = 0.obs;
  final RxBool _hasStatistics = false.obs;
  
  // Getters
  String get appVersion => _appVersion.value;
  bool get hasUpdateAvailable => _hasUpdateAvailable.value;
  int get documentsScanned => _documentsScanned.value;
  int get minutesListened => _minutesListened.value;
  int get consecutiveDays => _consecutiveDays.value;
  bool get hasStatistics => _hasStatistics.value;
  /// Navega a la página de biblioteca de documentos
  void irABiblioteca() {
    Get.toNamed(AppRoutes.library);
  }

  /// Navega a la funcionalidad de escanear texto
  void escanearTexto() {
    Get.toNamed(AppRoutes.scanText);
  }
  
  /// Navega a configuraciones
  void irAConfiguraciones() {
    Get.toNamed(AppRoutes.settings);
  }

  /// Método llamado cuando el controlador es inicializado
  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadAppInfo();
    _loadStatistics();
  }

  /// Método llamado cuando el controlador está listo
  @override
  void onReady() {
    super.onReady();
    _checkForUpdates();
    // Refrescar estadísticas cuando el controlador esté listo
    _loadStatistics();
  }
  
  /// Inicializa los servicios
  void _initializeServices() {
    try {
      _prefsService = Get.find<UserPreferencesService>();
      _versionService = Get.find<VersionService>();
      _updateService = Get.find<AppUpdateService>();
    } catch (e) {
      // Servicios no disponibles aún
    }
  }
  
  /// Carga información de la aplicación
  void _loadAppInfo() {
    try {
      if (_versionService != null) {
        _appVersion.value = _versionService!.version;
      }
    } catch (e) {
      // Mantener versión por defecto
    }
  }
  
  /// Refresca las estadísticas (método público)
  Future<void> refreshStatistics() async {
    await _loadStatistics();
  }

  /// Carga estadísticas del usuario
  Future<void> _loadStatistics() async {
    try {
      // Cargar documentos escaneados
      final documentos = await _databaseProvider.obtenerTodosLosDocumentos();
      _documentsScanned.value = documentos.length;
      
      // Cargar estadísticas de usuario desde preferencias
      if (_prefsService != null) {
        final summary = _prefsService!.getWelcomeSummary();
        _minutesListened.value = summary['minutesListened'] ?? 0;
        _consecutiveDays.value = summary['consecutiveDays'] ?? 0;
      }
      
      // Mostrar estadísticas si hay datos
      _hasStatistics.value = _documentsScanned.value > 0 || 
                            _minutesListened.value > 0 || 
                            _consecutiveDays.value > 0;
      
    } catch (e) {
      _hasStatistics.value = false;
    }
  }
  
  /// Verifica si hay actualizaciones disponibles
  void _checkForUpdates() {
    try {
      if (_updateService != null) {
        // Escuchar cambios en el estado de actualización
        ever(_updateService!.state.obs, (state) {
          _hasUpdateAvailable.value = state == UpdateState.available;
        });
        
        // Verificar actualizaciones inmediatamente
        _updateService!.checkForUpdates();
      }
    } catch (e) {
      // Servicio no disponible
    }
  }

  /// Método llamado cuando el controlador es cerrado
  @override
  void onClose() {
    super.onClose();
    // Limpieza de recursos si es necesaria
  }
}
