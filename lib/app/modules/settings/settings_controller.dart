import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/configuracion_provider.dart';
import '../../data/models/configuracion_usuario.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/debug_console_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/theme_service.dart';
import '../../../global_widgets/global_widgets.dart';
import '../../core/models/voice_profiles.dart';

/// Controlador para la página de configuraciones
/// Gestiona todas las configuraciones del usuario y opciones premium
class SettingsController extends GetxController {
  final ConfiguracionProvider _configProvider = ConfiguracionProvider();
  final TTSService _ttsService = Get.find<TTSService>();
  
  // Servicios opcionales (pueden no estar disponibles)
  LanguageService? _languageService;
  ThemeService? _themeService;

  /// Configuración actual del usuario
  final Rx<ConfiguracionUsuario> _configuracion = ConfiguracionUsuario.nuevoUsuario('Usuario').obs;
  ConfiguracionUsuario get configuracion => _configuracion.value;

  /// Indica si se están cargando las configuraciones
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  /// Lista de voces disponibles para TTS
  final RxList<Map<String, dynamic>> _vocesDisponibles = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get vocesDisponibles => _vocesDisponibles;

  /// Lista de idiomas disponibles
  final RxList<String> _idiomasDisponibles = <String>[].obs;
  List<String> get idiomasDisponibles => _idiomasDisponibles;

  /// Controladores de texto para formularios
  late TextEditingController nombreController;
  late TextEditingController emailController;

  @override
  void onInit() {
    super.onInit();
    _inicializarControladores();
    _inicializarServicios();
    cargarConfiguraciones();
  }
  
  /// Inicializar servicios opcionales
  void _inicializarServicios() {
    try {
      _languageService = Get.find<LanguageService>();
      _themeService = Get.find<ThemeService>();
    } catch (e) {
      DebugLog.w('Some services not available in SettingsController', category: LogCategory.app);
    }
  }

  @override
  void onClose() {
    nombreController.dispose();
    emailController.dispose();
    super.onClose();
  }

  /// Inicializa los controladores de texto
  void _inicializarControladores() {
    nombreController = TextEditingController();
    emailController = TextEditingController();
  }

  /// Carga las configuraciones del usuario
  Future<void> cargarConfiguraciones() async {
    _isLoading.value = true;
    
    try {
      final config = await _configProvider.obtenerConfiguracion();
      _configuracion.value = config;
      
      // Actualizar controladores de texto
      nombreController.text = config.nombreUsuario;
      emailController.text = config.email ?? '';
      
      // Cargar voces disponibles
      await _cargarVocesDisponibles();
      
      // Aplicar configuraciones al servicio TTS
      await _aplicarConfiguracionTTS();
      
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error cargando configuraciones: $e',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Carga las voces disponibles del servicio TTS
  Future<void> _cargarVocesDisponibles() async {
    try {
      _vocesDisponibles.value = _ttsService.vocesDisponibles;
      _idiomasDisponibles.value = _ttsService.idiomasDisponibles;
    } catch (e) {
      DebugLog.service('Error cargando voces: $e');
    }
  }

  /// Aplica la configuración actual al servicio TTS
  Future<void> _aplicarConfiguracionTTS() async {
    try {
      final configTTS = ConfiguracionVoz(
        idioma: _configuracion.value.idiomaVoz,
        velocidad: _configuracion.value.velocidadVoz,
        tono: _configuracion.value.tonoVoz,
        volumen: _configuracion.value.volumenVoz,
        vozSeleccionada: _configuracion.value.vozSeleccionada,
      );
      
      await _ttsService.actualizarConfiguracion(configTTS);
    } catch (e) {
      DebugLog.service('Error aplicando configuración TTS: $e');
    }
  }

  /// Actualiza el tema de la aplicación
  Future<void> actualizarTema(TipoTema nuevoTema) async {
    try {
      await _configProvider.actualizarTema(nuevoTema);
      _configuracion.value = _configuracion.value.copyWith(tema: nuevoTema);
      
      // Aplicar tema inmediatamente
      _aplicarTema(nuevoTema);
      
      Get.snackbar(
        'Tema actualizado',
        'El tema se ha cambiado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error actualizando tema: $e',
      );
    }
  }

  /// Aplica el tema seleccionado
  void _aplicarTema(TipoTema tema) {
    switch (tema) {
      case TipoTema.claro:
        Get.changeThemeMode(ThemeMode.light);
        break;
      case TipoTema.oscuro:
        Get.changeThemeMode(ThemeMode.dark);
        break;
      case TipoTema.sistema:
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }

  /// Actualiza configuraciones de TTS
  Future<void> actualizarConfiguracionTTS({
    String? idiomaVoz,
    String? vozSeleccionada,
    double? velocidad,
    double? tono,
    double? volumen,
  }) async {
    try {
      await _configProvider.actualizarConfiguracionTTS(
        idiomaVoz: idiomaVoz,
        vozSeleccionada: vozSeleccionada,
        velocidad: velocidad,
        tono: tono,
        volumen: volumen,
      );

      _configuracion.value = _configuracion.value.copyWith(
        idiomaVoz: idiomaVoz ?? _configuracion.value.idiomaVoz,
        vozSeleccionada: vozSeleccionada ?? _configuracion.value.vozSeleccionada,
        velocidadVoz: velocidad ?? _configuracion.value.velocidadVoz,
        tonoVoz: tono ?? _configuracion.value.tonoVoz,
        volumenVoz: volumen ?? _configuracion.value.volumenVoz,
      );

      await _aplicarConfiguracionTTS();
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error actualizando configuración de voz: $e',
      );
    }
  }

  /// Muestra información de voces disponibles y guía descarga
  Future<void> mostrarInfoVoces() async {
    try {
      final vocesReales = await _ttsService.obtenerVocesReales();
      
      final mensaje = '''
📱 Voces disponibles en tu dispositivo: ${vocesReales.length}

${vocesReales.map((v) => '• ${v['name']} (${v['locale']})').join('\n')}

💡 Para más voces:
1. Ve a Configuración → Accesibilidad → Texto a voz
2. Selecciona "Motor de Google Text-to-Speech"
3. Toca "Instalar datos de voz"
4. Descarga voces adicionales en español e inglés
''';

      await ModernDialog.mostrarInformacion(
        titulo: 'Voces TTS Disponibles',
        mensaje: mensaje,
        icono: Icons.record_voice_over,
      );
    } catch (e) {
      await ModernDialog.mostrarError(
        titulo: 'Error',
        mensaje: 'No se pudo obtener información de voces: $e',
      );
    }
  }

  /// Prueba la configuración de voz actual
  Future<void> probarVoz() async {
    try {
      // Detener cualquier reproducción anterior
      await _ttsService.stopAll();
      
      // Obtener configuración de la voz seleccionada
      final voiceProfile = _getVoiceProfileFromId(_configuracion.value.vozSeleccionada);
      
      // Configurar TTS con las configuraciones de la voz seleccionada
      final config = ConfiguracionVoz(
        velocidad: voiceProfile?.defaultSpeed ?? _configuracion.value.velocidadVoz,
        tono: voiceProfile?.defaultPitch ?? _configuracion.value.tonoVoz,
        volumen: _configuracion.value.volumenVoz,
        idioma: voiceProfile?.language ?? _configuracion.value.idiomaVoz,
        vozSeleccionada: voiceProfile?.name ?? _configuracion.value.idiomaVoz,
      );
      await _ttsService.actualizarConfiguracion(config);
      
      // Reproducir texto de prueba personalizado
      final nombreUsuario = _configuracion.value.nombreUsuario;
      final textoPrueba = _getPersonalizedTestMessage(nombreUsuario);
      await _ttsService.reproducir(textoPrueba);
      
      // Log success using the debug system
      try {
        final debugService = Get.find<DebugConsoleService>();
        debugService.log('Voice test completed successfully', level: LogLevel.info, category: LogCategory.service);
      } catch (_) {
        // Debug service not available, skip logging
      }
    } catch (e) {
      try {
        final debugService = Get.find<DebugConsoleService>();
        debugService.log('Error testing voice: $e', level: LogLevel.error, category: LogCategory.service);
      } catch (_) {
        // Debug service not available, skip logging
      }
      await ModernDialog.mostrarError(
        titulo: 'Error de voz',
        mensaje: 'No se pudo reproducir la prueba de voz. Verifica que el servicio de texto a voz esté disponible.',
      );
    }
  }

  /// Obtiene el perfil de voz por ID
  VoiceProfile? _getVoiceProfileFromId(String? voiceId) {
    if (voiceId == null) return null;
    
    try {
      return VoiceProfileManager.getVoiceById(voiceId);
    } catch (e) {
      return null;
    }
  }

  /// Genera mensaje de prueba personalizado
  String _getPersonalizedTestMessage(String nombreUsuario) {
    final currentLanguage = Get.locale?.languageCode ?? 'es';
    
    // Mensajes variados para hacer más interesante
    final mensajesEspanol = [
      '¡Hola $nombreUsuario! Esta es tu nueva voz en Te Leo.',
      'Hola $nombreUsuario, me gusta como suena esta voz, ¿a ti también?',
      '¡Perfecto $nombreUsuario! Con esta voz podrás escuchar todos tus documentos.',
      'Hola $nombreUsuario, esta voz te acompañará en todas tus lecturas.',
      '¡Excelente elección $nombreUsuario! Esta voz hará que leer sea más divertido.',
    ];
    
    final mensajesIngles = [
      'Hello $nombreUsuario! This is your new voice in Te Leo.',
      'Hi $nombreUsuario, I like how this voice sounds, do you?',
      'Perfect $nombreUsuario! With this voice you can listen to all your documents.',
      'Hello $nombreUsuario, this voice will accompany you in all your readings.',
      'Excellent choice $nombreUsuario! This voice will make reading more fun.',
    ];
    
    final mensajes = currentLanguage == 'en' ? mensajesIngles : mensajesEspanol;
    final randomIndex = DateTime.now().millisecond % mensajes.length;
    
    return mensajes[randomIndex];
  }

  /// Actualiza información del usuario
  Future<void> actualizarInfoUsuario() async {
    final nuevoNombre = nombreController.text.trim();
    final nuevoEmail = emailController.text.trim();

    if (nuevoNombre.isEmpty) {
      await ModernDialog.mostrarError(
        mensaje: 'El nombre no puede estar vacío',
      );
      return;
    }

    try {
      LoadingOverlay.mostrar(mensaje: 'Actualizando información...');

      await _configProvider.actualizarInfoUsuario(
        nombreUsuario: nuevoNombre,
        email: nuevoEmail.isNotEmpty ? nuevoEmail : null,
      );

      _configuracion.value = _configuracion.value.copyWith(
        nombreUsuario: nuevoNombre,
        email: nuevoEmail.isNotEmpty ? nuevoEmail : null,
      );

      LoadingOverlay.ocultar();
      
      Get.snackbar(
        'Información actualizada',
        'Tus datos se han guardado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      LoadingOverlay.ocultar();
      await ModernDialog.mostrarError(
        mensaje: 'Error actualizando información: $e',
      );
    }
  }

  /// Actualiza configuraciones de accesibilidad
  Future<void> actualizarConfiguracionAccesibilidad({
    double? tamanoFuente,
    bool? modoAltoContraste,
  }) async {
    try {
      final nuevaConfig = _configuracion.value.copyWith(
        tamanoFuente: tamanoFuente,
        modoAltoContraste: modoAltoContraste,
      );

      await _configProvider.guardarConfiguracion(nuevaConfig);
      _configuracion.value = nuevaConfig;

      Get.snackbar(
        'Configuración actualizada',
        'Los cambios de accesibilidad se han aplicado',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      await ModernDialog.mostrarError(
        mensaje: 'Error actualizando accesibilidad: $e',
      );
    }
  }

  /// Muestra información sobre características premium
  Future<void> mostrarInfoPremium() async {
    await ModernDialog.mostrarInformacion(
      titulo: 'Te Leo Premium',
      mensaje: '''
¡Desbloquea todas las características!

✨ Características Premium:
• Sincronización en la nube
• Respaldo automático
• Voces premium adicionales
• Sin límites de documentos
• Soporte prioritario

¿Te gustaría obtener Premium?
      ''',
      icono: Icons.star,
      colorIcono: Colors.amber,
    );
  }


  /// Resetea todas las configuraciones
  Future<void> resetearConfiguraciones() async {
    final confirmar = await ModernDialog.mostrarConfirmacion(
      titulo: 'Resetear configuraciones',
      mensaje: '¿Estás seguro de que quieres restaurar todas las configuraciones a sus valores por defecto?',
      textoConfirmar: 'Resetear',
      textoCancelar: 'Cancelar',
      icono: Icons.restore,
      colorIcono: Colors.orange,
    );

    if (!confirmar) return;

    try {
      LoadingOverlay.mostrar(mensaje: 'Restaurando configuraciones...');

      await _configProvider.resetearConfiguraciones();
      await cargarConfiguraciones();

      LoadingOverlay.ocultar();
      
      await ModernDialog.mostrarExito(
        mensaje: 'Las configuraciones se han restaurado correctamente',
      );
    } catch (e) {
      LoadingOverlay.ocultar();
      await ModernDialog.mostrarError(
        mensaje: 'Error restaurando configuraciones: $e',
      );
    }
  }

  /// Exporta configuraciones para respaldo
  Future<void> exportarConfiguraciones() async {
    try {
      LoadingOverlay.mostrar(mensaje: 'Exportando configuraciones...');

      await _configProvider.exportarConfiguraciones();
      
      // Aquí podrías implementar la lógica para guardar en archivo o compartir
      // Por ahora solo mostramos un mensaje
      
      LoadingOverlay.ocultar();
      
      Get.snackbar(
        'Exportación completa',
        'Las configuraciones se han exportado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      LoadingOverlay.ocultar();
      await ModernDialog.mostrarError(
        mensaje: 'Error exportando configuraciones: $e',
      );
    }
  }

  /// Verifica si una característica es premium
  bool esCaracteristicaPremium(String caracteristica) {
    const caracteristicasPremium = [
      'sincronizacion_nube',
      'respaldo_automatico',
      'voces_premium',
      'documentos_ilimitados',
    ];
    
    return caracteristicasPremium.contains(caracteristica);
  }

  /// Verifica si el usuario puede usar una característica premium
  bool puedeUsarCaracteristica(String caracteristica) {
    if (!esCaracteristicaPremium(caracteristica)) return true;
    return _configuracion.value.puedeUsarCaracteristicaPremium(caracteristica);
  }


  /// Obtiene las estadísticas de uso formateadas
  Map<String, String> get estadisticasUso {
    return {
      'Documentos escaneados': '${_configuracion.value.documentosEscaneados}',
      'Minutos escuchados': '${_configuracion.value.minutosEscuchados}',
      'Días restantes Premium': _configuracion.value.tienePremiumActivo 
          ? '${_configuracion.value.diasRestantesPremium}'
          : 'No activo',
    };
  }

  /// Verifica si hay actualizaciones disponibles
  Future<void> checkForUpdates() async {
    try {
      DebugLog.i('User requested manual update check', category: LogCategory.ui);
      
      final updateService = Get.find<AppUpdateService>();
      final updateInfo = await updateService.checkForUpdates(showDialog: true);
      
      if (updateInfo == null || !updateInfo.hasUpdate) {
        // No hay actualizaciones disponibles
        Get.dialog(
          ModernDialog(
            titulo: 'Te Leo Actualizado',
            contenido: 'Ya tienes la versión más reciente de Te Leo.',
            textoBotonPrimario: 'Entendido',
            onBotonPrimario: () => Get.back(),
          ),
        );
      }
      // Si hay actualización, el servicio ya mostrará el dialog automáticamente
      
    } catch (e) {
      DebugLog.e('Error checking for updates: $e', category: LogCategory.ui);
      
      Get.dialog(
        ModernDialog(
          titulo: 'Error',
          contenido: 'No se pudo verificar si hay actualizaciones disponibles.\n'
                     'Verifica tu conexión a internet e intenta nuevamente.',
          textoBotonPrimario: 'Reintentar',
          textoBotonSecundario: 'Cancelar',
          onBotonPrimario: () {
            Get.back();
            checkForUpdates();
          },
          onBotonSecundario: () => Get.back(),
        ),
      );
    }
  }
  
  /// Métodos para manejar idioma y tema
  
  /// Obtener el nombre del idioma actual
  String get textoIdiomaActual {
    if (_languageService != null) {
      return _languageService!.currentLanguageName;
    }
    return 'language_spanish'.tr;
  }
  
  /// Obtener el nombre del tema actual
  String get textoTemaActual {
    if (_themeService != null) {
      return _themeService!.currentThemeName;
    }
    return 'theme_system'.tr;
  }
  
  /// Cambiar idioma
  Future<void> cambiarIdioma(String languageCode) async {
    try {
      if (_languageService != null) {
        await _languageService!.changeLanguageByString(languageCode);
        
        Get.snackbar(
          'success'.tr,
          'language'.tr + ' ' + 'success'.tr.toLowerCase(),
          snackPosition: SnackPosition.BOTTOM,
        );
        
        // Forzar actualización de la UI
        update();
      }
    } catch (e) {
      DebugLog.e('Error changing language: $e', category: LogCategory.app);
      Get.snackbar(
        'error'.tr,
        'Error cambiando idioma',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// Cambiar tema
  Future<void> cambiarTema(ThemeMode themeMode) async {
    try {
      if (_themeService != null) {
        await _themeService!.changeTheme(themeMode);
        
        Get.snackbar(
          'success'.tr,
          'theme'.tr + ' ' + 'success'.tr.toLowerCase(),
          snackPosition: SnackPosition.BOTTOM,
        );
        
        // Forzar actualización de la UI
        update();
      }
    } catch (e) {
      DebugLog.e('Error changing theme: $e', category: LogCategory.app);
      Get.snackbar(
        'error'.tr,
        'Error cambiando tema',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
