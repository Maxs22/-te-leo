import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/core/services/app_update_service.dart';
import '../app/core/services/debug_console_service.dart';

/// Widget para mostrar notificaciones de actualización
class UpdateNotification extends StatelessWidget {
  final bool showOnlyWhenAvailable;
  final bool compact;

  const UpdateNotification({
    super.key,
    this.showOnlyWhenAvailable = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<AppUpdateService>(
      builder: (service) {
        return Obx(() {
          final updateInfo = service.updateInfo;
          final state = service.state;

          // No mostrar si no hay actualización y está configurado para solo mostrar cuando hay
          if (showOnlyWhenAvailable && !service.hasUpdate) {
            return const SizedBox.shrink();
          }

          // No mostrar durante verificación inicial
          if (state == UpdateState.checking && updateInfo == null) {
            return const SizedBox.shrink();
          }

          return _buildNotificationCard(service, updateInfo, state);
        });
      },
    );
  }

  Widget _buildNotificationCard(AppUpdateService service, UpdateInfo? updateInfo, UpdateState state) {
    Color cardColor;
    IconData icon;
    String title;
    String subtitle;
    List<Widget> actions = [];

    switch (state) {
      case UpdateState.checking:
        cardColor = Colors.blue;
        icon = Icons.refresh;
        title = 'Verificando actualizaciones...';
        subtitle = service.statusMessage;
        break;

      case UpdateState.available:
        cardColor = _getColorForUpdateType(updateInfo?.updateType);
        icon = Icons.system_update;
        title = _getTitleForUpdateType(updateInfo?.updateType);
        subtitle = updateInfo != null 
            ? 'Versión ${updateInfo.latestVersion} disponible (${updateInfo.fileSizeFormatted})'
            : 'Nueva versión disponible';
        actions = [
          if (!compact) ...[
            TextButton(
              onPressed: () => _showUpdateDetails(service, updateInfo),
              child: const Text('Detalles'),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton(
            onPressed: () => service.startUpdate(),
            style: ElevatedButton.styleFrom(backgroundColor: cardColor),
            child: const Text('Actualizar'),
          ),
        ];
        break;

      case UpdateState.downloading:
        cardColor = Colors.orange;
        icon = Icons.download;
        title = 'Descargando actualización...';
        subtitle = '${(service.downloadProgress * 100).toInt()}% completado';
        break;

      case UpdateState.readyToInstall:
        cardColor = Colors.green;
        icon = Icons.install_desktop;
        title = 'Listo para instalar';
        subtitle = 'La actualización está lista para instalarse';
        actions = [
          ElevatedButton(
            onPressed: () => service.completeFlexibleUpdate(),
            style: ElevatedButton.styleFrom(backgroundColor: cardColor),
            child: const Text('Instalar'),
          ),
        ];
        break;

      case UpdateState.installing:
        cardColor = Colors.amber;
        icon = Icons.settings;
        title = 'Instalando...';
        subtitle = 'Por favor espera mientras se instala la actualización';
        break;

      case UpdateState.completed:
        cardColor = Colors.green;
        icon = Icons.check_circle;
        title = 'Actualización completada';
        subtitle = 'Te Leo se ha actualizado correctamente';
        break;

      case UpdateState.failed:
        cardColor = Colors.red;
        icon = Icons.error;
        title = 'Error en actualización';
        subtitle = service.statusMessage.isNotEmpty ? service.statusMessage : 'No se pudo completar la actualización';
        actions = [
          TextButton(
            onPressed: () => service.checkForUpdates(),
            child: const Text('Reintentar'),
          ),
        ];
        break;

      default:
        return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactNotification(cardColor, icon, title, actions);
    } else {
      return _buildFullNotification(cardColor, icon, title, subtitle, actions, service);
    }
  }

  Widget _buildCompactNotification(Color color, IconData icon, String title, List<Widget> actions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildFullNotification(
    Color color, 
    IconData icon, 
    String title, 
    String subtitle, 
    List<Widget> actions,
    AppUpdateService service,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Get.theme.textTheme.bodyMedium?.copyWith(
                              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Botón de cerrar
                  IconButton(
                    onPressed: () => _dismissNotification(service),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),

              // Barra de progreso para descarga
              if (service.state == UpdateState.downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: service.downloadProgress,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],

              // Acciones
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForUpdateType(UpdateType? type) {
    switch (type) {
      case UpdateType.forced:
      case UpdateType.critical:
        return Colors.red;
      case UpdateType.recommended:
        return Colors.orange;
      case UpdateType.optional:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTitleForUpdateType(UpdateType? type) {
    switch (type) {
      case UpdateType.forced:
        return 'Actualización Obligatoria';
      case UpdateType.critical:
        return 'Actualización Crítica';
      case UpdateType.recommended:
        return 'Actualización Recomendada';
      case UpdateType.optional:
        return 'Actualización Disponible';
      default:
        return 'Nueva Actualización';
    }
  }

  void _showUpdateDetails(AppUpdateService service, UpdateInfo? updateInfo) {
    if (updateInfo == null) return;

    DebugLog.i('Showing update details dialog', category: LogCategory.ui);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _getColorForUpdateType(updateInfo.updateType),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalles de Actualización',
                      style: Get.theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Información de versión
              _buildDetailRow('Versión Actual:', updateInfo.currentVersion),
              _buildDetailRow('Nueva Versión:', updateInfo.latestVersion),
              _buildDetailRow('Tipo:', _getUpdateTypeText(updateInfo.updateType)),
              _buildDetailRow('Tamaño:', updateInfo.fileSizeFormatted),

              if (updateInfo.releaseDate != null)
                _buildDetailRow('Fecha:', _formatDate(updateInfo.releaseDate!)),

              const SizedBox(height: 20),

              // Notas de la versión
              Text(
                'Notas de la Versión:',
                style: Get.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  updateInfo.releaseNotes ?? 'No hay notas de versión disponibles.',
                  style: Get.theme.textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      service.startUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getColorForUpdateType(updateInfo.updateType),
                    ),
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getUpdateTypeText(UpdateType type) {
    switch (type) {
      case UpdateType.forced:
        return 'Obligatoria';
      case UpdateType.critical:
        return 'Crítica';
      case UpdateType.recommended:
        return 'Recomendada';
      case UpdateType.optional:
        return 'Opcional';
      default:
        return 'Desconocida';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _dismissNotification(AppUpdateService service) {
    // En una implementación completa, podríamos agregar lógica para
    // recordar que el usuario desestimó la notificación
    DebugLog.d('Update notification dismissed by user', category: LogCategory.ui);
  }
}

/// Widget flotante para mostrar estado de actualización
class UpdateFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const UpdateFloatingButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<AppUpdateService>(
      builder: (service) {
        return Obx(() {
          if (!service.hasUpdate) {
            return const SizedBox.shrink();
          }

          final updateInfo = service.updateInfo!;
          final color = _getColorForUpdateType(updateInfo.updateType);

          return FloatingActionButton.extended(
            onPressed: onPressed ?? () => service.startUpdate(),
            backgroundColor: color,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.system_update),
            label: Text(_getButtonText(updateInfo.updateType)),
            tooltip: 'Actualizar Te Leo',
          );
        });
      },
    );
  }

  Color _getColorForUpdateType(UpdateType type) {
    switch (type) {
      case UpdateType.forced:
      case UpdateType.critical:
        return Colors.red;
      case UpdateType.recommended:
        return Colors.orange;
      case UpdateType.optional:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getButtonText(UpdateType type) {
    switch (type) {
      case UpdateType.forced:
        return 'Actualizar';
      case UpdateType.critical:
        return 'Actualizar';
      case UpdateType.recommended:
        return 'Actualizar';
      case UpdateType.optional:
        return 'Actualizar';
      default:
        return 'Actualizar';
    }
  }
}
