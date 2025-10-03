import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global_widgets/ads/ads_exports.dart';
import '../../../global_widgets/global_widgets.dart';
import 'library_controller.dart';

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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: controller.volverAlHome),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: PremiumBadge(showOnlyWhenPremium: false, size: BadgeSize.small),
          ),
        ],
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
      itemCount: controller.documentos.length + 3, // +3 para anuncios
      itemBuilder: (context, index) {
        // Banner en la parte superior
        if (index == 0) {
          return const Column(children: [BannerAdWidget(margin: EdgeInsets.only(bottom: 16))]);
        }

        // Native ad cada 5 documentos
        if ((index - 1) % 6 == 5 && index < controller.documentos.length + 1) {
          return const Column(children: [NativeAdWidget(margin: EdgeInsets.symmetric(vertical: 8))]);
        }

        // Ajustar índice para anuncios insertados
        int docIndex = index - 1 - ((index - 1) ~/ 6);
        if (docIndex >= controller.documentos.length) {
          return const SizedBox.shrink();
        }

        final documento = controller.documentos[docIndex];
        return DocumentCard(
          titulo: documento.titulo,
          resumen: documento.resumen,
          fechaModificacion: documento.fechaModificacion,
          esFavorito: documento.esFavorito,
          onTap: () => controller.abrirDocumento(documento),
          onFavoriteToggle: () => controller.alternarFavorito(documento),
          onDelete: () => controller.eliminarDocumento(documento),
        );
      },
    );
  }
}
