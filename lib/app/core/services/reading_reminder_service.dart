import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'debug_console_service.dart';
import '../../data/models/documento.dart';
import '../../data/providers/database_provider.dart';
import '../../routes/app_routes.dart';

/// Servicio para gestionar recordatorios de lectura mediante notificaciones push
/// Envía notificaciones cuando el usuario no ha terminado de leer un documento
class ReadingReminderService extends GetxService {
  static const String _reminderEnabledKey = 'reading_reminders_enabled';
  static const String _reminderIntervalKey = 'reading_reminder_interval_hours';
  static const String _lastReminderKey = 'last_reminder_timestamp';
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final DatabaseProvider _databaseProvider = DatabaseProvider();
  
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
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
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
  
  /// Maneja el tap en notificaciones
  void _onNotificationTapped(NotificationResponse response) {
    DebugLog.d('Notification tapped: ${response.payload}', category: LogCategory.service);
    
    if (response.payload != null) {
      try {
        final documentId = int.parse(response.payload!);
        _openDocumentFromNotification(documentId);
      } catch (e) {
        DebugLog.e('Error parsing notification payload: $e', category: LogCategory.service);
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
          DebugLog.d('Found saved progress: ${(progreso.porcentajeProgreso * 100).toStringAsFixed(1)}%', 
                    category: LogCategory.navigation);
          
          Get.toNamed(AppRoutes.documentReader, arguments: {
            'documento': documento,
            'resumeFromProgress': true,
            'savedProgress': progreso,
          });
        } else {
          // Abrir desde el principio
          Get.toNamed(AppRoutes.documentReader, arguments: {
            'documento': documento,
            'resumeFromProgress': false,
          });
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
      final prefs = await SharedPreferences.getInstance();
      _isEnabled.value = prefs.getBool(_reminderEnabledKey) ?? true;
      _reminderIntervalHours.value = prefs.getInt(_reminderIntervalKey) ?? 24;
      
      DebugLog.d('Reminder settings loaded: enabled=${_isEnabled.value}, interval=${_reminderIntervalHours.value}h', 
                category: LogCategory.service);
    } catch (e) {
      DebugLog.e('Error loading reminder settings: $e', category: LogCategory.service);
    }
  }
  
  /// Guarda configuraciones
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, _isEnabled.value);
      await prefs.setInt(_reminderIntervalKey, _reminderIntervalHours.value);
      
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
      final prefs = await SharedPreferences.getInstance();
      final lastReminderTimestamp = prefs.getInt(_lastReminderKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastReminder = (now - lastReminderTimestamp) / (1000 * 60 * 60);
      
      if (hoursSinceLastReminder >= _reminderIntervalHours.value) {
        await _sendRemindersForIncompleteDocuments();
        await prefs.setInt(_lastReminderKey, now);
      }
    } catch (e) {
      DebugLog.e('Error checking reminders: $e', category: LogCategory.service);
    }
  }
  
  /// Envía recordatorios para documentos incompletos
  Future<void> _sendRemindersForIncompleteDocuments() async {
    try {
      final documentos = await _databaseProvider.obtenerTodosLosDocumentos();
      final incompletos = <Documento>[];
      
      for (final doc in documentos) {
        if (doc.id != null) {
          final progreso = await _databaseProvider.obtenerProgresoLectura(doc.id!);
          if (progreso != null && progreso.porcentajeProgreso < 1.0) {
            incompletos.add(doc);
          }
        }
      }
      
      if (incompletos.isNotEmpty) {
        await _sendReminderNotification(incompletos);
        DebugLog.i('Sent reminder for ${incompletos.length} incomplete documents', 
                  category: LogCategory.service);
      }
    } catch (e) {
      DebugLog.e('Error sending reminders: $e', category: LogCategory.service);
    }
  }
  
  /// Envía notificación de recordatorio
  Future<void> _sendReminderNotification(List<Documento> documentos) async {
    try {
      String title, body;
      String? payload;
      
      if (documentos.length == 1) {
        final doc = documentos.first;
        title = 'reading_reminder_single_title'.tr;
        body = 'reading_reminder_single_body'.trParams({'document': doc.titulo});
        payload = doc.id?.toString();
      } else {
        title = 'reading_reminder_multiple_title'.tr;
        body = 'reading_reminder_multiple_body'.trParams({'count': documentos.length.toString()});
      }
      
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Recordatorios de Lectura',
          channelDescription: 'Notificaciones para recordar continuar leyendo documentos',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
    } catch (e) {
      DebugLog.e('Error showing reminder notification: $e', category: LogCategory.service);
    }
  }
  
  /// Actualiza configuración de recordatorios
  Future<void> updateReminderSettings({
    bool? enabled,
    int? intervalHours,
  }) async {
    if (enabled != null) {
      _isEnabled.value = enabled;
    }
    
    if (intervalHours != null && intervalHours > 0) {
      _reminderIntervalHours.value = intervalHours;
    }
    
    await _saveSettings();
    
    // Reiniciar timer con nueva configuración
    _startReminderTimer();
    
    DebugLog.i('Reminder settings updated: enabled=${_isEnabled.value}, interval=${_reminderIntervalHours.value}h', 
              category: LogCategory.service);
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
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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
