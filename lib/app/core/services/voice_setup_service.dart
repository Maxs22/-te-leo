import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../global_widgets/modern_dialog.dart';
import 'tts_service.dart';
import 'debug_console_service.dart';

/// Servicio para configurar y verificar voces TTS durante la instalación
class VoiceSetupService extends GetxService {
  final TTSService _ttsService = Get.find<TTSService>();
  
  /// Lista de voces mínimas requeridas por idioma
  static const Map<String, List<String>> requiredVoices = {
    'es': ['es-ES', 'es-MX', 'es-AR'], // Español de España, México, Argentina
    'en': ['en-US', 'en-GB', 'en-AU'], // Inglés de US, UK, Australia
  };
  
  /// Verifica si las voces están disponibles y guía la instalación si es necesario
  Future<bool> checkAndSetupVoices() async {
    try {
      final availableVoices = await _ttsService.obtenerVocesReales();
      
      // Log de voces disponibles
      try {
        final debugService = Get.find<DebugConsoleService>();
        debugService.log(
          'Checking ${availableVoices.length} available voices',
          level: LogLevel.info,
          category: LogCategory.service,
        );
      } catch (_) {}
      
      final missingLanguages = <String>[];
      
      // Verificar cada idioma requerido
      for (final entry in requiredVoices.entries) {
        final languageCode = entry.key;
        final requiredLocales = entry.value;
        
        // Buscar si hay al menos una voz para este idioma
        final hasVoiceForLanguage = availableVoices.any((voice) {
          final locale = voice['locale']?.toString() ?? '';
          return requiredLocales.any((required) => locale.startsWith(required.split('-')[0]));
        });
        
        if (!hasVoiceForLanguage) {
          missingLanguages.add(languageCode);
        }
      }
      
      // Si faltan voces, mostrar guía de instalación
      if (missingLanguages.isNotEmpty) {
        return await _showVoiceInstallationGuide(missingLanguages, availableVoices);
      }
      
      return true;
      
    } catch (e) {
      try {
        final debugService = Get.find<DebugConsoleService>();
        debugService.log(
          'Error checking voices: $e',
          level: LogLevel.error,
          category: LogCategory.service,
        );
      } catch (_) {}
      return false;
    }
  }
  
  /// Muestra guía para instalar voces faltantes
  Future<bool> _showVoiceInstallationGuide(
    List<String> missingLanguages, 
    List<Map<String, dynamic>> availableVoices
  ) async {
    final currentLanguage = Get.locale?.languageCode ?? 'es';
    
    String title = currentLanguage == 'en' 
      ? '🎙️ Voice Setup Required' 
      : '🎙️ Configuración de Voces Requerida';
    
    String message = _buildInstallationMessage(missingLanguages, availableVoices, currentLanguage);
    
    final userChoice = await ModernDialog.mostrarConfirmacion(
      titulo: title,
      mensaje: message,
      textoConfirmar: currentLanguage == 'en' ? 'Install Voices' : 'Instalar Voces',
      textoCancelar: currentLanguage == 'en' ? 'Skip for Now' : 'Omitir por Ahora',
      icono: Icons.record_voice_over,
    );
    
    if (userChoice) {
      await _openTTSSettings();
      return await _waitForUserToInstallVoices();
    } else {
      // Usuario decidió omitir, usar voces disponibles
      return true;
    }
  }
  
  /// Construye mensaje de instalación personalizado
  String _buildInstallationMessage(
    List<String> missingLanguages, 
    List<Map<String, dynamic>> availableVoices,
    String currentLanguage
  ) {
    if (currentLanguage == 'en') {
      return '''Te Leo works best with quality voices installed on your device.

📱 Currently available: ${availableVoices.length} voices
🎯 Recommended: Install Spanish and English voices

Installing voices will give you:
• Multiple voice options (male/female)
• Better pronunciation quality  
• Offline reading capability
• Personalized reading experience

This is a one-time setup that takes 2-3 minutes.''';
    } else {
      return '''Te Leo funciona mejor con voces de calidad instaladas en tu dispositivo.

📱 Actualmente disponibles: ${availableVoices.length} voces
🎯 Recomendado: Instalar voces en español e inglés

Instalar voces te dará:
• Múltiples opciones de voz (masculina/femenina)
• Mejor calidad de pronunciación
• Capacidad de lectura sin internet
• Experiencia de lectura personalizada

Esta es una configuración única que toma 2-3 minutos.''';
    }
  }
  
  /// Abre configuración de TTS del sistema
  Future<void> _openTTSSettings() async {
    try {
      // Intentar abrir configuración específica de TTS
      await _openAndroidTTSSettings();
    } catch (e) {
      // Si falla, mostrar instrucciones manuales
      await _showManualInstructions();
    }
  }
  
  /// Abre configuración de TTS en Android usando método nativo
  Future<void> _openAndroidTTSSettings() async {
    const platform = MethodChannel('com.teleo.te_leo/voice_setup');
    try {
      await platform.invokeMethod('openTTSSettings');
    } catch (e) {
      // Fallback: intentar abrir configuración general
      await platform.invokeMethod('openSettings');
    }
  }
  
  /// Muestra instrucciones manuales para instalar voces
  Future<void> _showManualInstructions() async {
    final currentLanguage = Get.locale?.languageCode ?? 'es';
    
    final title = currentLanguage == 'en' 
      ? '📖 Manual Installation' 
      : '📖 Instalación Manual';
      
    final instructions = currentLanguage == 'en'
      ? '''Follow these steps to install voices:

🔹 Open Settings on your device
🔹 Go to Accessibility > Text-to-Speech
🔹 Select "Google Text-to-Speech Engine"  
🔹 Tap "Install voice data"
🔹 Download Spanish and English voices
🔹 Return to Te Leo when done

💡 Tip: Look for "Enhanced" or "Neural" voices for best quality!'''
      : '''Sigue estos pasos para instalar voces:

🔹 Abre Configuración en tu dispositivo
🔹 Ve a Accesibilidad > Texto a voz
🔹 Selecciona "Motor de Google Text-to-Speech"
🔹 Toca "Instalar datos de voz"
🔹 Descarga voces en español e inglés
🔹 Regresa a Te Leo cuando termines

💡 Consejo: Busca voces "Mejoradas" o "Neural" para mejor calidad!''';
    
    await ModernDialog.mostrarInformacion(
      titulo: title,
      mensaje: instructions,
      icono: Icons.help_outline,
    );
  }
  
  /// Espera a que el usuario instale voces y verifica
  Future<bool> _waitForUserToInstallVoices() async {
    final currentLanguage = Get.locale?.languageCode ?? 'es';
    
    final title = currentLanguage == 'en' 
      ? '⏳ Installation in Progress' 
      : '⏳ Instalación en Progreso';
      
    final message = currentLanguage == 'en'
      ? '''Please install the voices and return to Te Leo.

When you're done:
• Tap "Check Again" to verify installation
• Or tap "Continue" to proceed with current voices'''
      : '''Por favor instala las voces y regresa a Te Leo.

Cuando termines:
• Toca "Verificar" para confirmar la instalación  
• O toca "Continuar" para proceder con las voces actuales''';
    
    final userChoice = await ModernDialog.mostrarConfirmacion(
      titulo: title,
      mensaje: message,
      textoConfirmar: currentLanguage == 'en' ? 'Check Again' : 'Verificar',
      textoCancelar: currentLanguage == 'en' ? 'Continue' : 'Continuar',
      icono: Icons.refresh,
    );
    
    if (userChoice) {
      // Verificar de nuevo
      return await checkAndSetupVoices();
    } else {
      // Continuar con voces actuales
      return true;
    }
  }
  
  /// Obtiene resumen de voces disponibles
  Future<Map<String, dynamic>> getVoiceSummary() async {
    final availableVoices = await _ttsService.obtenerVocesReales();
    
    final summary = <String, dynamic>{
      'total': availableVoices.length,
      'spanish': 0,
      'english': 0,
      'other': 0,
      'voices': availableVoices,
    };
    
    for (final voice in availableVoices) {
      final locale = voice['locale']?.toString() ?? '';
      if (locale.startsWith('es')) {
        summary['spanish']++;
      } else if (locale.startsWith('en')) {
        summary['english']++;
      } else {
        summary['other']++;
      }
    }
    
    return summary;
  }
  
  /// Verifica si hay suficientes voces para una buena experiencia
  Future<bool> hasGoodVoiceSetup() async {
    final summary = await getVoiceSummary();
    return summary['spanish'] >= 1 && summary['english'] >= 1;
  }
}
