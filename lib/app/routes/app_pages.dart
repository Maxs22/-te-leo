import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/welcome/welcome_binding.dart';
import '../modules/welcome/welcome_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_page_clean.dart';
import '../modules/library/library_binding.dart';
import '../modules/library/library_page.dart';
import '../modules/scan/scan_binding.dart';
import '../modules/scan/scan_page.dart';
import '../modules/settings/settings_binding.dart';
import '../modules/settings/settings_page.dart';
import '../modules/subscription/subscription_binding.dart';
import '../modules/subscription/subscription_page.dart';
import '../../global_widgets/simple_document_reader.dart';
import '../data/models/documento.dart';
import '../modules/translator/translator_binding.dart';
import '../modules/translator/translator_page.dart';

/// Configuración de páginas y rutas para GetX
/// Define todas las rutas disponibles en la aplicación y sus bindings correspondientes
class AppPages {
  /// Lista de todas las páginas de la aplicación
  static final List<GetPage> routes = [
    // Página de bienvenida
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomePage(),
      binding: WelcomeBinding(),
    ),
    
    // Página principal (Home)
    GetPage(
      name: AppRoutes.home,
      page: () => const CleanHomePage(),
      binding: HomeBinding(),
    ),
    
    // Página de biblioteca
    GetPage(
      name: AppRoutes.library,
      page: () => const LibraryPage(),
      binding: LibraryBinding(),
    ),
    
    // Página de escaneo de texto
    GetPage(
      name: AppRoutes.scanText,
      page: () => const ScanPage(),
      binding: ScanBinding(),
    ),
    
    // Página de configuraciones
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    
    // Página de suscripción premium
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionPage(),
      binding: SubscriptionBinding(),
    ),
    
    // Lector de documentos (para notificaciones)
    GetPage(
      name: AppRoutes.documentReader,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final documento = args['documento'] as Documento;
        final resumeFromProgress = args['resumeFromProgress'] as bool? ?? false;
        
        return SimpleDocumentReader(
          documento: documento,
          showControls: true,
          onClose: () => Get.back(),
          autoResumeFromNotification: resumeFromProgress,
        );
      },
    ),
    
    // Traductor OCR
    GetPage(
      name: AppRoutes.translator,
      page: () => const TranslatorPage(),
      binding: TranslatorBinding(),
    ),
  ];
  
  /// Ruta inicial de la aplicación
  static const String initial = AppRoutes.initial;
}
