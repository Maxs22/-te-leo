import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:te_leo/app/core/config/app_config.dart';
import 'package:te_leo/app/core/services/app_bootstrap_service.dart';
import 'package:te_leo/app/core/services/environment_service.dart';
import 'package:te_leo/app/core/widgets/app_loading_screen_final.dart';
import 'package:te_leo/global_widgets/ads/app_open_ad_manager.dart';

import 'app/core/services/language_service.dart';
import 'app/core/services/route_service.dart';
import 'app/core/services/theme_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/translations/app_translations.dart';
import 'app/core/widgets/global_theme_wrapper.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

/// Punto de entrada principal de la aplicación Te Leo
/// Configura la aplicación con GetX, temas accesibles y navegación
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar GetStorage (reemplaza SharedPreferences)
  await GetStorage.init();

  // Inicializar variables de entorno
  await EnvironmentService.initialize();

  // Imprimir información de configuración (solo en desarrollo)
  AppConfig.printConfigInfo();

  runApp(const TeLeoApp());
}

/// Widget principal de la aplicación Te Leo
/// Herramienta de lectura accesible para jóvenes con problemas de vista y dislexia
class TeLeoApp extends StatefulWidget {
  const TeLeoApp({super.key});

  @override
  State<TeLeoApp> createState() => _TeLeoAppState();
}

class _TeLeoAppState extends State<TeLeoApp> with WidgetsBindingObserver {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // NO mostrar App Open ad en el arranque inicial para mejor UX
    // Solo se mostrará cuando el usuario vuelva a la app desde el background (onAppResumed)
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Mostrar App Open ad solo al volver del background, no en el cold start
        _appOpenAdManager.onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _appOpenAdManager.onAppPaused();
        break;
      case AppLifecycleState.detached:
        // La app se está cerrando
        break;
      case AppLifecycleState.hidden:
        _appOpenAdManager.onAppPaused();
        break;
    }
  }

  /// Obtiene la ruta inicial usando el RouteService
  String _getInitialRoute() {
    try {
      if (Get.isRegistered<RouteService>()) {
        return Get.find<RouteService>().getInitialRoute();
      }
      // Fallback si el RouteService no está disponible
      return AppRoutes.welcome;
    } catch (e) {
      // Si hay error, mostrar onboarding por seguridad
      return AppRoutes.welcome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AppBootstrapService>(
      init: AppBootstrapService(),
      initState: (state) {
        state.controller?.initializeApp();
      },
      builder: (bootstrapService) {
        // Si no está inicializado, mostrar pantalla de carga
        if (!bootstrapService.isInitialized) {
          return const MaterialApp(title: 'Te Leo', debugShowCheckedModeBanner: false, home: AppLoadingScreenFinal());
        }

        // Aplicación completamente inicializada
        return GlobalThemeWrapper(
          child: GetBuilder<ThemeService>(
            builder: (themeService) {
              return GetMaterialApp(
                // Configuración básica de la aplicación
                title: 'Te Leo',
                debugShowCheckedModeBanner: false,

                // Configuración de temas accesibles (reactivos)
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeService.themeMode,

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
                      textScaler: TextScaler.linear(MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.4)),
                    ),
                    child: child!,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
