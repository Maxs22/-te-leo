import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/database_provider.dart';
import '../../data/models/documento.dart';
import '../../data/models/progreso_lectura.dart';
import '../../../global_widgets/modern_dialog.dart';
import 'debug_console_service.dart';

/// Servicio de gestión de progreso de lectura
/// Maneja el guardado y recuperación automática del progreso de lectura
class ReadingProgressService extends GetxService {
  final DatabaseProvider _databaseProvider = DatabaseProvider();
  
  /// Timer para guardar progreso automáticamente
  Timer? _autoSaveTimer;
  
  /// Progreso actual que se está guardando
  ProgresoLectura? _currentProgress;
  
  /// Intervalo de guardado automático (en segundos)
  final int _autoSaveInterval = 5;
  
  /// Indica si el servicio está activo
  final RxBool _isActive = false.obs;
  bool get isActive => _isActive.value;

  @override
  void onInit() {
    super.onInit();
    DebugLog.service('Reading Progress Service inicializado', serviceName: 'ReadingProgress');
  }

  @override
  void onClose() {
    _stopAutoSave();
    super.onClose();
  }

  /// Inicia el seguimiento de progreso para un documento
  Future<void> startTracking(Documento documento) async {
    try {
      _isActive.value = true;
      
      // Verificar si hay progreso previo
      final progresoExistente = await _databaseProvider.obtenerProgresoLectura(documento.id!);
      
      if (progresoExistente != null && progresoExistente.tieneProgresoSignificativo) {
        // Modal deshabilitado - ahora se maneja desde library_controller.dart con ResumeReadingDialog
        // final shouldResume = await _showResumeDialog(documento, progresoExistente);
        
        // if (shouldResume) {
        //   return; // El usuario eligió continuar, no hacer nada más
        // } else {
        //   // El usuario eligió empezar desde el principio
        //   await _databaseProvider.reiniciarProgresoLectura(documento.id!);
        // }
        
        // Por ahora, simplemente usar el progreso existente sin mostrar modal
        _currentProgress = progresoExistente;
        return;
      }
      
      // Inicializar progreso nuevo
      _currentProgress = ProgresoLectura.nuevo(documentoId: documento.id!);
      await _databaseProvider.guardarProgresoLectura(_currentProgress!);
      
      _startAutoSave();
    } catch (e) {
        DebugLog.e('Error iniciando seguimiento: $e', category: LogCategory.service);
    }
  }

  /// Actualiza el progreso actual
  Future<void> updateProgress({
    required int documentoId,
    double? progressPercentage,
    int? characterPosition,
    int? wordPosition,
    Duration? elapsedTime,
    String? currentFragment,
  }) async {
    try {
      if (!_isActive.value) return;
      
      await _databaseProvider.actualizarProgresoLectura(
        documentoId: documentoId,
        porcentajeProgreso: progressPercentage,
        posicionCaracter: characterPosition,
        posicionPalabra: wordPosition,
        tiempoReproducido: elapsedTime,
        fragmentoActual: currentFragment,
      );
      
      // Actualizar progreso local
      if (_currentProgress?.documentoId == documentoId) {
        _currentProgress = _currentProgress!.copyWith(
          porcentajeProgreso: progressPercentage,
          posicionCaracter: characterPosition,
          posicionPalabra: wordPosition,
          tiempoReproducido: elapsedTime,
          fragmentoActual: currentFragment,
        );
      }
    } catch (e) {
        DebugLog.e('Error actualizando progreso: $e', category: LogCategory.database);
    }
  }

  /// Marca un documento como completado
  Future<void> markAsCompleted(int documentoId) async {
    try {
      await _databaseProvider.marcarDocumentoComoCompleto(documentoId);
      _stopAutoSave();
      _isActive.value = false;
      
      Get.snackbar(
        'Lectura completada',
        'Has terminado de leer este documento',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      DebugLog.i('Error marcando como completado: $e');
    }
  }

  /// Detiene el seguimiento del progreso
  Future<void> stopTracking() async {
    _stopAutoSave();
    _isActive.value = false;
    _currentProgress = null;
  }

  /// Obtiene el progreso de un documento específico
  Future<ProgresoLectura?> getProgress(int documentoId) async {
    try {
      return await _databaseProvider.obtenerProgresoLectura(documentoId);
    } catch (e) {
      DebugLog.i('Error obteniendo progreso: $e');
      return null;
    }
  }

  /// Obtiene todos los documentos en progreso
  Future<List<Map<String, dynamic>>> getDocumentsInProgress() async {
    try {
      return await _databaseProvider.obtenerDocumentosEnProgreso();
    } catch (e) {
      DebugLog.i('Error obteniendo documentos en progreso: $e');
      return [];
    }
  }

  /// Reinicia el progreso de un documento
  Future<void> resetProgress(int documentoId) async {
    try {
      await _databaseProvider.reiniciarProgresoLectura(documentoId);
      
      if (_currentProgress?.documentoId == documentoId) {
        _currentProgress = ProgresoLectura.nuevo(documentoId: documentoId);
      }
      
      Get.snackbar(
        'Progreso reiniciado',
        'El documento comenzará desde el inicio',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error reiniciando progreso: $e',
      );
    }
  }

  /// Inicia el guardado automático de progreso
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _autoSaveInterval),
      (timer) async {
        if (_currentProgress != null && _isActive.value) {
          try {
            await _databaseProvider.guardarProgresoLectura(_currentProgress!);
          } catch (e) {
            DebugLog.i('Error en guardado automático: $e');
          }
        }
      },
    );
  }

  /// Detiene el guardado automático
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Obtiene estadísticas de progreso
  Future<Map<String, dynamic>> getProgressStats() async {
    try {
      final stats = await _databaseProvider.obtenerEstadisticasProgreso();
      final documentsInProgress = await getDocumentsInProgress();
      
      return {
        ...stats,
        'documentos_recientes': documentsInProgress.take(5).toList(),
      };
    } catch (e) {
      DebugLog.i('Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Limpia progreso antiguo (más de 30 días sin actualizar)
  Future<void> cleanOldProgress() async {
    try {
      final db = await _databaseProvider.database;
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      await db.delete(
        'progreso_lectura',
        where: 'ultima_actualizacion < ? AND esta_completo = 0',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );
      
      DebugLog.i('Progreso antiguo limpiado');
    } catch (e) {
      DebugLog.i('Error limpiando progreso antiguo: $e');
    }
  }

  /// Exporta el progreso de todos los documentos
  Future<Map<String, dynamic>> exportProgress() async {
    try {
      final documentsWithProgress = await _databaseProvider.obtenerDocumentosConProgreso();
      
      return {
        'export_date': DateTime.now().toIso8601String(),
        'total_documents': documentsWithProgress.length,
        'progress_data': documentsWithProgress,
      };
    } catch (e) {
      DebugLog.i('Error exportando progreso: $e');
      return {};
    }
  }

  /// Verifica si un documento tiene progreso guardado
  Future<bool> hasProgress(int documentoId) async {
    try {
      final progreso = await getProgress(documentoId);
      return progreso?.tieneProgresoSignificativo == true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el último documento leído
  Future<Map<String, dynamic>?> getLastReadDocument() async {
    try {
      final documentsInProgress = await getDocumentsInProgress();
      return documentsInProgress.isNotEmpty ? documentsInProgress.first : null;
    } catch (e) {
      DebugLog.i('Error obteniendo último documento: $e');
      return null;
    }
  }
}
