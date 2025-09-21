import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'debug_console_service.dart';
import 'subscription_service.dart';
import '../../data/providers/configuracion_provider.dart';

/// Servicio para gestionar límites de uso en la versión gratuita
class UsageLimitsService extends GetxController {
  static UsageLimitsService get to => Get.find();

  final ConfiguracionProvider _configProvider = ConfiguracionProvider();

  // Límites para versión gratuita
  static const int LIMITE_DOCUMENTOS_GRATIS = 5;
  static const Duration PERIODO_RESETEO = Duration(days: 30);

  // Estado reactivo
  final RxInt _documentosUsadosEstesMes = 0.obs;
  final Rx<DateTime> _fechaProximoReseteo = DateTime.now().obs;
  final RxBool _limiteAlcanzado = false.obs;

  // Getters
  int get documentosUsadosEstesMes => _documentosUsadosEstesMes.value;
  DateTime get fechaProximoReseteo => _fechaProximoReseteo.value;
  bool get limiteAlcanzado => _limiteAlcanzado.value;
  int get documentosRestantes => (LIMITE_DOCUMENTOS_GRATIS - _documentosUsadosEstesMes.value).clamp(0, LIMITE_DOCUMENTOS_GRATIS);
  bool get puedeEscanearMas => !_limiteAlcanzado.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
  }

  /// Inicializar el servicio
  Future<void> _initializeService() async {
    try {
      await _loadUsageData();
      _checkAndResetIfNeeded();
      
      DebugLog.i('UsageLimitsService initialized - Documents used: ${_documentosUsadosEstesMes.value}/$LIMITE_DOCUMENTOS_GRATIS', 
                 category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing UsageLimitsService: $e', category: LogCategory.service);
    }
  }

  /// Cargar datos de uso desde la configuración
  Future<void> _loadUsageData() async {
    try {
      final config = await _configProvider.obtenerConfiguracion();
      _documentosUsadosEstesMes.value = config.documentosEstesMes;
      _fechaProximoReseteo.value = (config.fechaReseteoMensual ?? DateTime.now()).add(PERIODO_RESETEO);
      _updateLimitStatus();
    } catch (e) {
      DebugLog.e('Error loading usage data: $e', category: LogCategory.service);
    }
  }

  /// Verificar si es hora de resetear el contador mensual
  void _checkAndResetIfNeeded() {
    final now = DateTime.now();
    if (now.isAfter(_fechaProximoReseteo.value)) {
      _resetMonthlyUsage();
    }
  }

  /// Resetear el uso mensual
  Future<void> _resetMonthlyUsage() async {
    try {
      _documentosUsadosEstesMes.value = 0;
      _fechaProximoReseteo.value = DateTime.now().add(PERIODO_RESETEO);
      _updateLimitStatus();
      
      await _saveUsageData();
      
      DebugLog.i('Monthly usage reset - New period until: ${_fechaProximoReseteo.value}', 
                 category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error resetting monthly usage: $e', category: LogCategory.service);
    }
  }

  /// Verificar si el usuario puede escanear un documento
  bool canScanDocument() {
    // Si es premium, siempre puede
    if (_isPremiumUser()) return true;
    
    // Si es gratuito, verificar límite
    _checkAndResetIfNeeded();
    return !_limiteAlcanzado.value;
  }

  /// Registrar que se escaneó un documento
  Future<bool> registerDocumentScanned() async {
    // Si es premium, no hay límites
    if (_isPremiumUser()) {
      await _incrementTotalDocuments();
      return true;
    }

    // Si es gratuito, verificar límite
    if (!canScanDocument()) {
      DebugLog.w('Document scan blocked - monthly limit reached', category: LogCategory.service);
      return false;
    }

    // Incrementar contador mensual
    _documentosUsadosEstesMes.value++;
    _updateLimitStatus();
    
    await _saveUsageData();
    await _incrementTotalDocuments();

    DebugLog.d('Document scanned - Monthly usage: ${_documentosUsadosEstesMes.value}/$LIMITE_DOCUMENTOS_GRATIS', 
               category: LogCategory.service);

    return true;
  }

  /// Verificar si el usuario es premium
  bool _isPremiumUser() {
    try {
      final subscriptionService = Get.find<SubscriptionService>();
      return subscriptionService.isActive;
    } catch (e) {
      return false;
    }
  }

  /// Incrementar contador total de documentos
  Future<void> _incrementTotalDocuments() async {
    try {
      final config = await _configProvider.obtenerConfiguracion();
      final newConfig = config.copyWith(
        documentosEscaneados: config.documentosEscaneados + 1,
      );
      await _configProvider.guardarConfiguracion(newConfig);
    } catch (e) {
      DebugLog.e('Error incrementing total documents: $e', category: LogCategory.service);
    }
  }

  /// Actualizar estado del límite
  void _updateLimitStatus() {
    _limiteAlcanzado.value = _documentosUsadosEstesMes.value >= LIMITE_DOCUMENTOS_GRATIS;
  }

  /// Guardar datos de uso
  Future<void> _saveUsageData() async {
    try {
      final config = await _configProvider.obtenerConfiguracion();
      final newConfig = config.copyWith(
        documentosEstesMes: _documentosUsadosEstesMes.value,
        fechaReseteoMensual: _fechaProximoReseteo.value.subtract(PERIODO_RESETEO),
      );
      await _configProvider.guardarConfiguracion(newConfig);
    } catch (e) {
      DebugLog.e('Error saving usage data: $e', category: LogCategory.service);
    }
  }

  /// Obtener información de límites para mostrar al usuario
  Map<String, dynamic> getLimitInfo() {
    return {
      'documentosUsados': _documentosUsadosEstesMes.value,
      'limiteTotal': LIMITE_DOCUMENTOS_GRATIS,
      'documentosRestantes': documentosRestantes,
      'diasParaReseteo': _fechaProximoReseteo.value.difference(DateTime.now()).inDays,
      'fechaReseteo': _fechaProximoReseteo.value,
      'limiteAlcanzado': _limiteAlcanzado.value,
      'esPremium': _isPremiumUser(),
    };
  }

  /// Mostrar diálogo de límite alcanzado
  Future<void> showLimitReachedDialog() async {
    await Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Límite Alcanzado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has alcanzado el límite de $LIMITE_DOCUMENTOS_GRATIS documentos este mes.',
              style: Get.theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Te Leo Premium - \$4.99/mes',
                        style: Get.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('✨ Documentos ilimitados'),
                  const Text('🎭 Voces premium naturales'),
                  const Text('📊 Estadísticas avanzadas'),
                  const Text('🎨 Temas premium'),
                  const Text('🚫 Sin anuncios'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'O espera ${_fechaProximoReseteo.value.difference(DateTime.now()).inDays} días para que se resetee tu límite gratuito.',
              style: Get.theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver Premium'),
          ),
        ],
      ),
    );
  }

  /// 🧪 MODO DESARROLLO: Simular límite alcanzado
  Future<void> simulateLimit() async {
    if (!kDebugMode) return;
    
    _documentosUsadosEstesMes.value = LIMITE_DOCUMENTOS_GRATIS;
    _updateLimitStatus();
    await _saveUsageData();
    
    DebugLog.i('🧪 SIMULATED: Monthly limit reached', category: LogCategory.service);
  }

  /// 🧪 MODO DESARROLLO: Resetear límites
  Future<void> resetLimitsForTesting() async {
    if (!kDebugMode) return;
    
    await _resetMonthlyUsage();
    DebugLog.i('🧪 SIMULATED: Limits reset for testing', category: LogCategory.service);
  }
}
