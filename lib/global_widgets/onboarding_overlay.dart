import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/core/services/debug_console_service.dart';

/// Información de paso de onboarding
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final Widget? customWidget;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.customWidget,
  });
}

/// Overlay de onboarding para nuevos usuarios
class OnboardingOverlay extends StatefulWidget {
  final List<OnboardingStep> steps;
  final VoidCallback? onCompleted;
  final bool canSkip;

  const OnboardingOverlay({
    super.key,
    required this.steps,
    this.onCompleted,
    this.canSkip = true,
  });

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();

  /// Mostrar onboarding estático
  static void show({
    required List<OnboardingStep> steps,
    VoidCallback? onCompleted,
    bool canSkip = true,
  }) {
    Get.dialog(
      OnboardingOverlay(
        steps: steps,
        onCompleted: () {
          Get.back();
          onCompleted?.call();
        },
        canSkip: canSkip,
      ),
      barrierDismissible: false,
    );
  }

  /// Onboarding predefinido para Te Leo
  static void showDefaultOnboarding({VoidCallback? onCompleted}) {
    final steps = [
      OnboardingStep(
        title: 'onboarding_welcome_title'.tr,
        description: 'onboarding_welcome_desc'.tr,
        icon: Icons.visibility,
        color: Colors.blue,
      ),
      OnboardingStep(
        title: 'onboarding_scan_title'.tr,
        description: 'onboarding_scan_desc'.tr,
        icon: Icons.document_scanner,
        color: Colors.green,
      ),
      OnboardingStep(
        title: 'onboarding_listen_title'.tr,
        description: 'onboarding_listen_desc'.tr,
        icon: Icons.volume_up,
        color: Colors.orange,
      ),
      OnboardingStep(
        title: 'onboarding_library_title'.tr,
        description: 'onboarding_library_desc'.tr,
        icon: Icons.library_books,
        color: Colors.purple,
      ),
      OnboardingStep(
        title: 'onboarding_start_title'.tr,
        description: 'onboarding_start_desc'.tr,
        icon: Icons.rocket_launch,
        color: Colors.red,
      ),
    ];

    show(
      steps: steps,
      onCompleted: onCompleted,
      canSkip: true,
    );
  }
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    
    // Log después del build para evitar ciclos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLog.i('Onboarding started with ${widget.steps.length} steps', category: LogCategory.ui);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Header con botón de saltar
              if (widget.canSkip)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'onboarding_welcome_title'.tr,
                        style: Get.theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'skip'.tr,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contenido principal
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemCount: widget.steps.length,
                  itemBuilder: (context, index) {
                    return _buildStepContent(widget.steps[index]);
                  },
                ),
              ),

              // Indicadores de página
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.steps.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),

              // Botones de navegación
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    // Botón anterior
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('previous'.tr),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),

                    const SizedBox(width: 16),

                    // Botón siguiente/finalizar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLastStep ? _complete : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Get.theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLastStep ? 'start'.tr : 'next'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir contenido de un paso
  Widget _buildStepContent(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono animado
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: step.color?.withValues(alpha: 0.2) ?? 
                             Get.theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      step.icon,
                      size: 60,
                      color: step.color ?? Get.theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Título
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    step.title,
                    style: Get.theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Descripción
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  step.description,
                  style: Get.theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),

          // Widget personalizado si existe
          if (step.customWidget != null) ...[
            const SizedBox(height: 32),
            step.customWidget!,
          ],
        ],
      ),
    );
  }

  /// Construir indicador de página
  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  bool get _isLastStep => _currentStep == widget.steps.length - 1;

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    DebugLog.i('Onboarding skipped by user', category: LogCategory.ui);
    _complete();
  }

  void _complete() {
    DebugLog.i('Onboarding completed', category: LogCategory.ui);
    widget.onCompleted?.call();
  }
}
