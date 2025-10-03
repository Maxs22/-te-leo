import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme_service.dart';

/// Widget que se reconstruye automáticamente cuando cambia el tema
/// Asegura que todos los widgets hijos se actualicen correctamente
class ThemeAwareWidget extends StatelessWidget {
  final Widget child;
  final bool forceUpdate;

  const ThemeAwareWidget({
    super.key,
    required this.child,
    this.forceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad
      
      // Forzar reconstrucción si es necesario
      if (forceUpdate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Trigger rebuild after frame
        });
      }
      
      return child;
    });
  }
}

/// Mixin para widgets que necesitan ser conscientes del tema
mixin ThemeAwareMixin<T extends StatefulWidget> on State<T> {
  ThemeService? _themeService;
  
  @override
  void initState() {
    super.initState();
    _themeService = Get.find<ThemeService>();
    _themeService?.addListener(_onThemeChanged);
  }
  
  @override
  void dispose() {
    _themeService?.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when theme changes
      });
    }
  }
  
  /// Obtiene el tema actual
  ThemeData get currentTheme => Get.theme;
  
  /// Obtiene el modo de tema actual
  ThemeMode get currentThemeMode => _themeService?.themeMode ?? ThemeMode.system;
  
  /// Verifica si el tema actual es oscuro
  bool get isDarkMode => _themeService?.isDarkMode ?? false;
}

/// Widget optimizado que evita reconstrucciones innecesarias
class OptimizedThemeWrapper extends StatelessWidget {
  final Widget child;
  final bool listenToThemeChanges;

  const OptimizedThemeWrapper({
    super.key,
    required this.child,
    this.listenToThemeChanges = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!listenToThemeChanges) {
      return child;
    }
    
    return Obx(() {
      // Solo acceder a la variable reactiva una vez
      final themeService = Get.find<ThemeService>();
      final _ = themeService.themeMode; // Esto activa la reactividad
      
      return child;
    });
  }
}

/// Widget mejorado que fuerza la reactividad completa del tema
class ForceThemeRebuild extends StatelessWidget {
  final Widget child;
  final bool forceRebuild;

  const ForceThemeRebuild({
    super.key,
    required this.child,
    this.forceRebuild = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a múltiples propiedades reactivas para asegurar actualización completa
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Modo de tema
      themeService.isDarkMode; // Estado de tema oscuro
      
      // Forzar reconstrucción si es necesario
      if (forceRebuild) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Trigger rebuild after frame
        });
      }
      
      return child;
    });
  }
}

/// Helper para obtener colores reactivos del tema
class ReactiveThemeColors {
  static Color get primary => Get.theme.colorScheme.primary;
  static Color get onPrimary => Get.theme.colorScheme.onPrimary;
  static Color get secondary => Get.theme.colorScheme.secondary;
  static Color get onSecondary => Get.theme.colorScheme.onSecondary;
  static Color get surface => Get.theme.colorScheme.surface;
  static Color get onSurface => Get.theme.colorScheme.onSurface;
  static Color get background => Get.theme.scaffoldBackgroundColor;
  static Color get error => Get.theme.colorScheme.error;
  static Color get onError => Get.theme.colorScheme.onError;
  
  /// Obtiene un color con opacidad reactivo al tema
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Obtiene un color primario con opacidad
  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }
  
  /// Obtiene un color de superficie con opacidad
  static Color surfaceWithOpacity(double opacity) {
    return surface.withOpacity(opacity);
  }
  
  /// Colores semánticos que se adaptan al tema (REACTIVO)
  static Color get success {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    }
  }
  
  static Color get warning {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFFFF9800) : const Color(0xFFE65100);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFFFF9800) : const Color(0xFFE65100);
    }
  }
  
  static Color get info {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFF2196F3) : const Color(0xFF1565C0);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFF2196F3) : const Color(0xFF1565C0);
    }
  }
  
  static Color get danger {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFFF44336) : const Color(0xFFC62828);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFFF44336) : const Color(0xFFC62828);
    }
  }
  
  /// Colores de estado premium que se adaptan al tema (REACTIVO)
  static Color get premium {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFFFFD700) : const Color(0xFFF57F17);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFFFFD700) : const Color(0xFFF57F17);
    }
  }
  
  static Color get premiumLight {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFFFFF59D) : const Color(0xFFFFF3C4);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFFFFF59D) : const Color(0xFFFFF3C4);
    }
  }
  
  /// Colores de desarrollo que se adaptan al tema (REACTIVO)
  static Color get debug {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF6A1B9A);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF6A1B9A);
    }
  }
  
  static Color get debugLight {
    try {
      final themeService = Get.find<ThemeService>();
      return themeService.isDarkMode ? const Color(0xFFE1BEE7) : const Color(0xFFF3E5F5);
    } catch (e) {
      return Get.isPlatformDarkMode ? const Color(0xFFE1BEE7) : const Color(0xFFF3E5F5);
    }
  }
}

/// Widget que proporciona colores reactivos a sus hijos
class ThemeColorProvider extends StatelessWidget {
  final Widget Function(ReactiveThemeColors colors) builder;

  const ThemeColorProvider({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad
      
      return builder(ReactiveThemeColors());
    });
  }
}

/// Widget helper para colores reactivos específicos
class ReactiveColor extends StatelessWidget {
  final Color Function() colorBuilder;
  final Widget child;

  const ReactiveColor({
    super.key,
    required this.colorBuilder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad
      
      return child;
    });
  }
}

/// Widget para iconos con colores reactivos
class ReactiveIcon extends StatelessWidget {
  final IconData icon;
  final Color Function()? colorBuilder;
  final double? size;

  const ReactiveIcon({
    super.key,
    required this.icon,
    this.colorBuilder,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad
      
      return Icon(
        icon,
        color: colorBuilder?.call() ?? Get.theme.colorScheme.onSurface,
        size: size,
      );
    });
  }
}
