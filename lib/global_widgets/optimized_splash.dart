import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../app/core/services/app_initialization_service.dart';
import '../app/core/services/access_validation_service.dart';
import '../app/core/services/debug_console_service.dart';

/// Splash screen optimizado con inicialización asíncrona
class OptimizedSplash extends StatelessWidget {
  final Widget child;
  final Duration minimumDuration;
  final bool showProgress;

  const OptimizedSplash({
    super.key,
    required this.child,
    this.minimumDuration = const Duration(milliseconds: 1500),
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OptimizedSplashController>(
      init: OptimizedSplashController(
        targetWidget: child,
        minimumDuration: minimumDuration,
      ),
      builder: (controller) {
        return Obx(() {
          if (controller.isReady.value) {
            return child;
          }
          
          return _buildSplashScreen(controller);
        });
      },
    );
  }

  /// Construye la pantalla de splash
  Widget _buildSplashScreen(OptimizedSplashController controller) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.primary,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Título de la app
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Text(
                      'Te Leo',
                      style: Get.theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Subtítulo
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'Tu herramienta de lectura accesible',
                    style: Get.theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 64),
            
             // Indicador de progreso
             if (showProgress) ...[
               SizedBox(
                 width: 200,
                 child: Obx(() {
                   // Mostrar progreso de validación de acceso si no está granted
                   if (!controller.accessGranted.value) {
                     return Column(
                       children: [
                         const CircularProgressIndicator(
                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                         ),
                         const SizedBox(height: 16),
                         Text(
                           controller.currentStep.value,
                           style: Get.theme.textTheme.bodySmall?.copyWith(
                             color: Colors.white.withValues(alpha: 0.9),
                           ),
                           textAlign: TextAlign.center,
                         ),
                         const SizedBox(height: 8),
                         Text(
                           controller.accessService.message,
                           style: Get.theme.textTheme.bodySmall?.copyWith(
                             color: Colors.white.withValues(alpha: 0.7),
                             fontSize: 12,
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     );
                   }
                   
                   // Mostrar progreso normal de inicialización
                   return Column(
                     children: [
                       LinearProgressIndicator(
                         value: controller.initService.progress,
                         backgroundColor: Colors.white.withValues(alpha: 0.3),
                         valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                       ),
                       const SizedBox(height: 12),
                       Text(
                         controller.currentStep.value,
                         style: Get.theme.textTheme.bodySmall?.copyWith(
                           color: Colors.white.withValues(alpha: 0.9),
                         ),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 4),
                       Text(
                         controller.initService.statusMessage,
                         style: Get.theme.textTheme.bodySmall?.copyWith(
                           color: Colors.white.withValues(alpha: 0.7),
                           fontSize: 12,
                         ),
                         textAlign: TextAlign.center,
                       ),
                     ],
                   );
                 }),
               ),
             ] else ...[
               Obx(() => Column(
                 children: [
                   const CircularProgressIndicator(
                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     controller.currentStep.value,
                     style: Get.theme.textTheme.bodySmall?.copyWith(
                       color: Colors.white.withValues(alpha: 0.8),
                     ),
                     textAlign: TextAlign.center,
                   ),
                 ],
               )),
             ],
            
            const SizedBox(height: 32),
            
            // Versión (solo en debug)
            if (kDebugMode)
              Text(
                'v1.0.0 (Debug)',
                style: Get.theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Controlador para el splash screen optimizado
class OptimizedSplashController extends GetxController {
  final Widget targetWidget;
  final Duration minimumDuration;
  
  late AppInitializationService initService;
  late AccessValidationService accessService;
  
  final RxBool isReady = false.obs;
  final RxBool accessGranted = false.obs;
  final RxString currentStep = 'Iniciando...'.obs;
  DateTime? _startTime;

  OptimizedSplashController({
    required this.targetWidget,
    required this.minimumDuration,
  });

  @override
  void onInit() {
    super.onInit();
    _startTime = DateTime.now();
    _initializeApp();
  }

  /// Inicializa la aplicación
  Future<void> _initializeApp() async {
    try {
      currentStep.value = 'Validando acceso...';
      
      // 1. Inicializar y validar acceso
      accessService = Get.put(AccessValidationService(), permanent: true);
      
      // Configurar validaciones según el entorno
      accessService.configure(
        enableDeviceValidation: !kDebugMode, // Solo en release
        enableLicenseValidation: true,
        enableSecurityValidation: !kDebugMode, // Solo en release
        enableMaintenanceCheck: false, // Activar cuando sea necesario
        validationTimeout: const Duration(seconds: 15),
      );
      
      final accessResult = await accessService.validateAccess();
      
      if (!accessResult.isGranted) {
        // Mostrar dialog de acceso denegado
        accessService.showAccessDeniedDialog(accessResult);
        return; // No continuar con la inicialización
      }
      
      accessGranted.value = true;
      currentStep.value = 'Inicializando servicios...';
      
      // 2. Registrar e inicializar servicios de la app
      initService = Get.put(AppInitializationService(), permanent: true);
      
      // 3. Esperar a que termine la inicialización
      await _waitForInitialization();
      
      // 4. Asegurar duración mínima del splash
      await _ensureMinimumDuration();
      
      // 5. Marcar como listo
      currentStep.value = 'Completado';
      isReady.value = true;
      
      DebugLog.i('Splash screen completed, showing main app - Access granted: ${accessGranted.value}', 
                 category: LogCategory.app);
      
    } catch (e) {
      DebugLog.e('Error in splash initialization: $e', category: LogCategory.app);
      
      // En caso de error, mostrar dialog de error
      _showInitializationError(e.toString());
    }
  }

  /// Espera a que termine la inicialización
  Future<void> _waitForInitialization() async {
    while (initService.state == InitializationState.initializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Asegura que el splash se muestre por el tiempo mínimo
  Future<void> _ensureMinimumDuration() async {
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!);
      final remaining = minimumDuration - elapsed;
      
      if (remaining.inMilliseconds > 0) {
        DebugLog.d('Waiting ${remaining.inMilliseconds}ms to meet minimum splash duration', 
                   category: LogCategory.ui);
        await Future.delayed(remaining);
      }
    }
  }

  /// Mostrar error de inicialización
  void _showInitializationError(String error) {
    currentStep.value = 'Error en inicialización';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Error de Inicialización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo inicializar Te Leo correctamente.\n\n'
              'Error: $error',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _initializeApp(); // Reintentar
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
