import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import '../routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Jalankan logika penyimpanan ringan atau logging lokal di sini jika diperlukan.
  debugPrint('Handling a background message: ${message.messageId}');
}

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref);
});

class PushService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

PushService(this._ref);

String? _initialRoute;
String? get initialRoute => _initialRoute;

Future<void> initialize({required Function(String route) onNavigate}) async {
  await requestPermission();

  await _initLocalNotifications(onNavigate);

  await _setupTokenManagement();

  _setupForegroundListener();
  _setupBackgroundOpenedListener(onNavigate);
  await _setupTerminatedListener(onNavigate);

  await subscribeToTopic('pengumuman-kampus');
}

Future<void> requestPermission() async {
    // iOS: Membutuhkan izin eksplisit dari user lewat FCM requestPermission.
    // Android 13+ (API 33+): Membutuhkan izin POST_NOTIFICATIONS di AndroidManifest.xml
    // serta dialog izin runtime yang dipicu oleh kode di bawah ini.
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

Future<void> _setupTokenManagement() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    _fcm.onTokenRefresh.listen((newToken) async {
      await _sendTokenToBackend(newToken);
    });
  }

Future<void> _sendTokenToBackend(String token) async {
  try {
    final dio = _ref.read(apiClientProvider);
    
    await dio.post(
      '/devices', 
      data: {
        'token': token,
        'device_type': 'flutter_app',
      },
    );
  } catch (_) {
    
  }
}
Future<void> _initLocalNotifications(Function(String route) onNavigate) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Callback saat banner lokal diklik pengguna di mode Foreground
        if (response.payload != null && response.payload!.isNotEmpty) {
          onNavigate(response.payload!);
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'pengumuman_channel',
      'Pengumuman Kampus',
      description: 'Channel untuk pengumuman penting kampus',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      String route = message.data['route'] ?? AppRoutes.home;

      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'pengumuman_channel',
              'Pengumuman Kampus',
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: route,
        );
      }
    });
  }

  void _setupBackgroundOpenedListener(Function(String route) onNavigate) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String? route = message.data['route'];
      if (route != null && route.isNotEmpty) {
        onNavigate(route);
      }
    });
  }

  // TERMINATED: Aplikasi mati total dan dibuka lewat notifikasi
  Future<void> _setupTerminatedListener(Function(String route) onNavigate) async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      String? route = initialMessage.data['route'];
      if (route != null && route.isNotEmpty) {
        _initialRoute = route;
        onNavigate(route);
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}
