/// Configuración para compras y suscripciones
class PurchaseConfig {
  // IDs de productos de suscripción
  static const String monthlyProductId = 'te_leo_premium_monthly';
  static const String yearlyProductId = 'te_leo_premium_yearly';

  // Precios (en centavos)
  static const Map<String, int> prices = {
    'monthly': 499, // $4.99
    'yearly': 4999, // $49.99
  };

  // Configuración de prueba
  static const bool isTestMode = false; // Cambiar a false para producción
  static const List<String> testDeviceIds = [];

  // Configuración de compras
  static const String currencyCode = 'USD';
  static const String countryCode = 'US';

  // Configuración de validación
  // NOTA: Desactivado hasta implementar backend. Google Play maneja la validación automáticamente.
  static const bool validateReceipts = false;
  static const String receiptValidationUrl = ''; // TODO: Implementar cuando tengas backend

  // Configuración de reintentos
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Configuración de cache
  static const Duration cacheExpiration = Duration(hours: 1);

  /// Obtener precio formateado
  static String getFormattedPrice(String productType) {
    final price = prices[productType] ?? 0;
    return '\$${(price / 100).toStringAsFixed(2)}';
  }

  /// Verificar si es un producto válido
  static bool isValidProduct(String productId) {
    return productId == monthlyProductId || productId == yearlyProductId;
  }

  /// Obtener tipo de producto por ID
  static String? getProductType(String productId) {
    switch (productId) {
      case monthlyProductId:
        return 'monthly';
      case yearlyProductId:
        return 'yearly';
      default:
        return null;
    }
  }
}
