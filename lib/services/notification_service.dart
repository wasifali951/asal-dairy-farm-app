import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static String? _tokenRefreshUserId;

  static Future<String?> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    if (!_isInitialized) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'asal_dairy_channel',
        'Asal Dairy Notifications',
        description: 'Notifications for Asal Dairy orders and offers',
        importance: Importance.high,
        sound: UriAndroidNotificationSound('default'),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          print('Notification tapped: ${details.payload}');
        },
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification opened app: ${message.notification?.title}');
      });
      _isInitialized = true;
    }

    return token;
  }

  static Future<void> saveFCMToken(String userId, String? token) async {
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }

    if (_tokenRefreshUserId != userId) {
      _tokenRefreshUserId = userId;
      _messaging.onTokenRefresh.listen((refreshedToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': refreshedToken});
      });
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'asal_dairy_channel',
      'Asal Dairy Notifications',
      channelDescription: 'Notifications for Asal Dairy app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: UriAndroidNotificationSound('default'),
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }

  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('In-app notification created for user: $userId');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> sendBulkNotification({
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? data,
  }) async {
    try {
      QuerySnapshot usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      for (var doc in usersQuery.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        Map<String, dynamic>? prefs =
            userData['notificationPrefs'] as Map<String, dynamic>?;

        bool shouldSend = false;
        if (notificationType == 'promotional' &&
            (prefs?['promotionalOffers'] ?? true)) {
          shouldSend = true;
        } else if (notificationType == 'newProduct' &&
            (prefs?['newProducts'] ?? true)) {
          shouldSend = true;
        }

        if (shouldSend) {
          await sendToUser(
            userId: doc.id,
            title: title,
            body: body,
            data: data,
          );
        }
      }
    } catch (e) {
      print('Error sending bulk notification: $e');
    }
  }

  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  static Stream<int> getUnreadCount(String userId) {
    return getUserNotifications(userId).map(
      (snapshot) => snapshot.docs.where((notification) {
        final data = notification.data() as Map<String, dynamic>;
        return data['read'] != true;
      }).length,
    );
  }

  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}
