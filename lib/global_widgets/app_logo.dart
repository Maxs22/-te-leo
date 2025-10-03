import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar el logo de Te Leo
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final bool showText;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo principal
          Image.asset(
            'assets/images/te-leo.png',
            width: width,
            height: height != null ? height! * 0.8 : null,
            fit: fit,
            color: color,
            errorBuilder: (context, error, stackTrace) {
              // Fallback si no se encuentra la imagen
              return Container(
                width: width ?? 100,
                height: height ?? 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'IT',
                    style: TextStyle(
                      fontSize: (width ?? 100) * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Texto del logo (opcional)
          if (showText && height != null && height! > 80)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'TE LEO',
                style: TextStyle(
                  fontSize: (height ?? 100) * 0.15,
                  fontWeight: FontWeight.w600,
                  color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget de logo compacto para headers
class AppLogoCompact extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogoCompact({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/te-leo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'IT',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget de logo para splash screen
class AppLogoSplash extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final bool showSubtitle;

  const AppLogoSplash({
    super.key,
    this.size = 200,
    this.backgroundColor,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo principal (solo imagen, sin texto)
        Image.asset(
          'assets/images/te-leo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  'IT',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
        
        if (showSubtitle) ...[
          const SizedBox(height: 24),
          
          // Subtítulo
          Text(
            'Lectura Accesible',
            style: TextStyle(
              fontSize: size * 0.1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget de logo solo (sin texto)
class AppLogoOnly extends StatelessWidget {
  final double size;
  final Color? color;
  final BoxFit fit;

  const AppLogoOnly({
    super.key,
    this.size = 100,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/te-leo.png',
      width: size,
      height: size,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              'IT',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
