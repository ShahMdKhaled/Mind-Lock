import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notifications.initialize(initializationSettings);
    _isInitialized = true;
  }

  Future<void> showStudyModeNotification() async {
    await init();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.notifChannelStudy,
      'Study Mode',
      channelDescription: 'Active while you focus',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      AppConstants.notifStudyModeId,
      'Study Mode Active',
      'Notifications are muted. Stay focused!',
      platformDetails,
    );
  }

  Future<void> cancelStudyModeNotification() async {
    await _notifications.cancel(AppConstants.notifStudyModeId);
  }

  Future<void> showBreakNotification(int seconds) async {
    await init();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.notifChannelBreak,
      'Break Time',
      channelDescription: 'Time for a break',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      AppConstants.notifBreakId,
      'Time for a Break!',
      'Take $seconds seconds to relax your eyes.',
      platformDetails,
    );
  }
}
