import 'package:flutter/material.dart';

import '../app/core/theme/accessible_colors.dart';
import '../app/core/widgets/global_theme_wrapper.dart';

/// Tarjeta moderna con diseño elegante y personalizable
class ModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final bool showShadow;
  final Border? border;
  final Gradient? gradient;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 2,
    this.onTap,
    this.showShadow = true,
    this.border,
    this.gradient,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 4,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: widget.margin ?? const EdgeInsets.all(8),
                  child: Material(
                    elevation: widget.showShadow ? _elevationAnimation.value : 0,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ?? theme.colorScheme.surface,
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border:
                            widget.border ??
                            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1), width: 0.5),
                      ),
                      child: InkWell(
                        onTap: widget.onTap,
                        onTapDown: (_) => _animationController.forward(),
                        onTapUp: (_) => _animationController.reverse(),
                        onTapCancel: () => _animationController.reverse(),
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: Container(padding: widget.padding ?? const EdgeInsets.all(16), child: widget.child),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tarjeta especializada para documentos
class DocumentCard extends StatelessWidget {
  final String titulo;
  final String resumen;
  final DateTime fechaModificacion;
  final bool esFavorito;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const DocumentCard({
    super.key,
    required this.titulo,
    required this.resumen,
    required this.fechaModificacion,
    this.esFavorito = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y botón de favorito
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AccessibleColors.getCardTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  esFavorito ? Icons.favorite : Icons.favorite_border,
                  color: esFavorito ? Colors.red : theme.colorScheme.outline,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Resumen del contenido
          Text(
            resumen,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AccessibleColors.getCardSecondaryTextColor(),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Footer con fecha y acciones
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                _formatearFecha(fechaModificacion),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AccessibleColors.getCardSecondaryTextColor(), // ✅ Color con contraste
                ),
              ),
              const Spacer(),

              // Botón de eliminar
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error.withValues(alpha: 0.7)),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      if (diferencia.inHours == 0) {
        if (diferencia.inMinutes == 0) {
          return 'Ahora';
        }
        return 'Hace ${diferencia.inMinutes} min';
      }
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}

/// Tarjeta de estadísticas
class StatsCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? color;
  final String? subtitulo;

  const StatsCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return ModernCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cardColor.withValues(alpha: 0.1), cardColor.withValues(alpha: 0.05)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: cardColor, size: 20),
              ),
              const Spacer(),
              Text(
                valor,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cardColor),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AccessibleColors.getCardTextColor(),
            ),
          ),

          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: theme.textTheme.bodySmall?.copyWith(color: AccessibleColors.getCardSecondaryTextColor()),
            ),
          ],
        ],
      ),
    );
  }
}
