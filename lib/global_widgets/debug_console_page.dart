import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../app/core/services/debug_console_service.dart';
import 'modern_card.dart';

/// Página de consola de debug integrada
class DebugConsolePage extends GetView<DebugConsoleController> {
  const DebugConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DebugConsoleController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Debug Console'),
            centerTitle: true,
            actions: [
              // Configuraciones
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'clear':
                      await controller.clearLogs();
                      break;
                    case 'export':
                      await controller.exportLogs();
                      break;
                    case 'settings':
                      controller.showSettings();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Configuración'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Exportar logs'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear_all, color: Colors.red),
                      title: Text('Limpiar logs'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Estadísticas y filtros
              _buildStatsAndFilters(controller),

              // Barra de búsqueda
              _buildSearchBar(controller),

              // Lista de logs
              Expanded(child: _buildLogsList(controller)),
            ],
          ),
          floatingActionButton: Obx(
            () => FloatingActionButton(
              onPressed: controller.toggleAutoScroll,
              tooltip: controller.debugService.autoScroll ? 'Pausar auto-scroll' : 'Activar auto-scroll',
              child: Icon(controller.debugService.autoScroll ? Icons.pause : Icons.play_arrow),
            ),
          ),
        );
      },
    );
  }

  /// Construye estadísticas y filtros
  Widget _buildStatsAndFilters(DebugConsoleController controller) {
    return ModernCard(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Estadísticas rápidas
          Obx(() {
            final stats = controller.debugService.getStats();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Total', '${stats['total_logs']}', Colors.blue),
                _buildStatChip('Errores', '${stats['by_level']?['error'] ?? 0}', Colors.red),
                _buildStatChip('Warnings', '${stats['by_level']?['warning'] ?? 0}', Colors.orange),
                _buildStatChip('Info', '${stats['by_level']?['info'] ?? 0}', Colors.green),
              ],
            );
          }),

          const SizedBox(height: 12),

          // Filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...LogLevel.values.map(
                  (level) => Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(level.toString().split('.').last),
                        selected: controller.debugService.levelFilters.contains(level),
                        onSelected: (selected) => controller.toggleLevelFilter(level),
                        avatar: Icon(_getLogLevelIcon(level), size: 16, color: _getLogLevelColor(level)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye barra de búsqueda
  Widget _buildSearchBar(DebugConsoleController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: controller.updateSearch,
        decoration: InputDecoration(
          hintText: 'Buscar en logs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(
            () => controller.debugService.searchFilter.isNotEmpty
                ? IconButton(onPressed: controller.clearSearch, icon: const Icon(Icons.clear))
                : const SizedBox.shrink(),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Construye la lista de logs
  Widget _buildLogsList(DebugConsoleController controller) {
    return Obx(() {
      final filteredLogs = controller.getFilteredLogs();

      if (filteredLogs.isEmpty) {
        return const Center(child: Text('No hay logs que mostrar'));
      }

      return ListView.builder(
        reverse: controller.debugService.autoScroll,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final entry = filteredLogs[index];
          return _buildLogEntry(entry);
        },
      );
    });
  }

  /// Construye una entrada de log individual
  Widget _buildLogEntry(LogEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ExpansionTile(
        leading: Icon(entry.icon, color: entry.color, size: 20),
        title: Text(
          entry.message,
          style: TextStyle(
            color: entry.color,
            fontWeight: entry.level == LogLevel.error || entry.level == LogLevel.critical
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(entry.timestamp.toIso8601String().substring(11, 19), style: Get.theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.category.toString().split('.').last,
                style: TextStyle(fontSize: 10, color: entry.color, fontWeight: FontWeight.bold),
              ),
            ),
            if (entry.tag != null) ...[
              const SizedBox(width: 4),
              Text('[${entry.tag}]', style: Get.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ],
        ),
        children: [
          if (entry.metadata != null || entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.metadata != null) ...[
                    Text('Metadata:', style: Get.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Get.theme.colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        entry.metadata.toString(),
                        style: Get.theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ],

                  if (entry.stackTrace != null) ...[
                    if (entry.metadata != null) const SizedBox(height: 12),
                    Text('Stack Trace:', style: Get.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        entry.stackTrace!,
                        style: Get.theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: Colors.red),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '${entry.message}\n${entry.metadata ?? ''}\n${entry.stackTrace ?? ''}'),
                          );
                          Get.snackbar('Copiado', 'Log copiado al portapapeles', snackPosition: SnackPosition.BOTTOM);
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Construye chip de estadística
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  IconData _getLogLevelIcon(LogLevel level) {
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

  Color _getLogLevelColor(LogLevel level) {
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
}

/// Controlador para la página de debug console
class DebugConsoleController extends GetxController {
  late final DebugConsoleService debugService;

  @override
  void onInit() {
    super.onInit();
    debugService = Get.find<DebugConsoleService>();
  }

  /// Obtiene logs filtrados
  List<LogEntry> getFilteredLogs() {
    return debugService.getFilteredLogs();
  }

  /// Alterna filtro de nivel
  void toggleLevelFilter(LogLevel level) {
    final isEnabled = debugService.levelFilters.contains(level);
    debugService.updateLevelFilter(level, !isEnabled);
  }

  /// Actualiza búsqueda
  void updateSearch(String search) {
    debugService.updateSearchFilter(search);
  }

  /// Limpia búsqueda
  void clearSearch() {
    debugService.updateSearchFilter('');
  }

  /// Limpia logs
  Future<void> clearLogs() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Limpiar logs'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los logs?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      debugService.clearLogs();
      Get.snackbar('Logs limpiados', 'Todos los logs han sido eliminados', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Exporta logs
  Future<void> exportLogs() async {
    try {
      final logsText = debugService.exportLogs();

      await Clipboard.setData(ClipboardData(text: logsText));

      Get.snackbar(
        'Logs exportados',
        'Los logs han sido copiados al portapapeles',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron exportar los logs: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  /// Muestra configuraciones de la consola
  void showSettings() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Configuración de Debug Console',
              style: Get.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Obx(
              () => SwitchListTile(
                title: const Text('Consola habilitada'),
                subtitle: const Text('Activar/desactivar logging'),
                value: debugService.isEnabled,
                onChanged: debugService.setEnabled,
              ),
            ),

            Obx(
              () => SwitchListTile(
                title: const Text('Log a consola del sistema'),
                subtitle: const Text('Mostrar logs en la consola de desarrollo'),
                value: debugService.logToConsole,
                onChanged: debugService.setLogToConsole,
              ),
            ),

            Obx(
              () => SwitchListTile(
                title: const Text('Auto-scroll'),
                subtitle: const Text('Seguir automáticamente los nuevos logs'),
                value: debugService.autoScroll,
                onChanged: debugService.setAutoScroll,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Alterna auto-scroll
  void toggleAutoScroll() {
    debugService.setAutoScroll(!debugService.autoScroll);
  }
}
