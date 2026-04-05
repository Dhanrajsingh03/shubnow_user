import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

// 🔥 Niche wale imports apne folder structure ke hisaab se check kar lena
import '../../core/dio_client.dart';
import 'notification_model.dart';
import '../../core/app_router.dart'; // Yahan NavigatorKey wala router hona chahiye

class NotificationService {
  // ==========================================================================
  // 🏗️ 1. SINGLETON PATTERN (Memory Efficient - Only one instance runs)
  // ==========================================================================
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String _baseRoute = '/notifications';

  // ==========================================================================
  // 📱 2. INIT & TOKEN GENERATION (Provider ya main.dart call karega)
  // ==========================================================================
  Future<void> generateAndSendFCMToken() async {
    try {
      // ✅ A. Request Permissions (Crucial for iOS & Android 13+)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("❌ User denied notification permissions.");
        return;
      }

      // ✅ B. Fetch FCM Token
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        debugPrint("🔥 FCM TOKEN GENERATED: $fcmToken");
        await _sendTokenToBackend(fcmToken);
      }

      // ✅ C. Listen to Token Refreshes (Agar token expire hoke naya bane)
      _messaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

      // ✅ D. Setup Deep-Linking / Tap Handlers
      _setupNotificationClickHandlers();

    } catch (e) {
      debugPrint("❌ Notification Initialization Error: $e");
    }
  }

  // ==========================================================================
  // 🎯 3. DEEP LINKING (Handling Notification Taps Like a Pro)
  // ==========================================================================
  void _setupNotificationClickHandlers() async {
    // Scenario 1: App was completely closed (Terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageClick(initialMessage);
    }

    // Scenario 2: App was in Background (Minimized)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageClick(message);
    });

    // Scenario 3: App is in Foreground (Active)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📥 Foreground Notification Received: ${message.notification?.title}");
      // Note: No auto-routing here so we don't interrupt the user's current task.
    });
  }

  // 🧠 THE BRAIN: Routing logic based on payload 'type'
  void _handleMessageClick(RemoteMessage message) {
    debugPrint("🔔 Notification Tapped! Payload: ${message.data}");

    final String? type = message.data['type'];
    if (type == null) return;

    // Fetch context globally without needing to pass it through functions
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) {
      debugPrint("⚠️ Navigator Context is null. Cannot route.");
      return;
    }

    // 🚦 Route Switcher
    switch (type) {
      case 'BOOKING_ACCEPTED':
      case 'BOOKING_ALERT':
      case 'BOOKING_COMPLETED':
        context.pushNamed('my-bookings');
        break;
      case 'SYSTEM_ALERT':
        context.pushNamed('notifications');
        break;
      case 'PROMO_ALERT':
        context.goNamed('home');
        break;
      default:
        context.goNamed('home');
    }
  }

  // ==========================================================================
  // 🌐 4. SYNC TOKEN WITH NODE.JS
  // ==========================================================================
  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final response = await DioClient.instance.patch(
          '/users/update-fcm', // Make sure this matches your backend route
          data: {'fcmToken': fcmToken}
      );
      if (response.statusCode == 200) {
        debugPrint("✅ FCM Token Synced with Backend.");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint("⚠️ Unauthorized: Token will sync automatically after login.");
      } else {
        debugPrint("❌ Backend Sync Error: ${e.message}");
      }
    } catch (e) {
      debugPrint("❌ Unknown Token Sync Error: $e");
    }
  }

  // ==========================================================================
  // 📥 5. FETCH HISTORY (For your Provider)
  // ==========================================================================
  Future<List<AppNotification>> fetchNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await DioClient.instance.get(
          _baseRoute,
          queryParameters: {'page': page, 'limit': limit}
      );

      if (response.statusCode == 200) {
        final List notificationsData = response.data['data']['notifications'] ?? [];
        return notificationsData.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Fetch History Error: $e");
      throw Exception("Failed to load notifications. Check your connection.");
    }
  }

  // ==========================================================================
  // 🔴 6. UNREAD COUNT (For Bell Badge)
  // ==========================================================================
  Future<int> getUnreadCount() async {
    try {
      final response = await DioClient.instance.get('$_baseRoute/unread-count');
      if (response.statusCode == 200) {
        return response.data['data']['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint("❌ Unread Count Error: $e");
      return 0; // Return 0 gracefully so UI doesn't crash
    }
  }

  // ==========================================================================
  // 👁️ 7. MARK READ & DELETE ACTIONS (Fully Populated)
  // ==========================================================================

  // 🟢 Single Read
  Future<void> markAsRead(String notificationId) async {
    try {
      await DioClient.instance.patch('$_baseRoute/$notificationId/read');
      debugPrint("✅ Notification $notificationId marked as read");
    } catch (e) {
      debugPrint("❌ markAsRead Error: $e");
    }
  }

  // 🟢 Mark All As Read
  Future<void> markAllAsRead() async {
    try {
      final response = await DioClient.instance.patch('$_baseRoute/mark-all-read');
      if (response.statusCode == 200) {
        debugPrint("✅ All notifications marked as read");
      }
    } catch (e) {
      debugPrint("❌ markAllAsRead Error: $e");
      throw Exception("Failed to mark all as read");
    }
  }

  // 🗑️ Delete Single Notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await DioClient.instance.delete('$_baseRoute/$notificationId');
      debugPrint("✅ Notification $notificationId Deleted");
    } catch (e) {
      debugPrint("❌ deleteNotification Error: $e");
      throw Exception("Failed to delete notification");
    }
  }

  // 🧨 Delete All (Clear History)
  Future<void> deleteAllNotifications() async {
    try {
      await DioClient.instance.delete(_baseRoute);
      debugPrint("✅ All Notifications History Cleared");
    } catch (e) {
      debugPrint("❌ deleteAll Error: $e");
      throw Exception("Failed to clear notification history");
    }
  }
}