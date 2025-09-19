import 'package:get/get.dart';

/// Traducciones de la aplicación Te Leo
/// Soporte para español e inglés
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es_ES': {
      // Aplicación general
      'app_name': 'Te Leo',
      'app_description': 'Tu herramienta de lectura accesible',
      'app_tagline': 'Convierte cualquier texto en audio',
      'home_title': 'Te Leo',
      'welcome_back': 'Bienvenido de vuelta',
      'statistics_title': 'Tus estadísticas de lectura',
      'documents_scanned': 'Documentos',
      'minutes_listened': 'Minutos',
      'consecutive_days': 'Días',
      'scan_text': 'Escanear texto',
      'my_library': 'Biblioteca',
      'scan_info': 'Toma una foto de cualquier texto y Te Leo lo leerá en voz alta',
      
      // Onboarding steps
      'onboarding_step1_title': '📸 Escanea cualquier texto',
      'onboarding_step1_description': 'Toma una foto de libros, documentos, carteles o cualquier texto que quieras escuchar',
      'onboarding_step2_title': '🎧 Escucha con voz natural',
      'onboarding_step2_description': 'Te Leo convierte el texto en audio con voces naturales y configurables',
      'onboarding_step3_title': '📚 Guarda en tu biblioteca',
      'onboarding_step3_description': 'Todos tus documentos se guardan automáticamente para acceder cuando quieras',
      'onboarding_step4_title': '🌐 Traduce al instante',
      'onboarding_step4_description': 'Traduce cualquier texto entre español e inglés con solo una foto',
      'onboarding_step5_title': '♿ Diseño accesible',
      'onboarding_step5_description': 'Optimizado para personas con baja visión y dislexia con colores y tipografía especiales',
      
      // Settings
      'settings_title': 'Configuraciones',
      'general': 'General',
      'theme': 'Tema',
      'language': 'Idioma',
      'theme_system': 'Sistema',
      'theme_light': 'Claro',
      'theme_dark': 'Oscuro',
      'language_spanish': 'Español',
      'language_english': 'English',
      'reading_reminders': 'Recordatorios de lectura',
      'enable_reading_reminders': 'Activar recordatorios',
      'reminder_interval': 'Intervalo de recordatorio',
      'send_test_notification': 'Enviar notificación de prueba',
      'reminder_interval_hours': 'horas',
      'voice_settings': 'Configuración de voz',
      'test_voice': 'Probar voz',
      'voice_profile': 'Perfil de voz',
      'advanced_voice_settings': 'Configuración avanzada de voz',
      'voice_speed': 'Velocidad de voz',
      'voice_pitch': 'Tono de voz',
      'voice_volume': 'Volumen de voz',
      
      // Traductor OCR
      'translator_title': '📸 Traductor',
      'taking_photo': 'Tomando foto...',
      'photo_cancelled': 'Foto cancelada',
      'selecting_image': 'Seleccionando imagen...',
      'image_selection_cancelled': 'Selección cancelada',
      'extracting_text': 'Extrayendo texto...',
      'no_text_detected': 'No se detectó texto en la imagen',
      'translating_text': 'Traduciendo...',
      'translation_completed': 'Traducción completada',
      'translation_failed': 'Error en la traducción',
      'translation_saved': 'Traducción guardada',
      'document_saved_successfully': 'Documento guardado exitosamente',
      'translation_error': 'Error de traducción',
      'translator_welcome_title': 'Traductor OCR',
      'translator_welcome_subtitle': 'Toma una foto y traduce el texto al instante',
      'take_photo': 'Tomar foto',
      'select_from_gallery': 'Seleccionar de galería',
      'original_text': 'Texto original',
      'detected_language': 'Idioma detectado: {{language}}',
      'translated_text': 'Texto traducido',
      'confidence': 'Confianza: {{confidence}}',
      'try_again': 'Intentar de nuevo',
      'play_text': 'Reproducir texto',
      'target_language': 'Idioma de destino',
      'save_translation': 'Guardar traducción',
      'translation_history': 'Historial de traducciones',
      'no_translation_history': 'No hay traducciones guardadas',
      'exit_app_title': 'Salir de la aplicación',
      'exit_app_message': '¿Estás seguro de que quieres salir?',
      'exit': 'Salir',
      'update_available': 'Actualización disponible',
      'settings': 'Configuraciones',
      
      // Navegación y botones generales
      'continue': 'Continuar',
      'cancel': 'Cancelar',
      'accept': 'Aceptar',
      'close': 'Cerrar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'back': 'Atrás',
      'next': 'Siguiente',
      'previous': 'Anterior',
      'finish': 'Finalizar',
      'start': 'Comenzar',
      'skip': 'Saltar',
      'retry': 'Reintentar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'warning': 'Advertencia',
      'info': 'Información',
      
      // Pantalla de bienvenida
      'good_morning': 'Buenos días',
      'good_afternoon': 'Buenas tardes',
      'good_evening': 'Buenas noches',
      'ready_to_read': 'Listo para una nueva experiencia de lectura',
      'lets_continue': 'Continuemos donde lo dejaste',
      'enter': 'Ingresar',
      'listening_time': 'Tiempo\nEscuchado',
      'premium': 'Premium',
      'version': 'Versión',
    
      
      // Onboarding
      'onboarding_welcome_title': 'Bienvenido a Te Leo',
      'onboarding_welcome_desc': 'Tu herramienta de lectura accesible que convierte cualquier texto en una experiencia auditiva.',
      'onboarding_scan_title': 'Escanea Cualquier Texto',
      'onboarding_scan_desc': 'Usa la cámara para capturar texto de libros, documentos o cualquier superficie.',
      'onboarding_listen_title': 'Escucha con Claridad',
      'onboarding_listen_desc': 'Convierte el texto en audio natural con voces de alta calidad y controles avanzados.',
      'onboarding_library_title': 'Organiza tu Biblioteca',
      'onboarding_library_desc': 'Guarda y organiza todos tus documentos para acceder fácilmente cuando los necesites.',
      'onboarding_start_title': '¡Comienza a Leer!',
      'onboarding_start_desc': 'Todo está listo. Comienza tu experiencia de lectura accesible con Te Leo.',
      
      // Biblioteca
      'library_title': 'Mi Biblioteca',
      'library_empty_title': 'Tu biblioteca está vacía',
      'library_empty_desc': 'Comienza escaneando tu primer documento',
      'scan_first_document': 'Escanear primer documento',
      'no_documents_found': 'No se encontraron documentos',
      
      // Escaneo
      'scan_title': 'Escanear Texto',

      'processing_image': 'Procesando imagen...',
      'text_recognized': 'Texto reconocido',
      'no_text_found': 'No se encontró texto en la imagen',
      'save_document': 'Guardar documento',
      
      // Configuraciones

      'user_name': 'Nombre de usuario',
      'audio': 'Audio',
      'tts_voice': 'Voz',
      'tts_speed': 'Velocidad',
      'reading': 'Lectura',
      'auto_save_progress': 'Guardar progreso automáticamente',
      'highlight_words': 'Resaltar palabras',
      'premium_features': 'Funciones Premium',
      'about': 'Acerca de',
      'version_info': 'Información de versión',
      'debug': 'Debug',
      'debug_console': 'Consola de debug',
      

      // TTS y reproducción
      'play': 'Reproducir',
      'pause': 'Pausar',
      'stop': 'Detener',
      'resume': 'Reanudar',
      'restart': 'Reiniciar',
      'speed': 'Velocidad',
      'voice': 'Voz',
      
      // Progreso de lectura
      'resume_reading': 'Reanudar lectura',
      'restart_reading': 'Reiniciar lectura',
      'reading_progress': 'Progreso de lectura',
      'resume_from_position': 'Reanudar desde donde lo dejaste',
      'start_from_beginning': 'Comenzar desde el principio',
      
      // Errores y mensajes
      'error_camera_permission': 'Se requiere permiso de cámara',
      'error_storage_permission': 'Se requiere permiso de almacenamiento',
      'error_no_camera': 'No hay cámara disponible',
      'error_processing_image': 'Error procesando la imagen',
      'error_saving_document': 'Error guardando el documento',
      'error_loading_document': 'Error cargando el documento',
      'error_tts_not_available': 'Síntesis de voz no disponible',
      'document_saved': 'Documento guardado',
      'document_deleted': 'Documento eliminado',
      
      // Diálogos de confirmación
      'delete_document_title': 'Eliminar documento',
      'delete_document_message': '¿Estás seguro de que quieres eliminar este documento?',
      
      // Premium y suscripciones
      'premium_title': 'Te Leo Premium',
      'premium_description': 'Desbloquea todas las funciones',
      'premium_features_list': 'Acceso ilimitado a todas las voces\nVelocidad de reproducción avanzada\nSin límite de documentos\nSoporte prioritario',
      'upgrade_to_premium': 'Actualizar a Premium',
      'demo_mode': 'Modo Demo',
      'demo_expires_in': 'El demo expira en',
      'days': 'días',
    },
    
    'en_US': {
      // Application general
      'app_name': 'Te Leo',
      'app_description': 'Your accessible reading tool',
      'app_tagline': 'Convert any text to audio',
      'home_title': 'Te Leo',
      'welcome_back': 'Welcome back',
      'statistics_title': 'Your reading stats',
      'documents_scanned': 'Documents',
      'minutes_listened': 'Minutes',
      'consecutive_days': 'Days',
      'scan_text': 'Scan Text',
      'my_library': 'Library',
      'scan_info': 'Take a photo of any text and Te Leo will read it aloud for you',
      
      // Onboarding steps
      'onboarding_step1_title': '📸 Scan any text',
      'onboarding_step1_description': 'Take a photo of books, documents, signs or any text you want to hear',
      'onboarding_step2_title': '🎧 Listen with natural voice',
      'onboarding_step2_description': 'Te Leo converts text to audio with natural and configurable voices',
      'onboarding_step3_title': '📚 Save to your library',
      'onboarding_step3_description': 'All your documents are automatically saved for easy access anytime',
      'onboarding_step4_title': '🌐 Translate instantly',
      'onboarding_step4_description': 'Translate any text between Spanish and English with just a photo',
      'onboarding_step5_title': '♿ Accessible design',
      'onboarding_step5_description': 'Optimized for people with low vision and dyslexia with special colors and typography',
      
      // Settings
      'settings_title': 'Settings',
      'general': 'General',
      'theme': 'Theme',
      'language': 'Language',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'language_spanish': 'Español',
      'language_english': 'English',
      'reading_reminders': 'Reading Reminders',
      'enable_reading_reminders': 'Enable reminders',
      'reminder_interval': 'Reminder interval',
      'send_test_notification': 'Send test notification',
      'reminder_interval_hours': 'hours',
      'voice_settings': 'Voice Settings',
      'test_voice': 'Test Voice',
      'voice_profile': 'Voice Profile',
      'advanced_voice_settings': 'Advanced Voice Settings',
      'voice_speed': 'Voice Speed',
      'voice_pitch': 'Voice Pitch',
      'voice_volume': 'Voice Volume',
      
      // OCR Translator
      'translator_title': '📸 Translator',
      'taking_photo': 'Taking photo...',
      'photo_cancelled': 'Photo cancelled',
      'selecting_image': 'Selecting image...',
      'image_selection_cancelled': 'Selection cancelled',
      'extracting_text': 'Extracting text...',
      'no_text_detected': 'No text detected in image',
      'translating_text': 'Translating...',
      'translation_completed': 'Translation completed',
      'translation_failed': 'Translation failed',
      'translation_saved': 'Translation saved',
      'document_saved_successfully': 'Document saved successfully',
      'translation_error': 'Translation error',
      'translator_welcome_title': 'OCR Translator',
      'translator_welcome_subtitle': 'Take a photo and translate text instantly',
      'take_photo': 'Take Photo',
      'select_from_gallery': 'Select from Gallery',
      'original_text': 'Original Text',
      'detected_language': 'Detected language: {{language}}',
      'translated_text': 'Translated Text',
      'confidence': 'Confidence: {{confidence}}',
      'try_again': 'Try Again',
      'play_text': 'Play Text',
      'target_language': 'Target Language',
      'save_translation': 'Save Translation',
      'translation_history': 'Translation History',
      'no_translation_history': 'No saved translations',
      'exit_app_title': 'Exit Application',
      'exit_app_message': 'Are you sure you want to exit?',
      'exit': 'Exit',
      'update_available': 'Update Available',
      'settings': 'Settings',
      
      // Navigation and general buttons
      'continue': 'Continue',
      'cancel': 'Cancel',
      'accept': 'Accept',
      'close': 'Close',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'finish': 'Finish',
      'start': 'Start',
      'skip': 'Skip',
      'retry': 'Retry',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',
      
      // Library
      'library_title': 'My Library',
      'library_empty': 'Your library is empty',
      'library_empty_subtitle': 'Scan your first document to get started',
      'search_documents': 'Search documents',
      'filter_by_date': 'Filter by date',
      'sort_by': 'Sort by',
      'sort_by_date': 'Date',
      'sort_by_title': 'Title',
      'sort_by_size': 'Size',
      'document_options': 'Document options',
      'play_document': 'Play document',
      'edit_document': 'Edit document',
      'share_document': 'Share document',
      'delete_document': 'Delete document',
      
      // Settings
      'accessibility': 'Accessibility',
      'about': 'About',
      'version': 'Version',
      'contact': 'Contact',
      'privacy': 'Privacy',
      'terms': 'Terms of Service',
      
      // Voice settings

      
      
      // TTS and playback
      'play': 'Play',
      'pause': 'Pause',
      'stop': 'Stop',
      'resume': 'Resume',
      'restart': 'Restart',
      'speed': 'Speed',
      'voice': 'Voice',
      
      // Reading progress
      'resume_reading': 'Resume reading',
      'restart_reading': 'Restart reading',
      'reading_progress': 'Reading progress',
      'resume_from_position': 'Resume from where you left off',
      'start_from_beginning': 'Start from beginning',
      
      // Errors and messages
      'error_camera_permission': 'Camera permission required',
      'error_storage_permission': 'Storage permission required',
      'error_no_camera': 'No camera available',
      'error_processing_image': 'Error processing image',
      'error_saving_document': 'Error saving document',
      'error_loading_document': 'Error loading document',
      'error_tts_not_available': 'Text-to-speech not available',
      'document_saved': 'Document saved',
      'document_deleted': 'Document deleted',
      
      // Confirmation dialogs
  
      'delete_document_title': 'Delete document',
      'delete_document_message': 'Are you sure you want to delete this document?',
      
      // Premium and subscriptions
      'premium_title': 'Te Leo Premium',
      'premium_description': 'Unlock all features',
      'premium_features_list': 'Unlimited access to all voices\nAdvanced playback speed\nUnlimited documents\nPriority support',
      'upgrade_to_premium': 'Upgrade to Premium',
      'demo_mode': 'Demo Mode',
      'demo_expires_in': 'Demo expires in',
      'days': 'days',
      
      // Reading reminders and notifications
      'reading_reminder_single_title': '📖 Continue reading!',
      'reading_reminder_single_body': 'You haven\'t finished reading "@document". Pick up where you left off!',
      'reading_reminder_multiple_title': '📚 You have pending readings!',
      'reading_reminder_multiple_body': 'You have @count unfinished documents. Continue reading!',
      'test_notification_title': '🔔 Test notification',
      'test_notification_body': 'Notifications are working correctly.',
    
      'reminder_settings': 'Reminder settings',
     
      
      // Translator module
      'new_translation': 'New translation',
     
      'translation_document_title': 'Translation @source → @target',
  
    },
  };
}
