import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../networking/api_client.dart';
import 'notification_service.dart';

/// Entry-point function for processing FCM push notifications when the
/// app is in the background or completely closed (terminated state).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final data = message.data;
  final type = data['type']?.toString();
  
  if (type == 'call' || type == 'call_invite') {
    final callId = data['callId']?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
    final callerName = data['callerUsername']?.toString() ?? data['callerName']?.toString() ?? '@peer';
    final callType = data['callType']?.toString() ?? 'audio';
    final senderId = data['senderId']?.toString() ?? '';

    await NotificationService().showIncomingCallNotification(
      callId: callId,
      callerName: callerName,
      callType: callType,
      senderId: senderId,
    );
  } else if (type == 'chat') {
    final senderName = data['senderName']?.toString() ?? 'Someone';
    final messageText = data['messageText']?.toString() ?? 'Sent you an encrypted message';
    final conversationId = data['conversationId']?.toString() ?? '';

    await NotificationService().showMessageNotification(
      senderName: senderName,
      messageText: messageText,
      conversationId: conversationId,
    );
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request FCM permissions (Notification banner + Sound + Critical Alert)
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // Set foreground notification options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Obtain FCM token
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('[FCM] Token obtained: $_fcmToken');
        await registerFcmTokenWithBackend(_fcmToken!);
      }

      // Listen to token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await registerFcmTokenWithBackend(newToken);
      });

      // Foreground FCM message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final data = message.data;
        final type = data['type']?.toString();

        if (type == 'call' || type == 'call_invite') {
          NotificationService().showIncomingCallNotification(
            callId: data['callId']?.toString() ?? '',
            callerName: data['callerUsername']?.toString() ?? data['callerName']?.toString() ?? '@peer',
            callType: data['callType']?.toString() ?? 'audio',
            senderId: data['senderId']?.toString() ?? '',
          );
        } else if (type == 'chat') {
          NotificationService().showMessageNotification(
            senderName: data['senderName']?.toString() ?? 'Someone',
            messageText: data['messageText']?.toString() ?? 'Sent you a message',
            conversationId: data['conversationId']?.toString() ?? '',
          );
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[FCM] Push Notification Service initialization deferred: $e');
    }
  }

  /// Register user device FCM Token with backend for closed-app call notifications
  Future<void> registerFcmTokenWithBackend(String token) async {
    try {
      await ApiClient.post('/users/fcm-token', {
        'fcmToken': token,
      });
    } catch (_) {}
  }
}
