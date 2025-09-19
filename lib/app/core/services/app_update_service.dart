import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'debug_console_service.dart';

/// Tipos de actualización disponibles
enum UpdateType {
  none,
  optional,
  recommended,
  critical,
  forced
}

/// Estado de la actualización
enum UpdateState {
  checking,
  available,
  downloading,
  readyToInstall,
  installing,
  completed,
  failed,
  cancelled,
  notAvailable
}

/// Información de actualización
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final int currentBuildNumber;
  final int latestBuildNumber;
  final UpdateType updateType;
  final String? releaseNotes;
  final String? downloadUrl;
  final int? fileSizeBytes;
  final DateTime? releaseDate;
  final bool isCompatible;
  final String? minOsVersion;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.currentBuildNumber,
    required this.latestBuildNumber,
    required this.updateType,
    this.releaseNotes,
    this.downloadUrl,
    this.fileSizeBytes,
    this.releaseDate,
    this.isCompatible = true,
    this.minOsVersion,
  });

  bool get hasUpdate => latestBuildNumber > currentBuildNumber;
  bool get isCriticalUpdate => updateType == UpdateType.critical || updateType == UpdateType.forced;
  bool get isForced => updateType == UpdateType.forced;

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Desconocido';
    final mb = fileSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json, String currentVersion, int currentBuildNumber) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: json['version'] ?? currentVersion,
      currentBuildNumber: currentBuildNumber,
      latestBuildNumber: json['buildNumber'] ?? currentBuildNumber,
      updateType: _parseUpdateType(json['updateType']),
      releaseNotes: json['releaseNotes'],
      downloadUrl: json['downloadUrl'],
      fileSizeBytes: json['fileSizeBytes'],
      releaseDate: json['releaseDate'] != null ? DateTime.tryParse(json['releaseDate']) : null,
      isCompatible: json['isCompatible'] ?? true,
      minOsVersion: json['minOsVersion'],
    );
  }

  static UpdateType _parseUpdateType(String? type) {
    switch (type?.toLowerCase()) {
      case 'optional':
        return UpdateType.optional;
      case 'recommended':
        return UpdateType.recommended;
      case 'critical':
        return UpdateType.critical;
      case 'forced':
        return UpdateType.forced;
      default:
        return UpdateType.none;
    }
  }
}

/// Servicio de actualización de la aplicación
class AppUpdateService extends GetxService {
  static AppUpdateService get to => Get.find();

  // Estado reactivo
  final Rx<UpdateState> _state = UpdateState.notAvailable.obs;
  final Rx<UpdateInfo?> _updateInfo = Rx<UpdateInfo?>(null);
  final RxDouble _downloadProgress = 0.0.obs;
  final RxString _statusMessage = ''.obs;
  final RxBool _isCheckingForUpdates = false.obs;

  // Configuración
  String _updateCheckUrl = 'https://api.github.com/repos/Maxs22/-te-leo/releases/latest';
  Duration _checkInterval = const Duration(hours: 6);
  bool _autoCheckEnabled = true;
  bool _showUpdateDialogs = true;

  // Información de la app
  late PackageInfo _packageInfo;

  // Getters reactivos
  UpdateState get state => _state.value;
  UpdateInfo? get updateInfo => _updateInfo.value;
  double get downloadProgress => _downloadProgress.value;
  String get statusMessage => _statusMessage.value;
  bool get isCheckingForUpdates => _isCheckingForUpdates.value;
  bool get hasUpdate => updateInfo?.hasUpdate ?? false;

  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      DebugLog.i('AppUpdateService initialized - Version: ${_packageInfo.version}+${_packageInfo.buildNumber}', 
                 category: LogCategory.app);

      // Verificar actualizaciones al iniciar
      if (_autoCheckEnabled) {
        _schedulePeriodicCheck();
        checkForUpdates(showDialog: false);
      }

    } catch (e) {
      DebugLog.e('Error initializing AppUpdateService: $e', category: LogCategory.app);
    }
  }

  /// Configurar el servicio de actualización
  void configure({
    String? updateCheckUrl,
    Duration? checkInterval,
    bool? autoCheckEnabled,
    bool? showUpdateDialogs,
  }) {
    _updateCheckUrl = updateCheckUrl ?? _updateCheckUrl;
    _checkInterval = checkInterval ?? _checkInterval;
    _autoCheckEnabled = autoCheckEnabled ?? _autoCheckEnabled;
    _showUpdateDialogs = showUpdateDialogs ?? _showUpdateDialogs;

    DebugLog.d('AppUpdateService configured: autoCheck=$_autoCheckEnabled, interval=${_checkInterval.inHours}h', 
               category: LogCategory.app);

    if (_autoCheckEnabled) {
      _schedulePeriodicCheck();
    }
  }

  /// Verificar actualizaciones disponibles
  Future<UpdateInfo?> checkForUpdates({bool showDialog = true}) async {
    if (_isCheckingForUpdates.value) {
      DebugLog.d('Update check already in progress', category: LogCategory.app);
      return _updateInfo.value;
    }

    try {
      _isCheckingForUpdates.value = true;
      _updateState(UpdateState.checking, 'Verificando actualizaciones...');

      DebugLog.i('Checking for app updates', category: LogCategory.app);

      // Verificar actualizaciones según la plataforma
      UpdateInfo? updateInfo;
      
      if (Platform.isAndroid) {
        updateInfo = await _checkAndroidUpdate();
      } else if (Platform.isIOS) {
        updateInfo = await _checkIOSUpdate();
      } else {
        updateInfo = await _checkGenericUpdate();
      }

      _updateInfo.value = updateInfo;

      if (updateInfo?.hasUpdate == true) {
        _updateState(UpdateState.available, 'Actualización disponible');
        
        DebugLog.i('Update available: ${updateInfo!.currentVersion} → ${updateInfo.latestVersion}', 
                   category: LogCategory.app);

        if (showDialog && _showUpdateDialogs) {
          _showUpdateAvailableDialog(updateInfo);
        }
      } else {
        _updateState(UpdateState.notAvailable, 'App actualizada');
        DebugLog.d('No updates available', category: LogCategory.app);
      }

      return updateInfo;

    } catch (e) {
      DebugLog.e('Error checking for updates: $e', category: LogCategory.app);
      _updateState(UpdateState.failed, 'Error al verificar actualizaciones');
      return null;
    } finally {
      _isCheckingForUpdates.value = false;
    }
  }

  /// Verificar actualizaciones en Android usando In-App Updates
  Future<UpdateInfo?> _checkAndroidUpdate() async {
    try {
      final appUpdateInfo = await InAppUpdate.checkForUpdate();
      
      if (appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        final updateType = appUpdateInfo.immediateUpdateAllowed 
            ? UpdateType.critical 
            : appUpdateInfo.flexibleUpdateAllowed 
                ? UpdateType.recommended 
                : UpdateType.optional;

        return UpdateInfo(
          currentVersion: _packageInfo.version,
          latestVersion: 'Nueva versión', // Google Play no proporciona número específico
          currentBuildNumber: int.tryParse(_packageInfo.buildNumber) ?? 1,
          latestBuildNumber: (int.tryParse(_packageInfo.buildNumber) ?? 1) + 1,
          updateType: updateType,
          releaseNotes: 'Actualizaciones y mejoras disponibles',
        );
      }
    } catch (e) {
      DebugLog.w('Error checking Android in-app update: $e', category: LogCategory.app);
      // Fallback a verificación manual
      return await _checkGenericUpdate();
    }
    
    return null;
  }

  /// Verificar actualizaciones en iOS
  Future<UpdateInfo?> _checkIOSUpdate() async {
    // En iOS, verificamos contra nuestro servidor o App Store API
    return await _checkGenericUpdate();
  }

  /// Verificación genérica contra GitHub releases
  Future<UpdateInfo?> _checkGenericUpdate() async {
    try {
      DebugLog.d('Checking GitHub releases for updates...', category: LogCategory.app);
      
      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Te-Leo-App/${_packageInfo.version}'
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Obtener información del release más reciente
        final latestVersion = data['tag_name']?.toString().replaceFirst('v', '') ?? '';
        final releaseNotes = data['body']?.toString() ?? '';
        final releaseDate = DateTime.tryParse(data['published_at'] ?? '');
        final downloadUrl = _getDownloadUrlFromAssets(data['assets']);
        
        DebugLog.d('Latest version from GitHub: $latestVersion, Current: ${_packageInfo.version}', 
                  category: LogCategory.app);
        
        // Comparar versiones
        if (_isNewerVersion(latestVersion, _packageInfo.version)) {
          DebugLog.i('New version available: ${_packageInfo.version} → $latestVersion', 
                    category: LogCategory.app);
          
          return UpdateInfo(
            currentVersion: _packageInfo.version,
            latestVersion: latestVersion,
            currentBuildNumber: int.tryParse(_packageInfo.buildNumber) ?? 1,
            latestBuildNumber: _extractBuildNumber(data['tag_name'] ?? ''),
            updateType: _determineUpdateType(_packageInfo.version, latestVersion),
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
            releaseDate: releaseDate,
            isCompatible: true,
            minOsVersion: null,
          );
        } else {
          DebugLog.d('App is up to date', category: LogCategory.app);
        }
      } else {
        DebugLog.w('GitHub API returned status: ${response.statusCode}', category: LogCategory.app);
      }
    } catch (e) {
      DebugLog.w('Error checking GitHub update: $e', category: LogCategory.app);
      // En caso de error de red, retornar null (no hay actualizaciones)
    }

    return null;
  }

  /// Iniciar descarga e instalación de actualización
  Future<bool> startUpdate() async {
    final updateInfo = _updateInfo.value;
    if (updateInfo == null || !updateInfo.hasUpdate) {
      return false;
    }

    try {
      DebugLog.i('Starting app update', category: LogCategory.app);

      if (Platform.isAndroid) {
        return await _startAndroidUpdate(updateInfo);
      } else if (Platform.isIOS) {
        return await _startIOSUpdate(updateInfo);
      } else {
        return await _startGenericUpdate(updateInfo);
      }

    } catch (e) {
      DebugLog.e('Error starting update: $e', category: LogCategory.app);
      _updateState(UpdateState.failed, 'Error al iniciar actualización');
      return false;
    }
  }

  /// Iniciar actualización en Android
  Future<bool> _startAndroidUpdate(UpdateInfo updateInfo) async {
    try {
      if (updateInfo.isCriticalUpdate) {
        // Actualización inmediata
        _updateState(UpdateState.downloading, 'Descargando actualización...');
        final result = await InAppUpdate.performImmediateUpdate();
        
        if (result == AppUpdateResult.success) {
          _updateState(UpdateState.completed, 'Actualización completada');
          return true;
        }
      } else {
        // Actualización flexible
        _updateState(UpdateState.downloading, 'Descargando actualización...');
        final result = await InAppUpdate.startFlexibleUpdate();
        
        if (result == AppUpdateResult.success) {
          _updateState(UpdateState.readyToInstall, 'Listo para instalar');
          
          // Mostrar notificación para completar instalación
          _showInstallReadyDialog();
          return true;
        }
      }
    } catch (e) {
      DebugLog.e('Error in Android update: $e', category: LogCategory.app);
    }
    
    return false;
  }

  /// Iniciar actualización en iOS
  Future<bool> _startIOSUpdate(UpdateInfo updateInfo) async {
    // En iOS, redirigir a App Store
    final appStoreUrl = 'https://apps.apple.com/app/te-leo/id${_packageInfo.packageName}';
    
    if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
      await launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
      return true;
    }
    
    return false;
  }

  /// Iniciar actualización genérica
  Future<bool> _startGenericUpdate(UpdateInfo updateInfo) async {
    if (updateInfo.downloadUrl != null) {
      if (await canLaunchUrl(Uri.parse(updateInfo.downloadUrl!))) {
        await launchUrl(Uri.parse(updateInfo.downloadUrl!), mode: LaunchMode.externalApplication);
        return true;
      }
    }
    
    return false;
  }

  /// Completar instalación de actualización flexible
  Future<void> completeFlexibleUpdate() async {
    if (Platform.isAndroid && _state.value == UpdateState.readyToInstall) {
      try {
        _updateState(UpdateState.installing, 'Instalando actualización...');
        await InAppUpdate.completeFlexibleUpdate();
        _updateState(UpdateState.completed, 'Actualización completada');
        
        DebugLog.i('Flexible update completed', category: LogCategory.app);
      } catch (e) {
        DebugLog.e('Error completing flexible update: $e', category: LogCategory.app);
        _updateState(UpdateState.failed, 'Error al completar actualización');
      }
    }
  }

  /// Mostrar dialog de actualización disponible
  void _showUpdateAvailableDialog(UpdateInfo updateInfo) {
    // Simplemente notificar que hay una actualización disponible
    // La UI se manejará en los widgets correspondientes
    DebugLog.i('Update available notification triggered', category: LogCategory.app);
    
    // Se puede usar Get.snackbar para una notificación simple
    Get.snackbar(
      'Actualización Disponible',
      'Nueva versión ${updateInfo.latestVersion} disponible',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      onTap: (_) => startUpdate(),
    );
  }

  /// Mostrar dialog cuando la instalación está lista
  void _showInstallReadyDialog() {
    Get.snackbar(
      'Actualización Lista',
      'Toca para instalar la actualización',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 10),
      onTap: (_) => completeFlexibleUpdate(),
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Programar verificación periódica
  void _schedulePeriodicCheck() {
    // Implementar timer para verificación periódica
    // En producción, usar WorkManager o similar
    DebugLog.d('Periodic update checks scheduled every ${_checkInterval.inHours}h', 
               category: LogCategory.app);
  }

  /// Actualizar estado interno
  void _updateState(UpdateState state, String message) {
    _state.value = state;
    _statusMessage.value = message;
    
    DebugLog.d('Update state changed: $state - $message', category: LogCategory.app);
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentVersion': _packageInfo.version,
      'buildNumber': _packageInfo.buildNumber,
      'packageName': _packageInfo.packageName,
      'state': state.toString(),
      'hasUpdate': hasUpdate,
      'updateInfo': updateInfo != null ? {
        'latestVersion': updateInfo!.latestVersion,
        'updateType': updateInfo!.updateType.toString(),
        'fileSize': updateInfo!.fileSizeFormatted,
      } : null,
      'config': {
        'autoCheckEnabled': _autoCheckEnabled,
        'checkInterval': _checkInterval.inHours,
        'showDialogs': _showUpdateDialogs,
      },
    };
  }

  /// 🧪 MODO DESARROLLO: Simular actualización disponible
  Future<UpdateInfo?> simulateUpdateAvailable({
    String? latestVersion,
    UpdateType updateType = UpdateType.recommended,
    String? releaseNotes,
  }) async {
    // Solo funciona en modo debug
    if (!kDebugMode) {
      DebugLog.w('simulateUpdateAvailable only works in debug mode', category: LogCategory.app);
      return null;
    }

    DebugLog.i('🧪 SIMULATING UPDATE AVAILABLE', category: LogCategory.app);

    // Generar versión simulada
    final currentParts = _packageInfo.version.split('.');
    final simulatedVersion = latestVersion ?? 
        '${currentParts[0]}.${int.parse(currentParts.length > 1 ? currentParts[1] : '0') + 1}.0';

    final simulatedUpdate = UpdateInfo(
      currentVersion: _packageInfo.version,
      latestVersion: simulatedVersion,
      currentBuildNumber: int.tryParse(_packageInfo.buildNumber) ?? 1,
      latestBuildNumber: (int.tryParse(_packageInfo.buildNumber) ?? 1) + 10,
      updateType: updateType,
      releaseNotes: releaseNotes ?? '''
🎉 Nueva versión de Te Leo disponible!

✨ Nuevas características:
• Mejoras en la síntesis de voz
• Interfaz más accesible
• Corrección de errores
• Optimizaciones de rendimiento

🔧 Mejoras técnicas:
• Mejor sincronización de resaltado
• Sistema de pausa/reanudación mejorado
• Actualizaciones automáticas

Esta es una actualización simulada para pruebas de desarrollo.
      ''',
      downloadUrl: 'https://github.com/MaximoDev/te-leo/releases/download/v$simulatedVersion/te-leo-$simulatedVersion.apk',
      releaseDate: DateTime.now().subtract(const Duration(days: 1)),
      isCompatible: true,
      minOsVersion: null,
    );

    _updateInfo.value = simulatedUpdate;
    _updateState(UpdateState.available, 'Actualización simulada disponible');

    DebugLog.i('Simulated update: ${_packageInfo.version} → $simulatedVersion', category: LogCategory.app);
    
    // Mostrar notificación si está habilitada
    if (_showUpdateDialogs) {
      _showUpdateAvailableDialog(simulatedUpdate);
    }

    return simulatedUpdate;
  }

  /// 🧪 MODO DESARROLLO: Simular diferentes tipos de actualización
  Future<void> testUpdateScenarios() async {
    if (!kDebugMode) return;

    DebugLog.i('🧪 TESTING UPDATE SCENARIOS', category: LogCategory.app);

    // Scenario 1: Actualización opcional (patch)
    await Future.delayed(const Duration(seconds: 1));
    await simulateUpdateAvailable(
      updateType: UpdateType.optional,
      releaseNotes: '🔧 Actualización opcional: Correcciones menores y mejoras de estabilidad.',
    );

    // Scenario 2: Actualización recomendada (minor)
    await Future.delayed(const Duration(seconds: 3));
    await simulateUpdateAvailable(
      updateType: UpdateType.recommended,
      releaseNotes: '⭐ Actualización recomendada: Nuevas características y mejoras importantes.',
    );

    // Scenario 3: Actualización crítica (major)
    await Future.delayed(const Duration(seconds: 5));
    await simulateUpdateAvailable(
      updateType: UpdateType.critical,
      releaseNotes: '🚨 Actualización crítica: Correcciones de seguridad importantes. Se recomienda actualizar inmediatamente.',
    );
  }

  /// 🧪 MODO DESARROLLO: Simular descarga
  Future<void> simulateDownload() async {
    if (!kDebugMode) return;

    DebugLog.i('🧪 SIMULATING DOWNLOAD', category: LogCategory.app);
    
    _updateState(UpdateState.downloading, 'Descargando actualización...');
    
    // Simular progreso de descarga
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      _downloadProgress.value = i / 100.0;
      _statusMessage.value = 'Descargando... ${i}%';
    }
    
    _updateState(UpdateState.readyToInstall, 'Descarga completa - Lista para instalar');
    
    // Auto-instalar después de 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    await simulateInstallation();
  }

  /// 🧪 MODO DESARROLLO: Simular instalación
  Future<void> simulateInstallation() async {
    if (!kDebugMode) return;

    DebugLog.i('🧪 SIMULATING INSTALLATION', category: LogCategory.app);
    
    _updateState(UpdateState.installing, 'Instalando actualización...');
    
    // Simular tiempo de instalación
    await Future.delayed(const Duration(seconds: 3));
    
    _updateState(UpdateState.completed, 'Actualización completada exitosamente');
    
    // Mostrar notificación de éxito
    Get.snackbar(
      '✅ Actualización Completada',
      'Te Leo se ha actualizado exitosamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// 🧪 MODO DESARROLLO: Resetear estado para nuevas pruebas
  void resetUpdateState() {
    if (!kDebugMode) return;
    
    DebugLog.i('🧪 RESETTING UPDATE STATE', category: LogCategory.app);
    
    _updateInfo.value = null;
    _downloadProgress.value = 0.0;
    _updateState(UpdateState.notAvailable, 'Sin actualizaciones');
  }

  /// Obtener URL de descarga desde los assets del release
  String? _getDownloadUrlFromAssets(List<dynamic>? assets) {
    if (assets == null || assets.isEmpty) return null;
    
    // Buscar el archivo APK para Android
    if (Platform.isAndroid) {
      for (var asset in assets) {
        final name = asset['name']?.toString().toLowerCase() ?? '';
        if (name.endsWith('.apk')) {
          return asset['browser_download_url']?.toString();
        }
      }
    }
    
    // Para iOS buscar archivo .ipa
    if (Platform.isIOS) {
      for (var asset in assets) {
        final name = asset['name']?.toString().toLowerCase() ?? '';
        if (name.endsWith('.ipa')) {
          return asset['browser_download_url']?.toString();
        }
      }
    }
    
    return null;
  }

  /// Comparar si una versión es más nueva que otra
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = _parseVersion(latestVersion);
      final current = _parseVersion(currentVersion);
      
      // Comparar major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      
      return false; // Son iguales
    } catch (e) {
      DebugLog.w('Error comparing versions: $e', category: LogCategory.app);
      return false;
    }
  }

  /// Parsear versión en formato x.y.z
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }

  /// Extraer build number del tag
  int _extractBuildNumber(String tag) {
    // Intentar extraer número de build del tag (ej: v1.2.3+45)
    final buildMatch = RegExp(r'\+(\d+)').firstMatch(tag);
    return int.tryParse(buildMatch?.group(1) ?? '') ?? 1;
  }

  /// Determinar tipo de actualización basado en versiones
  UpdateType _determineUpdateType(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);
      
      // Major version change = crítica
      if (latest[0] > current[0]) return UpdateType.critical;
      
      // Minor version change = recomendada
      if (latest[1] > current[1]) return UpdateType.recommended;
      
      // Patch version change = opcional
      if (latest[2] > current[2]) return UpdateType.optional;
      
      return UpdateType.none;
    } catch (e) {
      return UpdateType.optional;
    }
  }
}
