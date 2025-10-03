import 'package:get/get.dart';

/// Estados de inicialización de la aplicación
enum InitializationState { notStarted, initializing, completed, failed }

/// Servicio de inicialización optimizada de la aplicación (DEPRECATED)
///
/// NOTA: Este servicio ya no se usa. Toda la inicialización se maneja en AppBootstrapService
/// para evitar duplicaciones. Se mantiene solo por compatibilidad con código existente.
///
/// @deprecated Use AppBootstrapService instead
class AppInitializationService extends GetxService {
  /// Estado actual de la inicialización
  final Rx<InitializationState> _state = InitializationState.completed.obs;
  InitializationState get state => _state.value;

  /// Progreso de inicialización (0.0 - 1.0)
  final RxDouble _progress = 1.0.obs;
  double get progress => _progress.value;

  /// Mensaje de estado actual
  final RxString _statusMessage = 'Inicialización manejada por AppBootstrapService'.obs;
  String get statusMessage => _statusMessage.value;

  /// Lista de servicios inicializados
  final RxList<String> _initializedServices = <String>[].obs;
  List<String> get initializedServices => _initializedServices;

  /// Indica si la inicialización está completa
  bool get isCompleted => true;

  @override
  void onInit() {
    super.onInit();
    // No hacer nada - AppBootstrapService maneja todo
    _state.value = InitializationState.completed;
    _progress.value = 1.0;
    print('ℹ️  AppInitializationService initialized (deprecated - using AppBootstrapService)');
  }

  /// Obtiene estadísticas de inicialización
  Map<String, dynamic> getInitializationStats() {
    return {
      'state': 'completed',
      'progress': 1.0,
      'status_message': 'Managed by AppBootstrapService',
      'initialized_services': 0,
      'services_list': [],
      'note': 'This service is deprecated. All initialization is handled by AppBootstrapService.',
    };
  }
}
