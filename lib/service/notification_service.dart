import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    await _pedirPermisos();
    _initialized = true;
  }

  Future<void> _pedirPermisos() async {
    // Android 13+
    await Permission.notification.request();
  }

  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bus_proximity_channel',
      'Alertas de bus cercano',
      channelDescription: 'Notifica cuando un bus está cerca de tu ubicación',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, titulo, cuerpo, details);
  }
}
