/// Configuración para límites de uso de la versión gratuita
class LimitsConfig {
  // Límites de documentos
  static const int LIMITE_DOCUMENTOS_GRATIS = 5;
  static const int LIMITE_DOCUMENTOS_PREMIUM = -1; // Ilimitado
  
  // Límites de tiempo de lectura
  static const Duration LIMITE_TIEMPO_LECTURA_GRATIS = Duration(minutes: 30);
  static const Duration LIMITE_TIEMPO_LECTURA_PREMIUM = Duration.zero; // Sin límite
  
  // Límites de OCR
  static const int LIMITE_OCR_GRATIS = 10;
  static const int LIMITE_OCR_PREMIUM = -1; // Ilimitado
  
  // Límites de exportación
  static const int LIMITE_EXPORTACION_GRATIS = 3;
  static const int LIMITE_EXPORTACION_PREMIUM = -1; // Ilimitado
  
  // Período de reseteo
  static const Duration PERIODO_RESETEO = Duration(days: 30);
  
  // Configuración de notificaciones
  static const bool NOTIFICACIONES_LIMITE_ACTIVAS = true;
  static const Duration TIEMPO_ANTES_LIMITE_NOTIFICACION = Duration(days: 3);
  
  // Configuración de upgrade
  static const bool MOSTRAR_UPGRADE_SUGGESTION = true;
  static const int UMBRAL_SUGGESTION_DOCUMENTOS = 3; // Sugerir upgrade cuando queden 3 documentos
  
  /// Obtener límite de documentos según el tipo de usuario
  static int getDocumentLimit(bool isPremium) {
    return isPremium ? LIMITE_DOCUMENTOS_PREMIUM : LIMITE_DOCUMENTOS_GRATIS;
  }
  
  /// Obtener límite de tiempo según el tipo de usuario
  static Duration getTimeLimit(bool isPremium) {
    return isPremium ? LIMITE_TIEMPO_LECTURA_PREMIUM : LIMITE_TIEMPO_LECTURA_GRATIS;
  }
  
  /// Obtener límite de OCR según el tipo de usuario
  static int getOCRLimit(bool isPremium) {
    return isPremium ? LIMITE_OCR_PREMIUM : LIMITE_OCR_GRATIS;
  }
  
  /// Obtener límite de exportación según el tipo de usuario
  static int getExportLimit(bool isPremium) {
    return isPremium ? LIMITE_EXPORTACION_PREMIUM : LIMITE_EXPORTACION_GRATIS;
  }
  
  /// Verificar si un límite es ilimitado
  static bool isUnlimited(int limit) {
    return limit == -1;
  }
  
  /// Verificar si se debe mostrar sugerencia de upgrade
  static bool shouldShowUpgradeSuggestion(int currentUsage, int limit) {
    if (isUnlimited(limit)) return false;
    return MOSTRAR_UPGRADE_SUGGESTION && 
           (limit - currentUsage) <= UMBRAL_SUGGESTION_DOCUMENTOS;
  }
  
  /// Calcular porcentaje de uso
  static double calculateUsagePercentage(int currentUsage, int limit) {
    if (isUnlimited(limit)) return 0.0;
    if (limit == 0) return 1.0;
    return (currentUsage / limit).clamp(0.0, 1.0);
  }
  
  /// Obtener mensaje de límite alcanzado
  static String getLimitReachedMessage(String limitType, bool isPremium) {
    if (isPremium) {
      return 'Tienes acceso ilimitado con Te Leo Premium';
    }
    
    switch (limitType.toLowerCase()) {
      case 'documentos':
        return 'Has alcanzado el límite de $LIMITE_DOCUMENTOS_GRATIS documentos gratuitos';
      case 'tiempo':
        return 'Has alcanzado el límite de ${LIMITE_TIEMPO_LECTURA_GRATIS.inMinutes} minutos de lectura';
      case 'ocr':
        return 'Has alcanzado el límite de $LIMITE_OCR_GRATIS escaneos gratuitos';
      case 'exportacion':
        return 'Has alcanzado el límite de $LIMITE_EXPORTACION_GRATIS exportaciones gratuitas';
      default:
        return 'Has alcanzado el límite de uso gratuito';
    }
  }
}
