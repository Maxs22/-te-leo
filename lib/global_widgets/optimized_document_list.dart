import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/data/models/documento.dart';

/// Lista optimizada de documentos con lazy loading y cache
class OptimizedDocumentList extends StatelessWidget {
  final List<Documento> documentos;
  final Function(Documento)? onDocumentTap;
  final Function(Documento)? onFavoriteToggle;
  final Function(Documento)? onDelete;
  final Function(Documento)? onShare;
  final bool enableAnimations;
  final EdgeInsets? padding;

  const OptimizedDocumentList({
    super.key,
    required this.documentos,
    this.onDocumentTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.onShare,
    this.enableAnimations = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (documentos.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: documentos.length,
      // Optimizaciones de rendimiento
      itemExtent: 120, // Altura fija para mejor rendimiento
      cacheExtent: 1000, // Cache más elementos fuera de pantalla
      physics: const BouncingScrollPhysics(), // Física más fluida
      itemBuilder: (context, index) {
        final documento = documentos[index];
        
        // Widget optimizado con AnimatedContainer para transiciones suaves
        return OptimizedDocumentCard(
          documento: documento,
          index: index,
          onTap: onDocumentTap != null ? () => onDocumentTap!(documento) : null,
          onFavoriteToggle: onFavoriteToggle != null ? () => onFavoriteToggle!(documento) : null,
          onDelete: onDelete != null ? () => onDelete!(documento) : null,
          onShare: onShare != null ? () => onShare!(documento) : null,
          enableAnimations: enableAnimations,
        );
      },
    );
  }
}

/// Tarjeta de documento optimizada con cache y animaciones eficientes
class OptimizedDocumentCard extends StatefulWidget {
  final Documento documento;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool enableAnimations;

  const OptimizedDocumentCard({
    super.key,
    required this.documento,
    required this.index,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.onShare,
    this.enableAnimations = true,
  });

  @override
  State<OptimizedDocumentCard> createState() => _OptimizedDocumentCardState();
}

class _OptimizedDocumentCardState extends State<OptimizedDocumentCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Cache del resumen formateado
  String? _cachedSummary;
  String? _cachedDateString;

  @override
  bool get wantKeepAlive => true; // Mantener estado para mejor rendimiento

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _prepareCache();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Configura animaciones eficientes
  void _setupAnimations() {
    if (!widget.enableAnimations) return;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50).clamp(0, 500)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Animar entrada con delay basado en el índice
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  /// Prepara cache de datos formateados
  void _prepareCache() {
    // Cache del resumen
    _cachedSummary = widget.documento.resumen;
    
    // Cache de la fecha formateada
    _cachedDateString = _formatearFecha(widget.documento.fechaModificacion);
  }

  /// Formatea fecha de manera eficiente
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    
    Widget card = _buildCard();
    
    // Aplicar animaciones solo si están habilitadas
    if (widget.enableAnimations && _animationController.isCompleted == false) {
      card = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: card,
      );
    }
    
    return card;
  }

  /// Construye la tarjeta optimizada
  Widget _buildCard() {
    final theme = Get.theme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header optimizado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.documento.titulo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Botón de favorito optimizado
                    _buildFavoriteButton(theme),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Resumen optimizado con cache
                Text(
                  _cachedSummary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Footer optimizado
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _cachedDateString!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    
                    // Botones de acción optimizados
                    _buildActionButtons(theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye botón de favorito optimizado
  Widget _buildFavoriteButton(ThemeData theme) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onFavoriteToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            widget.documento.esFavorito ? Icons.favorite : Icons.favorite_border,
            color: widget.documento.esFavorito 
                ? Colors.red 
                : theme.colorScheme.outline,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Construye botones de acción optimizados
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onShare != null)
          _buildActionButton(
            icon: Icons.share,
            onTap: widget.onShare!,
            color: theme.colorScheme.outline,
          ),
        
        if (widget.onDelete != null) ...[
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.delete_outline,
            onTap: widget.onDelete!,
            color: theme.colorScheme.error.withValues(alpha: 0.7),
          ),
        ],
      ],
    );
  }

  /// Construye un botón de acción individual
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}
