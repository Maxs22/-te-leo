import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget de loading fullscreen moderno con fondo desenfocado
/// Proporciona una experiencia visual elegante durante las operaciones asíncronas
class LoadingOverlay extends StatelessWidget {
  final String? mensaje;
  final bool mostrarProgreso;
  final double? progreso;
  final VoidCallback? onCancelar;

  const LoadingOverlay({
    super.key,
    this.mensaje,
    this.mostrarProgreso = false,
    this.progreso,
    this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de carga animado
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        value: mostrarProgreso ? progreso : null,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Mensaje personalizable
                    if (mensaje != null) ...[
                      Text(
                        mensaje!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Barra de progreso si es necesaria
                    if (mostrarProgreso && progreso != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          value: progreso,
                          backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progreso! * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    
                    // Botón de cancelar si es necesario
                    if (onCancelar != null) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: onCancelar,
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el overlay de loading
  static void mostrar({
    String? mensaje,
    bool mostrarProgreso = false,
    double? progreso,
    VoidCallback? onCancelar,
  }) {
    Get.dialog(
      LoadingOverlay(
        mensaje: mensaje,
        mostrarProgreso: mostrarProgreso,
        progreso: progreso,
        onCancelar: onCancelar,
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
    );
  }

  /// Oculta el overlay de loading
  static void ocultar() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// Actualiza el progreso del loading
  static void actualizarProgreso(double progreso, {String? mensaje}) {
    // Esta función requeriría un controlador reactivo para actualizar en tiempo real
    // Por simplicidad, se puede reimplementar con GetX controllers si es necesario
  }
}

/// Controlador reactivo para el loading overlay
class LoadingController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxString _mensaje = ''.obs;
  final RxDouble _progreso = 0.0.obs;
  final RxBool _mostrarProgreso = false.obs;

  bool get isLoading => _isLoading.value;
  String get mensaje => _mensaje.value;
  double get progreso => _progreso.value;
  bool get mostrarProgreso => _mostrarProgreso.value;

  void mostrarLoading({
    String mensaje = 'Cargando...',
    bool mostrarProgreso = false,
  }) {
    _mensaje.value = mensaje;
    _mostrarProgreso.value = mostrarProgreso;
    _progreso.value = 0.0;
    _isLoading.value = true;

    Get.dialog(
      Obx(() => LoadingOverlay(
        mensaje: _mensaje.value,
        mostrarProgreso: _mostrarProgreso.value,
        progreso: _progreso.value,
      )),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
    );
  }

  void actualizarProgreso(double progreso, {String? nuevoMensaje}) {
    _progreso.value = progreso.clamp(0.0, 1.0);
    if (nuevoMensaje != null) {
      _mensaje.value = nuevoMensaje;
    }
  }

  void ocultarLoading() {
    _isLoading.value = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
