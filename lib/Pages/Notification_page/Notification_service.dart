import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

import '../../core/dio_client.dart';
import 'notification_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 🚀 Base route centralized kar diya hai taaki future me change karna ho toh ek jagah se ho
  final String _baseRoute = '/notifications';

  // ==========================================
  // 📱 1. GENERATE & SEND FCM TOKEN TO NODE.JS
  // ==========================================
  Future<void> generateAndSendFCMToken() async {
    try {
      // iOS permissions
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Generate Firebase Token
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _sendTokenToBackend(fcmToken);
      }

      // Background token refresh listener
      _messaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      print("❌ FCM Initialization Error: $e");
    }
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final response = await DioClient.instance.patch(
        '/users/update-fcm', // Pandit app mein isko '/pandit/update-fcm' kar dena
        data: {'fcmToken': fcmToken},
      );

      if (response.statusCode == 200) {
        print("✅ FCM Token Synced with Backend via Dio!");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print("⚠️ User not logged in yet. FCM token will be sent after login.");
      } else {
        print("❌ Backend rejected FCM token: ${e.message}");
      }
    } catch (e) {
      print("❌ API Token Sync Error: $e");
    }
  }

  // ==========================================
  // 📥 2. FETCH HISTORY FROM NODE.JS (With Filters)
  // ==========================================
  Future<List<AppNotification>> fetchNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead, // Optional filter for unread only
    String? type, // Optional filter by type (PROMO_ALERT, SYSTEM_ALERT)
  }) async {
    try {
      // Dynamic Query Parameters
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (isRead != null) queryParams['isRead'] = isRead;
      if (type != null) queryParams['type'] = type;

      final response = await DioClient.instance.get(
        _baseRoute,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        List notificationsData = response.data['data']['notifications'];
        return notificationsData.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load notifications");
      }
    } on DioException catch (e) {
      print("❌ Fetch Notifications Dio Error: ${e.message}");
      final errorMessage = e.response?.data['message'] ?? "Please check your internet connection.";
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ Unknown Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 🔴 3. GET UNREAD COUNT (For Bell Badge)
  // ==========================================
  Future<int> getUnreadCount() async {
    try {
      final response = await DioClient.instance.get('$_baseRoute/unread-count');

      if (response.statusCode == 200) {
        return response.data['data']['unreadCount'] ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      print("❌ Fetch Unread Count Error: ${e.message}");
      return 0; // Returning 0 gracefully so UI doesn't crash
    }
  }

  // ==========================================
  // 👁️ 4. MARK SINGLE NOTIFICATION AS READ (The CTR Tracker)
  // ==========================================
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await DioClient.instance.patch('$_baseRoute/$notificationId/read');

      if (response.statusCode == 200) {
        print("✅ Notification $notificationId marked as read");
      }
    } on DioException catch (e) {
      print("❌ Mark as read failed: ${e.message}");
      throw Exception(e.response?.data['message'] ?? "Failed to mark as read");
    }
  }

  // ==========================================
  // 👁️‍🗨️ 5. MARK ALL AS READ (Clear Badges)
  // ==========================================
  Future<void> markAllAsRead() async {
    try {
      final response = await DioClient.instance.patch('$_baseRoute/mark-all-read');

      if (response.statusCode == 200) {
        print("✅ All notifications marked as read");
      }
    } on DioException catch (e) {
      print("❌ Mark all as read failed: ${e.message}");
      throw Exception(e.response?.data['message'] ?? "Failed to mark all as read");
    }
  }

  // ==========================================
  // 🗑️ 6. DELETE SINGLE NOTIFICATION
  // ==========================================
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await DioClient.instance.delete('$_baseRoute/$notificationId');

      if (response.statusCode == 200) {
        print("✅ Notification $notificationId deleted");
      }
    } on DioException catch (e) {
      print("❌ Delete notification failed: ${e.message}");
      throw Exception(e.response?.data['message'] ?? "Failed to delete notification");
    }
  }

  // ==========================================
  // 🧨 7. DELETE ALL NOTIFICATIONS (Clear History)
  // ==========================================
  Future<void> deleteAllNotifications() async {
    try {
      final response = await DioClient.instance.delete(_baseRoute);

      if (response.statusCode == 200) {
        print("✅ All notifications deleted successfully");
      }
    } on DioException catch (e) {
      print("❌ Delete all notifications failed: ${e.message}");
      throw Exception(e.response?.data['message'] ?? "Failed to clear notifications");
    }
  }
}