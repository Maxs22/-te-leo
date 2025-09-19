import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/core/services/access_validation_service.dart';
import '../app/core/services/debug_console_service.dart';
import 'modern_button.dart';

/// Página mostrada cuando el acceso es denegado
class AccessDeniedPage extends StatelessWidget {
  final AccessValidationResult result;
  final VoidCallback? onRetry;
  final VoidCallback? onExit;

  const AccessDeniedPage({
    super.key,
    required this.result,
    this.onRetry,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header con logo y título
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono de error
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        _getIconForReason(result.deniedReason),
                        size: 60,
                        color: Get.theme.colorScheme.error,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Título
                    Text(
                      _getTitleForReason(result.deniedReason),
                      style: Get.theme.textTheme.headlineSmall?.copyWith(
                        color: Get.theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Contenido principal
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mensaje principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Get.theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            result.message,
                            style: Get.theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          
                          // Información adicional si existe
                          if (result.retryAfter != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Get.theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 20,
                                    color: Get.theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Podrás intentar nuevamente después de: ${_formatRetryTime(result.retryAfter!)}',
                                      style: Get.theme.textTheme.bodySmall?.copyWith(
                                        color: Get.theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Información adicional de debugging en modo debug
                          if (GetPlatform.isAndroid && result.additionalData != null) ...[
                            const SizedBox(height: 12),
                            ExpansionTile(
                              title: Text(
                                'Información Técnica',
                                style: Get.theme.textTheme.bodySmall,
                              ),
                              children: [
                                Text(
                                  result.additionalData.toString(),
                                  style: Get.theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botones de acción
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botones según el tipo de error
                    ..._buildActionButtons(),
                    
                    const SizedBox(height: 16),
                    
                    // Información de contacto
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '¿Necesitas ayuda?',
                            style: Get.theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contacta a soporte: teleo.app@gmail.com',
                            style: Get.theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obtener icono según la razón de denegación
  IconData _getIconForReason(AccessDeniedReason? reason) {
    switch (reason) {
      case AccessDeniedReason.expiredLicense:
        return Icons.card_membership;
      case AccessDeniedReason.unsupportedDevice:
        return Icons.phonelink_off;
      case AccessDeniedReason.rootedDevice:
        return Icons.security;
      case AccessDeniedReason.debuggerDetected:
        return Icons.bug_report;
      case AccessDeniedReason.tampered:
        return Icons.warning;
      case AccessDeniedReason.networkUnavailable:
        return Icons.wifi_off;
      case AccessDeniedReason.maintenanceMode:
        return Icons.build;
      case AccessDeniedReason.bannedDevice:
        return Icons.block;
      case AccessDeniedReason.invalidSignature:
        return Icons.verified_user_outlined;
      default:
        return Icons.error_outline;
    }
  }

  /// Obtener título según la razón de denegación
  String _getTitleForReason(AccessDeniedReason? reason) {
    switch (reason) {
      case AccessDeniedReason.expiredLicense:
        return 'Licencia Expirada';
      case AccessDeniedReason.unsupportedDevice:
        return 'Dispositivo No Compatible';
      case AccessDeniedReason.rootedDevice:
        return 'Dispositivo Modificado';
      case AccessDeniedReason.debuggerDetected:
        return 'Debugger Detectado';
      case AccessDeniedReason.tampered:
        return 'App Modificada';
      case AccessDeniedReason.networkUnavailable:
        return 'Sin Conexión';
      case AccessDeniedReason.maintenanceMode:
        return 'Mantenimiento';
      case AccessDeniedReason.bannedDevice:
        return 'Dispositivo Bloqueado';
      case AccessDeniedReason.invalidSignature:
        return 'Firma Inválida';
      default:
        return 'Acceso Denegado';
    }
  }

  /// Construir botones de acción según el tipo de error
  List<Widget> _buildActionButtons() {
    List<Widget> buttons = [];

    switch (result.deniedReason) {
      case AccessDeniedReason.expiredLicense:
        buttons.addAll([
          ModernButton(
            text: 'Renovar Suscripción',
            onPressed: () => _handleRenewSubscription(),
            type: ModernButtonType.primary,
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          if (result.allowRetry)
            ModernButton(
              text: 'Verificar Nuevamente',
              onPressed: onRetry,
              type: ModernButtonType.secondary,
              isExpanded: true,
            ),
        ]);
        break;

      case AccessDeniedReason.networkUnavailable:
        buttons.addAll([
          ModernButton(
            text: 'Verificar Conexión',
            onPressed: onRetry,
            type: ModernButtonType.primary,
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          ModernButton(
            text: 'Usar Sin Conexión',
            onPressed: () => _handleOfflineMode(),
            type: ModernButtonType.secondary,
            isExpanded: true,
          ),
        ]);
        break;

      case AccessDeniedReason.maintenanceMode:
        buttons.addAll([
          ModernButton(
            text: 'Verificar Estado',
            onPressed: onRetry,
            type: ModernButtonType.primary,
            isExpanded: true,
          ),
        ]);
        break;

      case AccessDeniedReason.unsupportedDevice:
      case AccessDeniedReason.rootedDevice:
      case AccessDeniedReason.tampered:
        buttons.addAll([
          ModernButton(
            text: 'Contactar Soporte',
            onPressed: () => _handleContactSupport(),
            type: ModernButtonType.secondary,
            isExpanded: true,
          ),
        ]);
        break;

      default:
        if (result.allowRetry) {
          buttons.addAll([
            ModernButton(
              text: 'Reintentar',
              onPressed: onRetry,
              type: ModernButtonType.primary,
              isExpanded: true,
            ),
          ]);
        }
    }

    // Botón de salir siempre disponible
    buttons.addAll([
      const SizedBox(height: 12),
      ModernButton(
        text: 'Salir',
        onPressed: onExit ?? () => _handleExit(),
        type: ModernButtonType.text,
        isExpanded: true,
      ),
    ]);

    return buttons;
  }

  /// Formatear tiempo de reintento
  String _formatRetryTime(DateTime retryAfter) {
    final now = DateTime.now();
    final difference = retryAfter.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} día(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora(s)';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto(s)';
    } else {
      return 'unos segundos';
    }
  }

  /// Manejar renovación de suscripción
  void _handleRenewSubscription() {
    DebugLog.i('User requested subscription renewal', category: LogCategory.ui);
    // Navegar a pantalla de suscripción o abrir store
    Get.toNamed('/subscription');
  }

  /// Manejar modo offline
  void _handleOfflineMode() {
    DebugLog.i('User requested offline mode', category: LogCategory.ui);
    // Configurar app para modo offline y continuar
    Get.back();
  }

  /// Manejar contacto con soporte
  void _handleContactSupport() {
    DebugLog.i('User requested support contact', category: LogCategory.ui);
    // Abrir email o chat de soporte
    // En producción, usar url_launcher para abrir email
    Get.snackbar(
      'Soporte',
      'Contacta a: teleo.app@gmail.com',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Manejar salida de la app
  void _handleExit() {
    DebugLog.i('User requested app exit from access denied', category: LogCategory.ui);
    // Cerrar la aplicación
    Get.back();
  }
}

/// Widget para mostrar estado de validación en tiempo real
class AccessValidationStatus extends StatelessWidget {
  final AccessValidationService service;

  const AccessValidationStatus({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = service.state;
      final message = service.message;

      Color statusColor;
      IconData statusIcon;

      switch (state) {
        case AccessValidationState.validating:
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_empty;
          break;
        case AccessValidationState.granted:
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case AccessValidationState.denied:
        case AccessValidationState.expired:
        case AccessValidationState.deviceNotSupported:
          statusColor = Colors.red;
          statusIcon = Icons.error;
          break;
        case AccessValidationState.networkRequired:
          statusColor = Colors.blue;
          statusIcon = Icons.wifi_off;
          break;
        case AccessValidationState.maintenanceMode:
          statusColor = Colors.amber;
          statusIcon = Icons.build;
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }
}
