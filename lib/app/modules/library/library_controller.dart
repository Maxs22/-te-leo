import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/database_provider.dart';
import '../../data/models/documento.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/enhanced_tts_service.dart';
import '../../core/services/error_service.dart';
import '../../../global_widgets/global_widgets.dart';

/// Controlador para la página de biblioteca de documentos
/// Gestiona la lógica de visualización y organización de documentos guardados
class LibraryController extends GetxController {
  // Servicios
  final DatabaseProvider _databaseProvider = DatabaseProvider();
  final TTSService _ttsService = Get.find<TTSService>();
  final ErrorService _errorService = Get.find<ErrorService>();

  /// Lista observable de documentos
  final RxList<Documento> documentos = <Documento>[].obs;

  /// Indica si se están cargando los documentos
  final RxBool isLoading = false.obs;

  /// Documento que se está reproduciendo actualmente
  final Rxn<Documento> _documentoReproduciendo = Rxn<Documento>();
  Documento? get documentoReproduciendo => _documentoReproduciendo.value;

  /// Volver a la página principal
  void volverAlHome() {
    Get.back();
  }

  /// Cargar documentos de la base de datos local
  Future<void> cargarDocumentos() async {
    isLoading.value = true;
    
    try {
      final documentosCargados = await _databaseProvider.obtenerTodosLosDocumentos();
      documentos.value = documentosCargados;
    } catch (e) {
      await _errorService.handleDatabaseError(e, operacion: 'cargar documentos');
    } finally {
      isLoading.value = false;
    }
  }

  /// Abre un documento en el lector avanzado
  void abrirDocumento(Documento documento) {
    Get.to(
      () => SimpleDocumentReader(
        documento: documento,
        showControls: true,
        onClose: () async {
          // Asegurar que se detenga TTS al cerrar desde biblioteca
          try {
            final ttsService = Get.find<TTSService>();
            final enhancedTTSService = Get.find<EnhancedTTSService>();
            await ttsService.stopAll();
            await enhancedTTSService.stopAll();
            // Pausa adicional para asegurar que se detenga completamente
            await Future.delayed(const Duration(milliseconds: 300));
          } catch (e) {
            // Servicios no disponibles, continuar
          }
          Get.back();
        },
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Reproduce un documento con TTS (método simplificado para tarjetas)
  Future<void> reproducirDocumento(Documento documento) async {
    try {
      if (_documentoReproduciendo.value?.id == documento.id && 
          _ttsService.estado == EstadoTTS.reproduciendo) {
        // Si ya se está reproduciendo este documento, pausar
        await _ttsService.detener();
        _documentoReproduciendo.value = null;
      } else {
        // Reproducir nuevo documento
        _documentoReproduciendo.value = documento;
        await _ttsService.reproducir(documento.contenido);
        
        // Escuchar cuando termine la reproducción
        ever(_ttsService.estado.obs, (EstadoTTS estado) {
          if (estado == EstadoTTS.completado || estado == EstadoTTS.detenido) {
            _documentoReproduciendo.value = null;
          }
        });
      }
    } catch (e) {
      await _errorService.handleTTSError(e, contexto: 'Reproducción desde biblioteca');
    }
  }

  /// Elimina un documento
  Future<void> eliminarDocumento(Documento documento) async {
    final confirmar = await ModernDialog.mostrarConfirmacion(
      titulo: 'Eliminar documento',
      mensaje: '¿Estás seguro de que quieres eliminar "${documento.titulo}"?',
      textoConfirmar: 'Eliminar',
      textoCancelar: 'Cancelar',
      icono: Icons.delete_outline,
      colorIcono: Get.theme.colorScheme.error,
    );

    if (!confirmar) return;

    try {
      LoadingOverlay.mostrar(mensaje: 'Eliminando documento...');
      
      await _databaseProvider.eliminarDocumento(documento.id!);
      documentos.remove(documento);
      
      LoadingOverlay.ocultar();
      
      Get.snackbar(
        'Eliminado',
        'Documento eliminado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
      );
    } catch (e) {
      LoadingOverlay.ocultar();
      await _errorService.handleDatabaseError(e, operacion: 'eliminar documento');
    }
  }

  /// Alterna el estado de favorito de un documento
  Future<void> alternarFavorito(Documento documento) async {
    try {
      final documentoActualizado = documento.copyWith(
        esFavorito: !documento.esFavorito,
      );
      
      await _databaseProvider.actualizarDocumento(documentoActualizado);
      
      // Actualizar en la lista local
      final index = documentos.indexWhere((d) => d.id == documento.id);
      if (index != -1) {
        documentos[index] = documentoActualizado;
      }
      
      final mensaje = documentoActualizado.esFavorito 
          ? 'Agregado a favoritos' 
          : 'Removido de favoritos';
      
      Get.snackbar(
        mensaje,
        documentoActualizado.titulo,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      await _errorService.handleDatabaseError(e, operacion: 'actualizar favorito');
    }
  }

  /// Busca documentos por texto
  Future<void> buscarDocumentos(String termino) async {
    if (termino.trim().isEmpty) {
      await cargarDocumentos();
      return;
    }

    isLoading.value = true;
    
    try {
      final resultados = await _databaseProvider.buscarDocumentos(termino);
      documentos.value = resultados;
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error en la búsqueda: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtiene documentos favoritos
  Future<void> cargarFavoritos() async {
    isLoading.value = true;
    
    try {
      final favoritos = await _databaseProvider.obtenerDocumentosFavoritos();
      documentos.value = favoritos;
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error cargando favoritos: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifica si un documento se está reproduciendo
  bool estaReproduciendo(Documento documento) {
    return _documentoReproduciendo.value?.id == documento.id && 
           _ttsService.estado == EstadoTTS.reproduciendo;
  }

  /// Método llamado cuando el controlador es inicializado
  @override
  void onInit() {
    super.onInit();
    cargarDocumentos();
  }

  /// Método llamado cuando el controlador está listo
  @override
  void onReady() {
    super.onReady();
    // Lógica adicional cuando la vista está lista
  }

  /// Método llamado cuando el controlador es cerrado
  @override
  void onClose() {
    super.onClose();
    // Limpieza de recursos si es necesaria
  }
}
