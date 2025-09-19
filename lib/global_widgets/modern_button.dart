import 'package:flutter/material.dart';

/// Enumeración para los tipos de botón
enum ModernButtonType {
  primary,
  secondary,
  outlined,
  text,
  danger,
}

/// Botón moderno con múltiples estilos y animaciones
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? customColor;
  final Size? minimumSize;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.borderRadius,
    this.customColor,
    this.minimumSize,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton(context);

    if (widget.isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        );
      },
    );
  }

  Widget _buildButton(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (widget.type) {
      case ModernButtonType.primary:
        return _buildPrimaryButton(context, theme);
      case ModernButtonType.secondary:
        return _buildSecondaryButton(context, theme);
      case ModernButtonType.outlined:
        return _buildOutlinedButton(context, theme);
      case ModernButtonType.text:
        return _buildTextButton(context, theme);
      case ModernButtonType.danger:
        return _buildDangerButton(context, theme);
    }
  }

  Widget _buildPrimaryButton(BuildContext context, ThemeData theme) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.customColor ?? theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: widget.minimumSize ?? const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        ),
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
      ),
      child: _buildButtonContent(theme.colorScheme.onPrimary),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, ThemeData theme) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.customColor ?? theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: widget.minimumSize ?? const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        ),
        elevation: 1,
      ),
      child: _buildButtonContent(theme.colorScheme.onSecondary),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, ThemeData theme) {
    final color = widget.customColor ?? theme.colorScheme.primary;
    return OutlinedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: widget.minimumSize ?? const Size(88, 48),
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        ),
      ),
      child: _buildButtonContent(color),
    );
  }

  Widget _buildTextButton(BuildContext context, ThemeData theme) {
    final color = widget.customColor ?? theme.colorScheme.primary;
    return TextButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: widget.minimumSize ?? const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        ),
      ),
      child: _buildButtonContent(color),
    );
  }

  Widget _buildDangerButton(BuildContext context, ThemeData theme) {
    final dangerColor = widget.customColor ?? theme.colorScheme.error;
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: dangerColor,
        foregroundColor: theme.colorScheme.onError,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: widget.minimumSize ?? const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        ),
        elevation: 2,
      ),
      child: _buildButtonContent(theme.colorScheme.onError),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  void _handlePress() {
    if (widget.onPressed != null) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      widget.onPressed!();
    }
  }
}

/// Extension para crear botones modernos fácilmente
extension ModernButtonExtension on Widget {
  Widget withModernButton({
    required String text,
    required VoidCallback onPressed,
    ModernButtonType type = ModernButtonType.primary,
    IconData? icon,
    bool isLoading = false,
  }) {
    return ModernButton(
      text: text,
      onPressed: onPressed,
      type: type,
      icon: icon,
      isLoading: isLoading,
    );
  }
}
