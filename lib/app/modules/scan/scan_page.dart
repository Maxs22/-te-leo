import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global_widgets/global_widgets.dart';
import 'scan_controller.dart';

/// Página de escaneo de texto de Te Leo
/// Interfaz completa para capturar, procesar y guardar texto desde imágenes
class ScanPage extends GetView<ScanController> {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escanear Texto'),
          centerTitle: true,
          actions: [
            if (controller.estado == EstadoEscaneo.mostrandoResultado)
              IconButton(
                onPressed: controller.reiniciarEscaneo,
                icon: const Icon(Icons.refresh),
                tooltip: 'Escanear otra imagen',
              ),
          ],
        ),
        body: () {
          switch (controller.estado) {
            case EstadoEscaneo.inicial:
              return _buildEstadoInicial();
            case EstadoEscaneo.seleccionandoImagen:
              return _buildCargando('Seleccionando imagen...');
            case EstadoEscaneo.procesandoOCR:
              return _buildCargando('Procesando imagen...');
            case EstadoEscaneo.mostrandoResultado:
              return _buildResultado();
            case EstadoEscaneo.guardando:
              return _buildCargando('Guardando documento...');
            case EstadoEscaneo.completado:
              return _buildCompletado();
            case EstadoEscaneo.error:
              return _buildError();
          }
        }(),
      );
    });
  }

  /// Construye el estado inicial con botón para iniciar escaneo
  Widget _buildEstadoInicial() {
    return EmptyState(
      icono: Icons.document_scanner,
      titulo: 'Escanear Texto',
      descripcion: 'Captura texto desde fotos o documentos y conviértelo en texto editable y audible',
      textoBoton: 'Comenzar Escaneo',
      onBotonPressed: controller.iniciarEscaneo,
      widgetPersonalizado: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Get.theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Get.theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Toma una foto del texto que quieres leer', style: Get.theme.textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.photo_library, color: Get.theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('O selecciona una imagen de tu galería', style: Get.theme.textTheme.bodyMedium)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el estado de carga
  Widget _buildCargando(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensaje, style: Get.theme.textTheme.titleMedium),
          if (controller.progreso > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: controller.progreso,
                backgroundColor: Get.theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 8),
            Text(controller.progresoTexto, style: Get.theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  /// Construye la vista de resultado con texto extraído
  Widget _buildResultado() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen capturada (si existe)
          if (controller.imagenActual != null) ...[
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imagen escaneada',
                    style: Get.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Get.theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(controller.imagenActual!.rutaArchivo),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Estadísticas del texto
          if (controller.estadisticas != null) ...[
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas del texto',
                    style: Get.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Get.theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          titulo: 'Palabras',
                          valor: '${controller.estadisticas!.totalPalabras}',
                          icono: Icons.text_fields,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatsCard(
                          titulo: 'Caracteres',
                          valor: '${controller.estadisticas!.totalCaracteres}',
                          icono: Icons.abc,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Campo de título
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Título del documento',
                  style: Get.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: controller.tituloDocumento)
                    ..selection = TextSelection.fromPosition(TextPosition(offset: controller.tituloDocumento.length)),
                  onChanged: (value) => controller.tituloDocumento = value,
                  decoration: InputDecoration(
                    hintText: 'Ingresa un título para el documento',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Texto extraído (editable)
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Texto extraído',
                        style: Get.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Botón de reproducir/pausar
                    IconButton(
                      onPressed: controller.reproducirTexto,
                      icon: Icon(
                        controller.isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Get.theme.colorScheme.primary,
                      ),
                      tooltip: controller.isPlaying ? 'Detener' : 'Reproducir',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(minHeight: 200),
                  child: TextField(
                    controller: TextEditingController(text: controller.textoExtraido)
                      ..selection = TextSelection.fromPosition(TextPosition(offset: controller.textoExtraido.length)),
                    onChanged: (value) => controller.textoExtraido = value,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'El texto extraído aparecerá aquí...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      alignLabelWithHint: true,
                    ),
                    style: Get.theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Nueva imagen',
                  onPressed: controller.reiniciarEscaneo,
                  type: ModernButtonType.outlined,
                  icon: Icons.refresh,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ModernButton(
                  text: 'Guardar documento',
                  onPressed: controller.puedeGuardar ? controller.guardarDocumento : null,
                  type: ModernButtonType.primary,
                  icon: Icons.save,
                ),
              ),
            ],
          ),

          // Espacio adicional para navegación
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Construye el estado completado
  Widget _buildCompletado() {
    return EmptyState(
      icono: Icons.check_circle,
      titulo: 'Documento guardado',
      descripcion: 'Tu documento ha sido guardado exitosamente en la biblioteca',
      colorIcono: Colors.green,
      textoBoton: 'Ver en biblioteca',
      onBotonPressed: () {
        Get.back();
        Get.toNamed('/library');
      },
    );
  }

  /// Construye el estado de error
  Widget _buildError() {
    return EmptyState(
      icono: Icons.error_outline,
      titulo: 'Error en el procesamiento',
      descripcion: controller.mensajeEstado.isNotEmpty
          ? controller.mensajeEstado
          : 'Ocurrió un error inesperado durante el procesamiento',
      colorIcono: Colors.red,
      textoBoton: 'Intentar de nuevo',
      onBotonPressed: controller.reiniciarEscaneo,
    );
  }
}
