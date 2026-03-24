import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🔥 Ensure these imports match your actual file names
import 'notification_service.dart';
import 'notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  // ==========================================
  // 🗄️ STATE VARIABLES
  // ==========================================
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  // ==========================================
  // 👁️ GETTERS (UI inko read karega)
  // ==========================================
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  // ==========================================
  // 🚀 1. INITIALIZE (App khulte hi Home par call karna)
  // ==========================================
  Future<void> initializeAppNotifications() async {
    // 1. Firebase Token nikalo aur backend ko do
    await _service.generateAndSendFCMToken();

    // 2. Fetch accurate unread count from backend (For Badge)
    await fetchUnreadCount();

    // 3. Purani history load karo
    await loadNotifications();

    // 4. App chalte waqt live message sunne ke liye listener on karo
    _setupForegroundListener();
  }

  // ==========================================
  // 📥 2. FETCH HISTORY FROM SERVICE
  // ==========================================
  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    _errorMessage = null;

    try {
      _notifications = await _service.fetchNotifications();
      _calculateLocalUnreadCount(); // Sync local count with fetched list
    } catch (e) {
      print("❌ Provider Error: $e");
      _errorMessage = "Failed to load notifications. Please check your internet connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 🔴 3. FETCH ACCURATE UNREAD COUNT
  // ==========================================
  Future<void> fetchUnreadCount() async {
    _unreadCount = await _service.getUnreadCount();
    notifyListeners();
  }

  // ==========================================
  // 👁️ 4. MARK SINGLE NOTIFICATION AS READ
  // ==========================================
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);

    if (index != -1 && !_notifications[index].isRead) {
      // 🚀 OPTIMISTIC UI: Turant UI update karo
      _notifications[index].isRead = true;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();

      try {
        // Background mein API call
        await _service.markAsRead(id);
      } catch (e) {
        print("❌ Background MarkAsRead failed: $e");
      }
    }
  }

  // ==========================================
  // 👁️‍🗨️ 5. MARK ALL AS READ
  // ==========================================
  Future<void> markAllAsRead() async {
    // 🚀 OPTIMISTIC UI: Saari list ko read mark kardo aur badge hata do
    for (var n in _notifications) {
      n.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await _service.markAllAsRead();
    } catch (e) {
      print("❌ Background MarkAllAsRead failed: $e");
    }
  }

  // ==========================================
  // 🗑️ 6. DELETE SINGLE NOTIFICATION
  // ==========================================
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);

    if (index != -1) {
      // Agar unread tha toh count minus karo
      if (!_notifications[index].isRead && _unreadCount > 0) {
        _unreadCount--;
      }

      // 🚀 OPTIMISTIC UI: List se turant gayab kardo
      _notifications.removeAt(index);
      notifyListeners();

      try {
        await _service.deleteNotification(id);
      } catch (e) {
        print("❌ Background Delete Notification failed: $e");
      }
    }
  }

  // ==========================================
  // 🧨 7. DELETE ALL NOTIFICATIONS
  // ==========================================
  Future<void> deleteAllNotifications() async {
    // 🚀 OPTIMISTIC UI: Pura inbox aur badge clean kardo
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _service.deleteAllNotifications();
    } catch (e) {
      print("❌ Background DeleteAll failed: $e");
    }
  }

  // ==========================================
  // 🧮 8. HELPER: CALCULATE LOCAL UNREAD COUNT
  // ==========================================
  void _calculateLocalUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  // ==========================================
  // 🔔 9. LIVE FOREGROUND LISTENER
  // ==========================================
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Live Foreground Notification Received!");

      // Jab naya message aaye, toh count badha do aur list refresh kardo
      _unreadCount++;
      loadNotifications(isRefresh: true); // Background silenty refresh karega (No loading spinner)
    });
  }
}

// 🚀 RIVERPOD PROVIDER DEFINITION
final notificationControllerProvider = ChangeNotifierProvider<NotificationProvider>((ref) {
  return NotificationProvider();
});