import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Function(Map<String, dynamic> payload)? _onNotificationSelected;

  Future<void> initialize({Function(Map<String, dynamic> payload)? onNotificationSelected}) async {
    if (_isInitialized) return;
    _onNotificationSelected = onNotificationSelected;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _onNotificationSelected?.call(data);
          } catch (_) {}
        }
      },
    );

    // Request permissions for Android 13+ (API level 33+)
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// Display a heads-up banner notification for a new message
  Future<void> showMessageNotification({
    int id = 100,
    required String senderName,
    required String messageText,
    required String conversationId,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ourspace_messages_channel',
      'Message Notifications',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        messageText,
        contentTitle: 'Message from $senderName',
        summaryText: 'New Message',
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = jsonEncode({
      'type': 'chat',
      'conversationId': conversationId,
      'senderName': senderName,
    });

    await _flutterLocalNotificationsPlugin.show(
      id,
      'Message from $senderName',
      messageText,
      platformDetails,
      payload: payload,
    );
  }

  /// Display a high-priority incoming call notification
  Future<void> showIncomingCallNotification({
    int id = 999,
    required String callId,
    required String callerName,
    required String callType,
    required String senderId,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ourspace_calls_channel',
      'Incoming Call Notifications',
      channelDescription: 'Notifications for incoming voice and video calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      category: AndroidNotificationCategory.call,
      enableVibration: true,
      playSound: true,
      ticker: 'Incoming $callType call from $callerName',
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    final payload = jsonEncode({
      'type': 'call',
      'callId': callId,
      'callerName': callerName,
      'callType': callType,
      'senderId': senderId,
    });

    await _flutterLocalNotificationsPlugin.show(
      id,
      'Incoming ${callType.toUpperCase()} Call',
      '$callerName is calling...',
      platformDetails,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all active notifications
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
