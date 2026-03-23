import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

import '../../core/dio_client.dart';
import 'notification_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ==========================================
  // 📱 1. GENERATE & SEND FCM TOKEN TO NODE.JS
  // ==========================================
  Future<void> generateAndSendFCMToken() async {
    try {
      // Permission maango (iOS ke liye zaroori hai)
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Firebase se Token generate karo
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _sendTokenToBackend(fcmToken);
      }

      // Agar Firebase background me naya token banata hai toh backend ko update karo
      _messaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      print("❌ FCM Initialization Error: $e");
    }
  }

  // 🚀 DIO MAGIC: Yahan koi token fetch ya header set karne ki zaroorat nahi hai.
  // Tera AuthInterceptor khud ba khud SecureStorage se token nikal kar laga dega!
  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      // Dhyan de: Sirf '/users/update-fcm' likha hai kyunki baseUrl Dio mein set hai
      final response = await DioClient.instance.patch(
        '/users/update-fcm', // Pandit app mein isko '/pandit/update-fcm' kar dena
        data: {'fcmToken': fcmToken},
      );

      if (response.statusCode == 200) {
        print("✅ FCM Token Synced with Backend via Dio!");
      }
    } on DioException catch (e) {
      // Agar user logged in nahi hai (401), toh error silently catch ho jayega
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
  // 📥 2. FETCH HISTORY FROM NODE.JS
  // ==========================================
  Future<List<AppNotification>> fetchNotifications({int page = 1}) async {
    try {
      // DioClient Automatically Auth Token aur Timeout handle karega
      final response = await DioClient.instance.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': 20,
        },
      );

      if (response.statusCode == 200) {
        // Dio automatically JSON ko decode kar deta hai, isliye jsonDecode() ki zaroorat nahi!
        List notificationsData = response.data['data']['notifications'];
        return notificationsData.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load notifications");
      }
    } on DioException catch (e) {
      print("❌ Fetch Notifications Dio Error: ${e.message}");
      // Agar backend se koi error message aaya hai toh wo dikhao, warna default message
      final errorMessage = e.response?.data['message'] ?? "Please check your internet connection.";
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ Unknown Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 👁️ 3. MARK NOTIFICATION AS READ
  // ==========================================
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await DioClient.instance.patch(
        '/notifications/$notificationId/read',
      );

      if (response.statusCode == 200) {
        print("✅ Notification $notificationId marked as read");
      }
    } on DioException catch (e) {
      print("❌ Mark as read failed: ${e.message}");
    }
  }
}