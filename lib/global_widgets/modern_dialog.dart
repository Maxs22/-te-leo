import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Diálogo moderno con diseño elegante y animaciones suaves
class ModernDialog extends StatelessWidget {
  final String? titulo;
  final String? contenido;
  final Widget? contenidoWidget;
  final String? textoBotonPrimario;
  final String? textoBotonSecundario;
  final VoidCallback? onBotonPrimario;
  final VoidCallback? onBotonSecundario;
  final IconData? icono;
  final Color? colorIcono;
  final bool barrierDismissible;
  final EdgeInsetsGeometry? padding;

  const ModernDialog({
    super.key,
    this.titulo,
    this.contenido,
    this.contenidoWidget,
    this.textoBotonPrimario,
    this.textoBotonSecundario,
    this.onBotonPrimario,
    this.onBotonSecundario,
    this.icono,
    this.colorIcono,
    this.barrierDismissible = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: padding ?? const EdgeInsets.all(24),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    // Icono si se proporciona
                    if (icono != null) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (colorIcono ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          icono,
                          size: 30,
                          color: colorIcono ?? Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Título
                    if (titulo != null) ...[
                      Text(
                        titulo!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Contenido
                    if (contenido != null) ...[
                      Text(
                        contenido!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Widget personalizado
                    if (contenidoWidget != null) ...[
                      contenidoWidget!,
                      const SizedBox(height: 24),
                    ],

                    // Botones
                    if (textoBotonPrimario != null || textoBotonSecundario != null)
                      Row(
                        children: [
                          // Botón secundario
                          if (textoBotonSecundario != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onBotonSecundario ?? () => Get.back(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(textoBotonSecundario!),
                              ),
                            ),
                            if (textoBotonPrimario != null) const SizedBox(width: 12),
                          ],

                          // Botón primario
                          if (textoBotonPrimario != null)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onBotonPrimario ?? () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(textoBotonPrimario!),
                              ),
                            ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación
  static Future<bool> mostrarConfirmacion({
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Confirmar',
    String textoCancelar = 'Cancelar',
    IconData? icono,
    Color? colorIcono,
  }) async {
    final resultado = await Get.dialog<bool>(
      ModernDialog(
        titulo: titulo,
        contenido: mensaje,
        textoBotonPrimario: textoConfirmar,
        textoBotonSecundario: textoCancelar,
        icono: icono,
        colorIcono: colorIcono,
        onBotonPrimario: () => Get.back(result: true),
        onBotonSecundario: () => Get.back(result: false),
      ),
      barrierDismissible: false,
    );
    return resultado ?? false;
  }

  /// Muestra un diálogo de información
  static Future<void> mostrarInformacion({
    required String titulo,
    required String mensaje,
    String textoBoton = 'Entendido',
    IconData? icono,
    Color? colorIcono,
    EdgeInsetsGeometry? padding,
  }) async {
    await Get.dialog(
      ModernDialog(
        titulo: titulo,
        contenido: mensaje,
        textoBotonPrimario: textoBoton,
        icono: icono,
        colorIcono: colorIcono,
        padding: padding,
      ),
    );
  }

  /// Muestra un diálogo de error
  static Future<void> mostrarError({
    String titulo = 'Error',
    required String mensaje,
    String textoBoton = 'Cerrar',
  }) async {
    await Get.dialog(
      ModernDialog(
        titulo: titulo,
        contenido: mensaje,
        textoBotonPrimario: textoBoton,
        icono: Icons.error_outline,
        colorIcono: Get.theme.colorScheme.error,
      ),
    );
  }

  /// Muestra un diálogo de éxito
  static Future<void> mostrarExito({
    String titulo = 'Éxito',
    required String mensaje,
    String textoBoton = 'Continuar',
  }) async {
    await Get.dialog(
      ModernDialog(
        titulo: titulo,
        contenido: mensaje,
        textoBotonPrimario: textoBoton,
        icono: Icons.check_circle_outline,
        colorIcono: Colors.green,
      ),
    );
  }

  /// Muestra un diálogo personalizado
  static Future<T?> mostrarPersonalizado<T>({
    String? titulo,
    Widget? contenido,
    List<Widget>? acciones,
    bool barrierDismissible = true,
  }) async {
    return await Get.dialog<T>(
      ModernDialog(
        titulo: titulo,
        contenidoWidget: contenido,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}
