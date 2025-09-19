import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'debug_console_service.dart';

/// Nivel de seguridad del dispositivo
enum SecurityLevel {
  secure,
  warning,
  compromised,
  unknown,
}

/// Resultado de verificación de seguridad
class SecurityCheckResult {
  final SecurityLevel level;
  final List<String> issues;
  final List<String> warnings;
  final Map<String, dynamic> details;
  final bool allowAccess;

  const SecurityCheckResult({
    required this.level,
    this.issues = const [],
    this.warnings = const [],
    this.details = const {},
    required this.allowAccess,
  });

  bool get isSecure => level == SecurityLevel.secure;
  bool get hasIssues => issues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Servicio de seguridad del dispositivo
class DeviceSecurityService extends GetxService {
  static DeviceSecurityService get to => Get.find();

  // Estado reactivo
  final Rx<SecurityLevel> _securityLevel = SecurityLevel.unknown.obs;
  final RxList<String> _detectedIssues = <String>[].obs;
  final RxBool _isRooted = false.obs;
  final RxBool _hasDebugger = false.obs;
  final RxBool _isEmulator = false.obs;

  // Getters
  SecurityLevel get securityLevel => _securityLevel.value;
  List<String> get detectedIssues => _detectedIssues;
  bool get isRooted => _isRooted.value;
  bool get hasDebugger => _hasDebugger.value;
  bool get isEmulator => _isEmulator.value;

  @override
  void onInit() {
    super.onInit();
    DebugLog.i('DeviceSecurityService initialized', category: LogCategory.security);
  }

  /// Realizar verificación completa de seguridad
  Future<SecurityCheckResult> performSecurityCheck() async {
    try {
      DebugLog.i('Starting comprehensive security check', category: LogCategory.security);
      
      final issues = <String>[];
      final warnings = <String>[];
      final details = <String, dynamic>{};

      // Solo verificar en modo release
      if (kDebugMode) {
        DebugLog.d('Debug mode detected, skipping security checks', category: LogCategory.security);
        return const SecurityCheckResult(
          level: SecurityLevel.secure,
          allowAccess: true,
        );
      }

      // 1. Verificar root/jailbreak
      final rootResult = await _checkRootStatus();
      _isRooted.value = rootResult;
      details['isRooted'] = rootResult;
      
      if (rootResult) {
        issues.add('Dispositivo rooteado/jailbreakeado detectado');
      }

      // 2. Verificar debugger
      final debuggerResult = _checkDebuggerAttached();
      _hasDebugger.value = debuggerResult;
      details['hasDebugger'] = debuggerResult;
      
      if (debuggerResult) {
        issues.add('Debugger externo detectado');
      }

      // 3. Verificar emulador
      final emulatorResult = await _checkEmulator();
      _isEmulator.value = emulatorResult;
      details['isEmulator'] = emulatorResult;
      
      if (emulatorResult) {
        warnings.add('Ejecutándose en emulador');
      }

      // 4. Verificar integridad de la app
      final integrityResult = await _checkAppIntegrity();
      details['appIntegrity'] = integrityResult;
      
      if (!integrityResult) {
        issues.add('Integridad de la aplicación comprometida');
      }

      // 5. Verificar permisos sospechosos
      final suspiciousPerms = await _checkSuspiciousPermissions();
      details['suspiciousPermissions'] = suspiciousPerms;
      
      if (suspiciousPerms.isNotEmpty) {
        warnings.add('Permisos sospechosos detectados');
      }

      // Actualizar estado
      _detectedIssues.value = [...issues, ...warnings];

      // Determinar nivel de seguridad
      SecurityLevel level;
      bool allowAccess;

      if (issues.isNotEmpty) {
        level = SecurityLevel.compromised;
        allowAccess = false;
      } else if (warnings.isNotEmpty) {
        level = SecurityLevel.warning;
        allowAccess = true; // Permitir pero con advertencias
      } else {
        level = SecurityLevel.secure;
        allowAccess = true;
      }

      _securityLevel.value = level;

      final result = SecurityCheckResult(
        level: level,
        issues: issues,
        warnings: warnings,
        details: details,
        allowAccess: allowAccess,
      );

      DebugLog.i('Security check completed: $level (${issues.length} issues, ${warnings.length} warnings)', 
                 category: LogCategory.security);

      return result;

    } catch (e) {
      DebugLog.e('Error during security check: $e', category: LogCategory.security);
      return const SecurityCheckResult(
        level: SecurityLevel.unknown,
        issues: ['Error en verificación de seguridad'],
        allowAccess: true, // Permitir en caso de error
      );
    }
  }

  /// Verificar si el dispositivo está rooteado/jailbreakeado
  Future<bool> _checkRootStatus() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkIOSJailbreak();
      }
      return false;
    } catch (e) {
      DebugLog.w('Error checking root status: $e', category: LogCategory.security);
      return false;
    }
  }

  /// Verificar root en Android
  Future<bool> _checkAndroidRoot() async {
    // Verificar archivos y directorios comunes de root
    final rootIndicators = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/system/app/SuperSU.apk',
      '/system/app/SuperSU',
      '/system/etc/init.d/99SuperSUDaemon',
    ];

    for (final path in rootIndicators) {
      if (await File(path).exists()) {
        DebugLog.w('Root indicator found: $path', category: LogCategory.security);
        return true;
      }
    }

    // Verificar propiedades del sistema
    try {
      final result = await Process.run('which', ['su']);
      if (result.exitCode == 0) {
        DebugLog.w('su binary found in PATH', category: LogCategory.security);
        return true;
      }
    } catch (e) {
      // Expected en dispositivos no rooteados
    }

    return false;
  }

  /// Verificar jailbreak en iOS
  Future<bool> _checkIOSJailbreak() async {
    // Verificar archivos y directorios comunes de jailbreak
    final jailbreakIndicators = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/private/var/lib/cydia',
      '/private/var/mobile/Library/SBSettings/Themes',
      '/Library/MobileSubstrate/DynamicLibraries/Veency.plist',
      '/private/var/stash',
      '/private/var/lib/dpkg/info/cydia.list',
      '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
      '/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist',
    ];

    for (final path in jailbreakIndicators) {
      if (await File(path).exists()) {
        DebugLog.w('Jailbreak indicator found: $path', category: LogCategory.security);
        return true;
      }
    }

    return false;
  }

  /// Verificar si hay debugger conectado
  bool _checkDebuggerAttached() {
    // En modo debug, siempre retornar false
    if (kDebugMode) return false;

    // Verificaciones básicas de debugger
    // En una implementación real, usarías técnicas más avanzadas
    return false;
  }

  /// Verificar si se ejecuta en emulador
  Future<bool> _checkEmulator() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidEmulator();
      } else if (Platform.isIOS) {
        return await _checkIOSSimulator();
      }
      return false;
    } catch (e) {
      DebugLog.w('Error checking emulator status: $e', category: LogCategory.security);
      return false;
    }
  }

  /// Verificar emulador Android
  Future<bool> _checkAndroidEmulator() async {
    // Verificar propiedades del sistema que indican emulador
    final emulatorIndicators = [
      'ro.kernel.qemu',
      'ro.hardware',
      'ro.product.model',
      'ro.product.manufacturer',
    ];

    // En una implementación real, leerías estas propiedades
    // Por ahora, retornar false
    return false;
  }

  /// Verificar simulador iOS
  Future<bool> _checkIOSSimulator() async {
    // En iOS, verificar si estamos en simulador
    // En una implementación real, usarías técnicas específicas de iOS
    return false;
  }

  /// Verificar integridad de la aplicación
  Future<bool> _checkAppIntegrity() async {
    try {
      // Verificar firma de la aplicación
      // En una implementación real, verificarías la firma digital
      return true;
    } catch (e) {
      DebugLog.w('Error checking app integrity: $e', category: LogCategory.security);
      return false;
    }
  }

  /// Verificar permisos sospechosos
  Future<List<String>> _checkSuspiciousPermissions() async {
    final suspiciousPerms = <String>[];
    
    // En una implementación real, verificarías permisos otorgados
    // que no deberían estar presentes
    
    return suspiciousPerms;
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'securityLevel': securityLevel.toString(),
      'isRooted': isRooted,
      'hasDebugger': hasDebugger,
      'isEmulator': isEmulator,
      'detectedIssues': detectedIssues,
      'platform': Platform.operatingSystem,
      'isDebugMode': kDebugMode,
    };
  }

  /// Limpiar estado de seguridad
  void clearSecurityState() {
    _securityLevel.value = SecurityLevel.unknown;
    _detectedIssues.clear();
    _isRooted.value = false;
    _hasDebugger.value = false;
    _isEmulator.value = false;
    
    DebugLog.d('Security state cleared', category: LogCategory.security);
  }
}
