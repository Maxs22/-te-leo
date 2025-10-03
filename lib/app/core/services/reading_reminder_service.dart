import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/documento.dart';
import '../../data/providers/database_provider.dart';
import '../../routes/app_routes.dart';
import 'debug_console_service.dart';
import 'subscription_service.dart';

/// Servicio para gestionar recordatorios de lectura mediante notificaciones push
/// Envía notificaciones cuando el usuario no ha terminado de leer un documento
class ReadingReminderService extends GetxService {
  static const String _reminderEnabledKey = 'reading_reminders_enabled';
  static const String _reminderIntervalKey = 'reading_reminder_interval_hours';
  static const String _lastReminderKey = 'last_reminder_timestamp';
  static const String _firstIncompleteDetectedKey = 'first_incomplete_detected_';
  static const String _lastPremiumReminderKey = 'last_premium_reminder_timestamp';
  static const String _lastScanDateKey = 'last_scan_date';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final DatabaseProvider _databaseProvider = DatabaseProvider();
  final _storage = GetStorage();

  /// Estados reactivos
  final RxBool _isEnabled = true.obs;
  final RxInt _reminderIntervalHours = 24.obs; // Por defecto 24 horas

  bool get isEnabled => _isEnabled.value;
  int get reminderIntervalHours => _reminderIntervalHours.value;

  Timer? _reminderTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _loadSettings();
    _startReminderTimer();
    DebugLog.i('ReadingReminderService initialized', category: LogCategory.service);
  }

  @override
  void onClose() {
    _reminderTimer?.cancel();
    super.onClose();
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

      // Solicitar permisos en Android 13+
      if (Platform.isAndroid) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      DebugLog.i('Notifications initialized successfully', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error initializing notifications: $e', category: LogCategory.service);
    }
  }

  /// Crea canales de notificación para Android
  Future<void> _createNotificationChannels() async {
    try {
      // Canal para recordatorios de lectura
      const readingRemindersChannel = AndroidNotificationChannel(
        'reading_reminders',
        'Recordatorios de Lectura',
        description: 'Notificaciones para recordar continuar leyendo documentos',
        importance: Importance.defaultImportance,
      );

      // Canal para recordatorios diarios
      const dailyRemindersChannel = AndroidNotificationChannel(
        'daily_reminders',
        'Recordatorios Diarios',
        description: 'Notificaciones diarias para recordar usar Te Leo',
        importance: Importance.defaultImportance,
      );

      // Canal para notificaciones premium
      const premiumChannel = AndroidNotificationChannel(
        'premium_notifications',
        'Notificaciones Premium',
        description: 'Notificaciones para invitar a hacerse premium',
        importance: Importance.defaultImportance,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(readingRemindersChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(dailyRemindersChannel);

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(premiumChannel);

      DebugLog.d('Notification channels created', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error creating notification channels: $e', category: LogCategory.service);
    }
  }

  /// Maneja el tap en notificaciones
  void _onNotificationTapped(NotificationResponse response) {
    DebugLog.d('Notification tapped: ${response.payload}', category: LogCategory.service);

    if (response.payload != null) {
      try {
        final payload = response.payload!;

        // Manejar diferentes tipos de payloads
        if (payload.startsWith('premium:')) {
          // Abrir pantalla de premium
          Get.toNamed('/premium');
        } else if (payload == 'scan_reminder') {
          // Abrir pantalla principal para escanear
          Get.toNamed('/home');
        } else if (payload == 'daily_reminder') {
          // Abrir pantalla principal
          Get.toNamed('/home');
        } else {
          // Es un ID de documento
          final documentId = int.parse(payload);
          _openDocumentFromNotification(documentId);
        }
      } catch (e) {
        DebugLog.e('Error handling notification tap: $e', category: LogCategory.service);
      }
    }
  }

  /// Abre documento desde notificación y reanuda lectura
  void _openDocumentFromNotification(int documentId) async {
    try {
      final documento = await _databaseProvider.obtenerDocumentoPorId(documentId);
      if (documento != null) {
        // Verificar si hay progreso guardado
        final progreso = await _databaseProvider.obtenerProgresoLectura(documentId);

        DebugLog.i('Opening document from notification: ${documento.titulo}', category: LogCategory.navigation);

        if (progreso != null && progreso.porcentajeProgreso > 0.05) {
          // Mostrar diálogo para reanudar o reiniciar
          DebugLog.d(
            'Found saved progress: ${(progreso.porcentajeProgreso * 100).toStringAsFixed(1)}%',
            category: LogCategory.navigation,
          );

          Get.toNamed(
            AppRoutes.documentReader,
            arguments: {'documento': documento, 'resumeFromProgress': true, 'savedProgress': progreso},
          );
        } else {
          // Abrir desde el principio
          Get.toNamed(AppRoutes.documentReader, arguments: {'documento': documento, 'resumeFromProgress': false});
        }

        DebugLog.i('Navigated to document reader from notification', category: LogCategory.navigation);
      } else {
        DebugLog.w('Document not found for notification: ID $documentId', category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error opening document from notification: $e', category: LogCategory.service);
    }
  }

  /// Carga configuraciones desde SharedPreferences
  Future<void> _loadSettings() async {
    try {
      _isEnabled.value = _storage.read<bool>(_reminderEnabledKey) ?? true;
      _reminderIntervalHours.value = _storage.read<int>(_reminderIntervalKey) ?? 24;

      DebugLog.d(
        'Reminder settings loaded: enabled=${_isEnabled.value}, interval=${_reminderIntervalHours.value}h',
        category: LogCategory.service,
      );
    } catch (e) {
      DebugLog.e('Error loading reminder settings: $e', category: LogCategory.service);
    }
  }

  /// Guarda configuraciones
  Future<void> _saveSettings() async {
    try {
      await _storage.write(_reminderEnabledKey, _isEnabled.value);
      await _storage.write(_reminderIntervalKey, _reminderIntervalHours.value);

      DebugLog.d('Reminder settings saved', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error saving reminder settings: $e', category: LogCategory.service);
    }
  }

  /// Inicia el timer de recordatorios
  void _startReminderTimer() {
    _reminderTimer?.cancel();

    if (!_isEnabled.value) return;

    // Verificar cada hora si hay que enviar recordatorios
    _reminderTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAndSendReminders();
    });

    // Verificar inmediatamente al iniciar
    _checkAndSendReminders();

    DebugLog.d('Reminder timer started', category: LogCategory.service);
  }

  /// Verifica y envía recordatorios si es necesario
  Future<void> _checkAndSendReminders() async {
    if (!_isEnabled.value) return;

    try {
      final lastReminderTimestamp = _storage.read<int>(_lastReminderKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastReminder = (now - lastReminderTimestamp) / (1000 * 60 * 60);

      // Verificar si han pasado las horas configuradas
      if (hoursSinceLastReminder >= _reminderIntervalHours.value) {
        await _sendDynamicReminders();
        await _storage.write(_lastReminderKey, now);
      }
    } catch (e) {
      DebugLog.e('Error checking reminders: $e', category: LogCategory.service);
    }
  }

  /// Envía recordatorios dinámicos basados en el estado del usuario
  Future<void> _sendDynamicReminders() async {
    try {
      final isPremium = _isPremiumUser();

      // Usuario premium no recibe notificaciones promocionales
      if (isPremium) {
        DebugLog.d('Premium user - no promotional notifications', category: LogCategory.notification);
        return;
      }

      // Verificar documentos incompletos
      final incompleteDocuments = await _getIncompleteDocuments();

      if (incompleteDocuments.isNotEmpty) {
        // Hay documentos incompletos - enviar recordatorios de lectura
        await _handleIncompleteDocumentsReminders(incompleteDocuments);
      } else {
        // No hay documentos incompletos - enviar notificaciones premium
        await _handleNoIncompleteDocumentsReminders();
      }
    } catch (e) {
      DebugLog.e('Error sending dynamic reminders: $e', category: LogCategory.service);
    }
  }

  /// Obtiene la lista de documentos incompletos
  Future<List<Documento>> _getIncompleteDocuments() async {
    try {
      final documentos = await _databaseProvider.obtenerTodosLosDocumentos();
      final incompletos = <Documento>[];

      for (final doc in documentos) {
        if (doc.id != null) {
          final progreso = await _databaseProvider.obtenerProgresoLectura(doc.id!);
          if (progreso != null && progreso.porcentajeProgreso > 0.05 && progreso.porcentajeProgreso < 1.0) {
            incompletos.add(doc);
          }
        }
      }

      return incompletos;
    } catch (e) {
      DebugLog.e('Error getting incomplete documents: $e', category: LogCategory.service);
      return [];
    }
  }

  /// Maneja recordatorios para documentos incompletos
  /// Primera notificación: al 1er día (24 horas)
  /// Después: cada 1 hora
  Future<void> _handleIncompleteDocumentsReminders(List<Documento> documents) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final doc in documents) {
        final docId = doc.id;
        if (docId == null) continue;

        final key = '$_firstIncompleteDetectedKey$docId';
        final firstDetected = _storage.read<int>(key);

        if (firstDetected == null) {
          // Primera vez que detectamos este documento incompleto
          await _storage.write(key, now);
          DebugLog.d('First time detecting incomplete document: ${doc.titulo}', category: LogCategory.notification);
          continue;
        }

        final hoursSinceDetected = (now - firstDetected) / (1000 * 60 * 60);

        if (hoursSinceDetected >= 24) {
          // Ya pasaron 24 horas - enviar notificación cada hora
          final lastReminderKey = '${_lastReminderKey}_$docId';
          final lastReminder = _storage.read<int>(lastReminderKey) ?? 0;
          final hoursSinceLastReminder = (now - lastReminder) / (1000 * 60 * 60);

          if (hoursSinceLastReminder >= 1) {
            // Enviar notificación
            await _sendIncompleteDocumentNotification(doc, isFirstNotification: false);
            await _storage.write(lastReminderKey, now);
            DebugLog.i('Sent hourly reminder for: ${doc.titulo}', category: LogCategory.notification);
          }
        } else if (hoursSinceDetected >= 24 && hoursSinceDetected < 25) {
          // Primera notificación al llegar a las 24 horas
          await _sendIncompleteDocumentNotification(doc, isFirstNotification: true);
          final lastReminderKey = '${_lastReminderKey}_$docId';
          await _storage.write(lastReminderKey, now);
          DebugLog.i('Sent first 24h reminder for: ${doc.titulo}', category: LogCategory.notification);
        }
      }
    } catch (e) {
      DebugLog.e('Error handling incomplete documents reminders: $e', category: LogCategory.service);
    }
  }

  /// Maneja recordatorios cuando no hay documentos incompletos
  /// Envía notificaciones de premium y motivacionales
  Future<void> _handleNoIncompleteDocumentsReminders() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Verificar última notificación de premium
      final lastPremiumReminder = _storage.read<int>(_lastPremiumReminderKey) ?? 0;
      final hoursSinceLastPremium = (now - lastPremiumReminder) / (1000 * 60 * 60);

      // Enviar notificación de premium cada 24 horas
      if (hoursSinceLastPremium >= 24) {
        // Alternar entre diferentes tipos de notificaciones premium
        final notificationType = (now ~/ (1000 * 60 * 60 * 24)) % 3;

        switch (notificationType) {
          case 0:
            await _sendPremiumUpgradeNotification();
            break;
          case 1:
            await _sendAvoidAdsNotification();
            break;
          case 2:
            await _sendAllDonePremiumNotification();
            break;
        }

        await _storage.write(_lastPremiumReminderKey, now);
      }

      // Verificar si escaneó hoy
      final hasScannedToday = await _hasScannedToday();
      if (!hasScannedToday && hoursSinceLastPremium >= 12) {
        await _sendNoScanTodayNotification();
      }
    } catch (e) {
      DebugLog.e('Error handling no incomplete documents reminders: $e', category: LogCategory.service);
    }
  }

  /// Verifica si el usuario escaneó hoy
  Future<bool> _hasScannedToday() async {
    try {
      final lastScanString = _storage.read<String>(_lastScanDateKey);

      if (lastScanString == null) return false;

      final lastScan = DateTime.tryParse(lastScanString);
      if (lastScan == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastScanDay = DateTime(lastScan.year, lastScan.month, lastScan.day);

      return today.isAtSameMomentAs(lastScanDay);
    } catch (e) {
      DebugLog.e('Error checking scan today: $e', category: LogCategory.service);
      return false;
    }
  }

  /// Actualiza la fecha del último escaneo
  Future<void> updateLastScanDate() async {
    try {
      await _storage.write(_lastScanDateKey, DateTime.now().toIso8601String());
      DebugLog.d('Last scan date updated', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error updating last scan date: $e', category: LogCategory.service);
    }
  }

  /// Limpia el tracking de notificaciones de un documento cuando se completa
  Future<void> clearDocumentTracking(int documentId) async {
    try {
      final key = '$_firstIncompleteDetectedKey$documentId';
      final lastReminderKey = '${_lastReminderKey}_$documentId';

      await _storage.remove(key);
      await _storage.remove(lastReminderKey);

      DebugLog.d('Cleared notification tracking for document: $documentId', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error clearing document tracking: $e', category: LogCategory.service);
    }
  }

  /// Envía notificación de documento incompleto
  Future<void> _sendIncompleteDocumentNotification(Documento doc, {required bool isFirstNotification}) async {
    try {
      final title = isFirstNotification ? 'first_incomplete_title'.tr : 'reading_reminder_single_title'.tr;
      final body = isFirstNotification
          ? 'first_incomplete_body'.trParams({'document': doc.titulo})
          : 'reading_reminder_single_body'.trParams({'document': doc.titulo});

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Recordatorios de Lectura',
          channelDescription: 'Notificaciones para recordar continuar leyendo documentos',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        doc.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: doc.id?.toString(),
      );

      DebugLog.i('Incomplete document notification sent for: ${doc.titulo}', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending incomplete document notification: $e', category: LogCategory.notification);
    }
  }

  /// Envía notificación de upgrade a premium
  Future<void> _sendPremiumUpgradeNotification() async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'premium_notifications',
          'Notificaciones Premium',
          channelDescription: 'Notificaciones para invitar a hacerse premium',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'upgrade_premium_title'.tr,
        'upgrade_premium_body'.tr,
        notificationDetails,
        payload: 'premium:upgrade',
      );

      DebugLog.i('Premium upgrade notification sent', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending premium upgrade notification: $e', category: LogCategory.notification);
    }
  }

  /// Envía notificación de evitar anuncios
  Future<void> _sendAvoidAdsNotification() async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'premium_notifications',
          'Notificaciones Premium',
          channelDescription: 'Notificaciones para invitar a hacerse premium',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'avoid_ads_title'.tr,
        'avoid_ads_body'.tr,
        notificationDetails,
        payload: 'premium:avoid_ads',
      );

      DebugLog.i('Avoid ads notification sent', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending avoid ads notification: $e', category: LogCategory.notification);
    }
  }

  /// Envía notificación de todo al día con premium
  Future<void> _sendAllDonePremiumNotification() async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'premium_notifications',
          'Notificaciones Premium',
          channelDescription: 'Notificaciones para invitar a hacerse premium',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'all_done_premium_title'.tr,
        'all_done_premium_body'.tr,
        notificationDetails,
        payload: 'premium:all_done',
      );

      DebugLog.i('All done premium notification sent', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending all done premium notification: $e', category: LogCategory.notification);
    }
  }

  /// Envía notificación de que no escaneó hoy
  Future<void> _sendNoScanTodayNotification() async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Recordatorios Diarios',
          channelDescription: 'Notificaciones diarias para recordar usar Te Leo',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'no_scan_today_title'.tr,
        'no_scan_today_body'.tr,
        notificationDetails,
        payload: 'scan_reminder',
      );

      DebugLog.i('No scan today notification sent', category: LogCategory.notification);
    } catch (e) {
      DebugLog.e('Error sending no scan today notification: $e', category: LogCategory.notification);
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

  /// Actualiza configuración de recordatorios
  Future<void> updateReminderSettings({bool? enabled, int? intervalHours}) async {
    if (enabled != null) {
      _isEnabled.value = enabled;
    }

    if (intervalHours != null && intervalHours > 0) {
      _reminderIntervalHours.value = intervalHours;
    }

    await _saveSettings();

    // Reiniciar timer con nueva configuración
    _startReminderTimer();

    DebugLog.i(
      'Reminder settings updated: enabled=${_isEnabled.value}, interval=${_reminderIntervalHours.value}h',
      category: LogCategory.service,
    );
  }

  /// Cancela todas las notificaciones pendientes
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      DebugLog.i('All reminder notifications cancelled', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error cancelling notifications: $e', category: LogCategory.service);
    }
  }

  /// Actualiza la fecha de último uso de la app
  Future<void> updateLastUsageDate() async {
    try {
      await _storage.write('last_usage_date', DateTime.now().toIso8601String());
      DebugLog.d('Last usage date updated', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error updating last usage date: $e', category: LogCategory.service);
    }
  }

  /// Envía notificación de prueba
  Future<void> sendTestNotification() async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Recordatorios de Lectura',
          channelDescription: 'Notificaciones para recordar continuar leyendo documentos',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        999999,
        'test_notification_title'.tr,
        'test_notification_body'.tr,
        notificationDetails,
      );

      DebugLog.i('Test notification sent', category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error sending test notification: $e', category: LogCategory.service);
    }
  }
}
