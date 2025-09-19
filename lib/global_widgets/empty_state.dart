import 'package:flutter/material.dart';
import 'modern_button.dart';

/// Widget para mostrar estados vacíos de manera elegante y moderna
class EmptyState extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String? textoBoton;
  final VoidCallback? onBotonPressed;
  final Color? colorIcono;
  final Widget? widgetPersonalizado;
  final bool mostrarAnimacion;

  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.textoBoton,
    this.onBotonPressed,
    this.colorIcono,
    this.widgetPersonalizado,
    this.mostrarAnimacion = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado
            if (mostrarAnimacion)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildIcon(theme),
              )
            else
              _buildIcon(theme),
            
            const SizedBox(height: 32),
            
            // Título
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Text(
                titulo,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Descripción
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Text(
                descripcion,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Widget personalizado
            if (widgetPersonalizado != null) ...[
              const SizedBox(height: 24),
              widgetPersonalizado!,
            ],
            
            // Botón de acción
            if (textoBoton != null && onBotonPressed != null) ...[
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: ModernButton(
                  text: textoBoton!,
                  onPressed: onBotonPressed,
                  type: ModernButtonType.primary,
                  icon: Icons.add,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: (colorIcono ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(60),
      ),
      child: Icon(
        icono,
        size: 60,
        color: (colorIcono ?? theme.colorScheme.primary).withValues(alpha: 0.6),
      ),
    );
  }
}

/// Estados vacíos predefinidos para la aplicación Te Leo
class TeLeoEmptyStates {
  /// Estado vacío para biblioteca sin documentos
  static Widget bibliotecaVacia({VoidCallback? onEscanear}) {
    return EmptyState(
      icono: Icons.library_books_outlined,
      titulo: 'Tu biblioteca está vacía',
      descripcion: 'Comienza escaneando texto para crear tu primera colección de documentos accesibles',
      textoBoton: 'Escanear Texto',
      onBotonPressed: onEscanear,
    );
  }

  /// Estado vacío para búsquedas sin resultados
  static Widget busquedaSinResultados(String termino) {
    return EmptyState(
      icono: Icons.search_off,
      titulo: 'Sin resultados',
      descripcion: 'No se encontraron documentos que coincidan con "$termino".\nIntenta con otros términos de búsqueda.',
      colorIcono: Colors.orange,
      mostrarAnimacion: false,
    );
  }

  /// Estado vacío para favoritos
  static Widget favoritosVacios() {
    return const EmptyState(
      icono: Icons.favorite_border,
      titulo: 'No tienes favoritos',
      descripcion: 'Marca documentos como favoritos para acceder a ellos rápidamente desde aquí.',
      colorIcono: Colors.red,
    );
  }

  /// Estado de error de conexión
  static Widget errorConexion({VoidCallback? onReintentar}) {
    return EmptyState(
      icono: Icons.wifi_off,
      titulo: 'Sin conexión',
      descripcion: 'Verifica tu conexión a internet e inténtalo nuevamente.',
      textoBoton: 'Reintentar',
      onBotonPressed: onReintentar,
      colorIcono: Colors.red,
    );
  }

  /// Estado de error general
  static Widget error({
    required String mensaje,
    VoidCallback? onReintentar,
  }) {
    return EmptyState(
      icono: Icons.error_outline,
      titulo: 'Algo salió mal',
      descripcion: mensaje,
      textoBoton: onReintentar != null ? 'Reintentar' : null,
      onBotonPressed: onReintentar,
      colorIcono: Colors.red,
    );
  }

  /// Estado de carga inicial
  static Widget cargandoDatos() {
    return const EmptyState(
      icono: Icons.hourglass_empty,
      titulo: 'Cargando...',
      descripcion: 'Preparando tus documentos',
      mostrarAnimacion: true,
      widgetPersonalizado:  Padding(
        padding: EdgeInsets.only(top: 16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Estado para cuando se necesitan permisos
  static Widget permisosDenegados({
    required String mensaje,
    VoidCallback? onSolicitarPermisos,
  }) {
    return EmptyState(
      icono: Icons.lock_outline,
      titulo: 'Permisos necesarios',
      descripcion: mensaje,
      textoBoton: 'Otorgar permisos',
      onBotonPressed: onSolicitarPermisos,
      colorIcono: Colors.orange,
    );
  }
}
