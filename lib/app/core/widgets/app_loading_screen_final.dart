import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/app_bootstrap_service.dart';
import '../../../global_widgets/app_logo.dart';

/// Pantalla de carga final - diseño robusto y bien centrado
class AppLoadingScreenFinal extends StatelessWidget {
  const AppLoadingScreenFinal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Get.theme.colorScheme.surface,
              Get.theme.colorScheme.surfaceVariant,
              Get.theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              children: [
                // Espaciador superior
                const Spacer(flex: 3),
                
                // Logo de la aplicación
                const AppLogoSplash(size: 150),
                
                const SizedBox(height: 60),
                
                // Barra de progreso y estado
                GetX<AppBootstrapService>(
                  builder: (controller) {
                    return Column(
                      children: [
                        // Barra de progreso
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Get.theme.colorScheme.outline.withOpacity(0.3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: controller.initializationProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Get.theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Porcentaje
                        Text(
                          '${(controller.initializationProgress * 100).round()}%',
                          style: Get.theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Get.theme.colorScheme.onSurface,
                            fontSize: 24,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Estado actual con animación
                        AnimatedText(
                          text: controller.initializationStatus,
                          style: Get.theme.textTheme.bodyLarge?.copyWith(
                            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Indicador de carga
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Get.theme.colorScheme.primary,
                    ),
                    backgroundColor: Get.theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                
                const Spacer(), // Empuja todo hacia arriba
                
                // Versión de la aplicación
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Versión ${snapshot.data!.version}',
                        style: Get.theme.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    )
    );
  }
}

/// Widget para texto animado que va apareciendo letra por letra
class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final Duration duration;

  const AnimatedText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.duration = const Duration(milliseconds: 50),
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  String _displayText = '';
  int _currentIndex = 0;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  @override
  void didUpdateWidget(AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _currentIndex = 0;
      _displayText = '';
      _cancelAnimation();
      _animateText();
    }
  }

  @override
  void dispose() {
    _cancelAnimation();
    super.dispose();
  }

  void _cancelAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  void _animateText() {
    // Verificar si el widget sigue montado antes de llamar setState
    if (!mounted) return;
    
    if (_currentIndex < widget.text.length) {
      setState(() {
        _displayText += widget.text[_currentIndex];
        _currentIndex++;
      });
      
      // Solo continuar la animación si el widget sigue montado
      if (mounted) {
        _animationTimer = Timer(widget.duration, _animateText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
      textAlign: TextAlign.center,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}