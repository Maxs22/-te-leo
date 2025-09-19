import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/services/theme_service.dart';
import 'app/core/services/language_service.dart';
import 'app/core/services/user_preferences_service.dart';
import 'app/core/services/app_initialization_service.dart';
import 'app/core/translations/app_translations.dart';

/// Punto de entrada principal de la aplicación Te Leo
/// Configura la aplicación con GetX, temas accesibles y navegación
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios críticos antes de la app
  await _initializeCriticalServices();
  
  runApp(const TeLeoApp());
}

/// Inicializar servicios críticos antes de construir la app
Future<void> _initializeCriticalServices() async {
  try {
    // Inicializar UserPreferencesService
    final userPrefsService = UserPreferencesService();
    await userPrefsService.onInit();
    Get.put(userPrefsService, permanent: true);
    
    // Inicializar ThemeService
    final themeService = ThemeService();
    Get.put(themeService, permanent: true);
    await themeService.onInit();
    
    // Inicializar LanguageService
    final languageService = LanguageService();
    Get.put(languageService, permanent: true);
    await languageService.onInit();
    
    // Inicializar AppInitializationService para el resto
    final appInitService = AppInitializationService();
    Get.put(appInitService, permanent: true);
    
  } catch (e) {
    // Si hay error, continuar con valores por defecto
    print('Error initializing critical services: $e');
  }
}

/// Widget principal de la aplicación Te Leo
/// Herramienta de lectura accesible para jóvenes con problemas de vista y dislexia
class TeLeoApp extends StatelessWidget {
  const TeLeoApp({super.key});

  /// Determina la ruta inicial basada en si es la primera vez
  String _getInitialRoute() {
    try {
      final userPrefs = Get.find<UserPreferencesService>();
      final hasSeenOnboarding = userPrefs.hasSeenOnboarding;
      
      return hasSeenOnboarding ? AppRoutes.home : AppRoutes.welcome;
    } catch (e) {
      // Si no se puede determinar, mostrar onboarding por seguridad
      return AppRoutes.welcome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Obtener el ThemeService para escuchar cambios reactivos
      ThemeService? themeService;
      try {
        themeService = Get.find<ThemeService>();
      } catch (e) {
        // Si el servicio no está disponible, usar tema del sistema por defecto
        print('ThemeService not available, using system theme');
      }
      
      return GetMaterialApp(
        // Configuración básica de la aplicación
        title: 'Te Leo',
        debugShowCheckedModeBanner: false,
        
        // Configuración de temas accesibles (reactivos)
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeService?.themeMode ?? ThemeMode.system, // Ahora es reactivo
      
      // Configuración de navegación con GetX
      initialRoute: _getInitialRoute(),
      getPages: AppPages.routes,
      
      // Configuración de internacionalización
      translations: AppTranslations(),
      locale: const Locale('es', 'ES'), // Se establecerá dinámicamente por LanguageService
      fallbackLocale: const Locale('es', 'ES'),
      supportedLocales: LanguageService.supportedLocales,
      
      // Delegados de localización para widgets nativos
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
        // Configuración de accesibilidad
        builder: (context, child) {
          return MediaQuery(
            // Asegurar que el texto no se escale más allá de límites legibles
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.4),
              ),
            ),
            child: child!,
          );
        },
      );
    });
  }
}
