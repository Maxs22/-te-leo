import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'library_controller.dart';
import '../../../global_widgets/global_widgets.dart';

/// Página de biblioteca de documentos de Te Leo
/// Muestra los documentos guardados y permite gestionarlos
class LibraryPage extends GetView<LibraryController> {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.volverAlHome,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return TeLeoEmptyStates.cargandoDatos();
        }

        if (controller.documentos.isEmpty) {
          return TeLeoEmptyStates.bibliotecaVacia(
            onEscanear: () {
              Get.toNamed('/scan-text'); // Ir directamente a escanear
            },
          );
        }

        return _buildDocumentList(context);
      }),
    );
  }


  /// Construye la lista de documentos
  Widget _buildDocumentList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: controller.documentos.length,
      itemBuilder: (context, index) {
        return Obx(() {
          final documento = controller.documentos[index];
          return DocumentCard(
            titulo: documento.titulo,
            resumen: documento.resumen,
            fechaModificacion: documento.fechaModificacion,
            esFavorito: documento.esFavorito,
            onTap: () => controller.abrirDocumento(documento), // Usar lector avanzado
            onFavoriteToggle: () => controller.alternarFavorito(documento),
            onDelete: () => controller.eliminarDocumento(documento),
            onShare: () {
              // TODO: Implementar compartir
              Get.snackbar(
                'Compartir',
                'Función en desarrollo',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          );
        });
      },
    );
  }

}
