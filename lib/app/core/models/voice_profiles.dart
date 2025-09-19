import 'package:get/get.dart';
import '../services/tts_service.dart';

/// Perfil de voz con características específicas
class VoiceProfile {
  final String id;
  final String name;
  final String displayName;
  final String language;
  final double defaultSpeed;
  final double defaultPitch;
  final String description;
  final String? gender; // 'male', 'female', 'neutral'
  final bool isAvailable;

  const VoiceProfile({
    required this.id,
    required this.name,
    required this.displayName,
    required this.language,
    this.defaultSpeed = 0.5,
    this.defaultPitch = 1.0,
    required this.description,
    this.gender,
    this.isAvailable = true,
  });

  /// Convierte a ConfiguracionVoz
  ConfiguracionVoz toConfiguracionVoz({
    double? customSpeed,
    double? customPitch,
    double? customVolume,
  }) {
    return ConfiguracionVoz(
      idioma: language,
      velocidad: customSpeed ?? defaultSpeed,
      tono: customPitch ?? defaultPitch,
      volumen: customVolume ?? 0.8,
      vozSeleccionada: name,
    );
  }
}

/// Gestor de perfiles de voz predefinidos
class VoiceProfileManager {
  /// Cache de voces disponibles
  static List<Map<String, dynamic>>? _availableVoices;
  
  /// Obtener voces disponibles del dispositivo
  static Future<List<Map<String, dynamic>>> _getAvailableVoices() async {
    if (_availableVoices == null) {
      try {
        final ttsService = Get.find<TTSService>();
        _availableVoices = await ttsService.obtenerVocesReales();
      } catch (e) {
        _availableVoices = [];
      }
    }
    return _availableVoices!;
  }
  
  /// Voces para español usando voces reales del dispositivo
  static Future<List<VoiceProfile>> getSpanishVoices() async {
    final availableVoices = await _getAvailableVoices();
    final spanishVoicesData = availableVoices.where((voice) => 
      voice['locale']?.toString().startsWith('es') == true
    ).toList();
    
    final profiles = <VoiceProfile>[];
    
    // Si hay voces disponibles, crear perfiles dinámicos
    if (spanishVoicesData.isNotEmpty) {
      for (int i = 0; i < spanishVoicesData.length && i < 5; i++) {
        final voice = spanishVoicesData[i];
        final voiceName = voice['name']?.toString() ?? 'es-ES';
        final locale = voice['locale']?.toString() ?? 'es-ES';
        
        profiles.add(VoiceProfile(
          id: 'es_dynamic_$i',
          name: voiceName,
          displayName: _getDisplayName(i, voiceName),
          language: locale,
          defaultSpeed: _getSpeed(i),
          defaultPitch: _getPitch(i),
          description: _getDescription(i),
          gender: _getGender(i),
          isAvailable: true,
        ));
      }
    }
    
    // Si no hay voces disponibles o son pocas, agregar perfiles genéricos
    if (profiles.length < 3) {
      profiles.addAll(_getDefaultSpanishVoices());
    }
    
    return profiles.take(5).toList();
  }
  
  /// Obtener nombre de display dinámico
  static String _getDisplayName(int index, String voiceName) {
    final icons = ['🎭', '🎙️', '✨', '📚', '🌙'];
    final names = ['Clara', 'Miguel', 'Sofía', 'Carlos', 'Luna'];
    return '${icons[index % icons.length]} ${names[index % names.length]}';
  }
  
  /// Obtener velocidad variada
  static double _getSpeed(int index) {
    final speeds = [0.5, 0.4, 0.6, 0.45, 0.5];
    return speeds[index % speeds.length];
  }
  
  /// Obtener tono variado
  static double _getPitch(int index) {
    final pitches = [1.0, 0.9, 1.1, 0.95, 1.05];
    return pitches[index % pitches.length];
  }
  
  /// Obtener descripción variada
  static String _getDescription(int index) {
    final descriptions = [
      'Voz clara y natural, ideal para lectura general',
      'Voz profunda y pausada, perfecta para textos largos',
      'Voz juvenil y energética, ideal para contenido dinámico',
      'Voz académica y formal, perfecta para documentos profesionales',
      'Voz suave y relajante, ideal para lectura nocturna',
    ];
    return descriptions[index % descriptions.length];
  }
  
  /// Obtener género alternado
  static String _getGender(int index) {
    return index % 2 == 0 ? 'female' : 'male';
  }
  
  /// Voces por defecto para español (usando solo voces genéricas que existen)
  static List<VoiceProfile> _getDefaultSpanishVoices() => const [
    VoiceProfile(
      id: 'es_lenta',
      name: 'es-ES',
      displayName: '🐢 Lenta',
      language: 'es-ES',
      defaultSpeed: 0.3,
      defaultPitch: 0.9,
      description: 'Velocidad muy lenta, ideal para aprendizaje',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'es_normal',
      name: 'es-ES',
      displayName: '🎭 Normal',
      language: 'es-ES',
      defaultSpeed: 0.5,
      defaultPitch: 1.0,
      description: 'Velocidad normal, ideal para lectura general',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'es_rapida',
      name: 'es-ES',
      displayName: '⚡ Rápida',
      language: 'es-ES',
      defaultSpeed: 0.7,
      defaultPitch: 1.1,
      description: 'Velocidad rápida, ideal para repaso',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'es_grave',
      name: 'es-ES',
      displayName: '🎙️ Grave',
      language: 'es-ES',
      defaultSpeed: 0.5,
      defaultPitch: 0.8,
      description: 'Tono grave y profundo, relajante',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'es_aguda',
      name: 'es-ES',
      displayName: '✨ Aguda',
      language: 'es-ES',
      defaultSpeed: 0.5,
      defaultPitch: 1.2,
      description: 'Tono agudo y claro, energizante',
      gender: 'neutral',
    ),
  ];

  /// Voces por defecto para inglés (usando solo voces genéricas que existen)
  static List<VoiceProfile> _getDefaultEnglishVoices() => const [
    VoiceProfile(
      id: 'en_slow',
      name: 'en-US',
      displayName: '🐢 Slow',
      language: 'en-US',
      defaultSpeed: 0.3,
      defaultPitch: 0.9,
      description: 'Very slow speed, ideal for learning',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'en_normal',
      name: 'en-US',
      displayName: '🎭 Normal',
      language: 'en-US',
      defaultSpeed: 0.5,
      defaultPitch: 1.0,
      description: 'Normal speed, ideal for general reading',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'en_fast',
      name: 'en-US',
      displayName: '⚡ Fast',
      language: 'en-US',
      defaultSpeed: 0.7,
      defaultPitch: 1.1,
      description: 'Fast speed, ideal for review',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'en_deep',
      name: 'en-US',
      displayName: '🎙️ Deep',
      language: 'en-US',
      defaultSpeed: 0.5,
      defaultPitch: 0.8,
      description: 'Deep and low tone, relaxing',
      gender: 'neutral',
    ),
    VoiceProfile(
      id: 'en_bright',
      name: 'en-US',
      displayName: '✨ Bright',
      language: 'en-US',
      defaultSpeed: 0.5,
      defaultPitch: 1.2,
      description: 'High and clear tone, energizing',
      gender: 'neutral',
    ),
  ];

  /// Obtiene voces para un idioma específico (versión síncrona para compatibilidad)
  static List<VoiceProfile> getVoicesForLanguage(String languageCode) {
    // Usar voces por defecto hasta que se implemente el sistema dinámico
    switch (languageCode) {
      case 'es':
      case 'es_ES':
      case 'es-ES':
        return _getDefaultSpanishVoices();
      case 'en':
      case 'en_US':
      case 'en-US':
      case 'en_GB':
      case 'en-GB':
        return _getDefaultEnglishVoices();
      default:
        return _getDefaultSpanishVoices(); // Default a español
    }
  }

  /// Obtiene voz por ID
  static VoiceProfile? getVoiceById(String voiceId) {
    final allVoices = [..._getDefaultSpanishVoices(), ..._getDefaultEnglishVoices()];
    try {
      return allVoices.firstWhere((voice) => voice.id == voiceId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene voz por nombre del sistema
  static VoiceProfile? getVoiceBySystemName(String systemName) {
    final allVoices = [..._getDefaultSpanishVoices(), ..._getDefaultEnglishVoices()];
    try {
      return allVoices.firstWhere((voice) => voice.name == systemName);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la voz por defecto para un idioma
  static VoiceProfile getDefaultVoiceForLanguage(String languageCode) {
    final voices = getVoicesForLanguage(languageCode);
    return voices.isNotEmpty ? voices.first : _getDefaultSpanishVoices().first;
  }

  /// Verifica si una voz está disponible en el dispositivo
  static Future<bool> isVoiceAvailable(VoiceProfile voice) async {
    // TODO: Implementar verificación real con FlutterTts.getVoices()
    return true; // Por ahora, asumir que todas están disponibles
  }

  /// Obtiene todas las voces disponibles
  static List<VoiceProfile> getAllVoices() {
    return [..._getDefaultSpanishVoices(), ..._getDefaultEnglishVoices()];
  }

  /// Filtra voces por género
  static List<VoiceProfile> getVoicesByGender(String languageCode, String? gender) {
    final voices = getVoicesForLanguage(languageCode);
    if (gender == null) return voices;
    
    return voices.where((voice) => voice.gender == gender).toList();
  }
}
