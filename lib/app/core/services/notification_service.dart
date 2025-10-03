import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'debug_console_service.dart';
import 'subscription_service.dart';

/// Servicio centralizado de notificaciones
/// Maneja diferentes tipos de notificaciones según el estado premium del usuario
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _storage = GetStorage();

  // Estado reactivo
  final RxBool _notificationsEnabled = true.obs;
  final RxBool _premiumNotificationsEnabled = true.obs;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get premiumNotificationsEnabled => _premiumNotificationsEnabled.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNotifications();
    await _loadSettings();
    DebugLog.i('NotificationService initialized', category: LogCategory.service);
  }

  /// Inicializa el sistema de notificaciones
  Future<void> _initializeNotifications() async {
    try {
      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // Configuración para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notificationsPlugin.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTapped);

      // Crear canales de notificación
      await _createNotificationChannels();

      DebugLog.d('Notifications initialized successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing notifications: $e', category: LogCategory.service);
    }
  }

  /// Crea canales de notificación
  Future<void> _createNotificationChannels() async {
    try {
      // Canal para recordatorios de lectura (solo usuarios gratuitos)
      const readingRemindersChannel = AndroidNotificationChannel(
        'reading_reminders',
        'Recordatorios de Lectura',
        description: 'Notificaciones para recordar continuar leyendo documentos',
        importance: Importance.defaultImportance,
      );

      // Canal para notificaciones premium
      const premiumChannel = AndroidNotificationChannel(
        'premium_notifications',
        'Notificaciones Premium',
        description: 'Notificaciones especiales para usuarios premium',
        importance: Importance.high,
      );

      // Canal para actualizaciones de la app
      const updatesChannel = AndroidNotificationChannel(
        'app_updates',
        'Actualizaciones de la App',
        description: 'Notificaciones sobre nuevas versiones y características',
        importance: Importance.high,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(readingRemindersChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(premiumChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(updatesChannel);

      DebugLog.d('Notification channels created', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error creating notification channels: $e', category: LogCategory.service);
    }
  }

  /// Maneja cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload == null) return;

      DebugLog.d('Notification tapped: $payload', category: LogCategory.navigation);

      // Manejar diferentes tipos de notificaciones
      if (payload.startsWith('document:')) {
        final documentId = payload.substring(9);
        _openDocumentFromNotification(documentId);
      } else if (payload.startsWith('premium:')) {
        _handlePremiumNotification(payload);
      } else if (payload.startsWith('update:')) {
        _handleUpdateNotification(payload);
      }
    } catch (e) {
      DebugLog.e('Error handling notification tap: $e', category: LogCategory.service);
    }
  }

  /// Abre un documento desde la notificación
  void _openDocumentFromNotification(String documentId) {
    try {
      Get.toNamed('/document-reader', arguments: {'documentId': documentId});
      DebugLog.i('Opened document from notification: $documentId', category: LogCategory.navigation);
    } catch (e) {
      DebugLog.e('Error opening document from notification: $e', category: LogCategory.navigation);
    }
  }

  /// Maneja notificaciones premium
  void _handlePremiumNotification(String payload) {
    try {
      // Navegar a pantalla premium o mostrar información
      Get.toNamed('/premium');
      DebugLog.i('Handled premium notification: $payload', category: LogCategory.navigation);
    } catch (e) {
      DebugLog.e('Error handling premium notification: $e', category: LogCategory.navigation);
    }
  }

  /// Maneja notificaciones de actualización
  void _handleUpdateNotification(String payload) {
    try {
      // Mostrar información de actualización
      Get.snackbar(
        'Actualización disponible',
        'Hay una nueva versión de Te Leo disponible',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      DebugLog.i('Handled update notification: $payload', category: LogCategory.navigation);
    } catch (e) {
      DebugLog.e('Error handling update notification: $e', category: LogCategory.navigation);
    }
  }

  /// Envía notificación de recordatorio de lectura (solo usuarios gratuitos)
  Future<void> sendReadingReminder({required String documentTitle, required String documentId}) async {
    try {
      // Verificar si el usuario es premium
      if (_isPremiumUser()) {
        DebugLog.d('Premium user - skipping reading reminder', category: LogCategory.notification);
        return;
      }

      if (!_notificationsEnabled.value) return;

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Recordatorios de Lectura',
          channelDescription: 'Notificaciones para recordar continuar leyendo documentos',
          importance: Importance.defaultImportance,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        1,
        '📖 Continúa leyendo',
        'No olvides terminar de leer "$documentTitle"',
        notificationDetails,
        payload: 'document:$documentId',
      );

      DebugLog.i('Reading reminder sent for: $documentTitle', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending reading reminder: $e', category: LogCategory.notification);
    }
  }

  /// Envía notificación premium (solo usuarios premium)
  Future<void> sendPremiumNotification({required String title, required String body, String? payload}) async {
    try {
      // Solo enviar a usuarios premium
      if (!_isPremiumUser()) {
        DebugLog.d('Non-premium user - skipping premium notification', category: LogCategory.notification);
        return;
      }

      if (!_premiumNotificationsEnabled.value) return;

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'premium_notifications',
          'Notificaciones Premium',
          channelDescription: 'Notificaciones especiales para usuarios premium',
          importance: Importance.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(2, title, body, notificationDetails, payload: payload ?? 'premium:general');

      DebugLog.i('Premium notification sent: $title', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending premium notification: $e', category: LogCategory.notification);
    }
  }

  /// Envía notificación de actualización de app
  Future<void> sendUpdateNotification({required String version, required String changelog}) async {
    try {
      if (!_notificationsEnabled.value) return;

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'app_updates',
          'Actualizaciones de la App',
          channelDescription: 'Notificaciones sobre nuevas versiones y características',
          importance: Importance.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        3,
        '🚀 Nueva versión disponible',
        'Te Leo v$version está listo para descargar',
        notificationDetails,
        payload: 'update:$version',
      );

      DebugLog.i('Update notification sent for version: $version', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending update notification: $e', category: LogCategory.notification);
    }
  }

  /// Verificar si el usuario es premium
  bool _isPremiumUser() {
    try {
      final subscriptionService = Get.find<SubscriptionService>();
      return subscriptionService.isPremium && subscriptionService.isActive;
    } catch (e) {
      return false;
    }
  }

  /// Habilitar/deshabilitar notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      _notificationsEnabled.value = enabled;
      await _saveSettings();

      if (!enabled) {
        await _notificationsPlugin.cancelAll();
      }

      DebugLog.i('Notifications ${enabled ? 'enabled' : 'disabled'}', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error setting notifications enabled: $e', category: LogCategory.service);
    }
  }

  /// Habilitar/deshabilitar notificaciones premium
  Future<void> setPremiumNotificationsEnabled(bool enabled) async {
    try {
      _premiumNotificationsEnabled.value = enabled;
      await _saveSettings();

      DebugLog.i('Premium notifications ${enabled ? 'enabled' : 'disabled'}', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error setting premium notifications enabled: $e', category: LogCategory.service);
    }
  }

  /// Cargar configuraciones
  Future<void> _loadSettings() async {
    try {
      
      _notificationsEnabled.value = _storage.read<bool>('notifications_enabled') ?? true;
      _premiumNotificationsEnabled.value = _storage.read<bool>('premium_notifications_enabled') ?? true;

      DebugLog.d('Notification settings loaded', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error loading notification settings: $e', category: LogCategory.service);
    }
  }

  /// Guardar configuraciones
  Future<void> _saveSettings() async {
    try {
      
      await _storage.write('notifications_enabled', _notificationsEnabled.value);
      await _storage.write('premium_notifications_enabled', _premiumNotificationsEnabled.value);

      DebugLog.d('Notification settings saved', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving notification settings: $e', category: LogCategory.service);
    }
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      DebugLog.i('All notifications cancelled', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error cancelling notifications: $e', category: LogCategory.service);
    }
  }

  /// Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'notificationsEnabled': _notificationsEnabled.value,
      'premiumNotificationsEnabled': _premiumNotificationsEnabled.value,
      'isPremiumUser': _isPremiumUser(),
    };
  }
}

