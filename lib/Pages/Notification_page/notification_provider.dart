import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Notification_service.dart';
import 'notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();

  // ==========================================
  // 🗄️ STATE VARIABLES
  // ==========================================
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage; // 🚀 Naya: Error dikhane ke liye
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

    // 2. Purani history load karo
    await loadNotifications();

    // 3. App chalte waqt live message sunne ke liye listener on karo
    _setupForegroundListener();
  }

  // ==========================================
  // 📥 2. FETCH HISTORY FROM SERVICE
  // ==========================================
  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null; // Purane errors clear karo
    notifyListeners();

    try {
      // Service file se (timeout ke sath) data laayega
      _notifications = await _service.fetchNotifications();
      _calculateUnreadCount();

    } catch (e) {
      print("❌ Provider Error: $e");
      // 🚀 Agar network timeout hua toh UI ko pata chalega
      _errorMessage = "Failed to load notifications. Please check your internet connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 👁️ 3. MARK SINGLE NOTIFICATION AS READ
  // ==========================================
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);

    // Agar notification pehle se read nahi hai
    if (index != -1 && !_notifications[index].isRead) {

      // 🚀 OPTIMISTIC UI UPDATE: Backend ka wait kiye bina UI turant change karo
      // Isse app ekdum "butter smooth" lagti hai lag-free!
      _notifications[index].isRead = true;
      _unreadCount--;
      notifyListeners();

      try {
        // Background mein API call chalne do
        await _service.markAsRead(id);
      } catch (e) {
        // Optional: Agar API fail ho jaye toh UI ko wapas unread kar sakte ho
        // Par notifications ke case mein silently fail hona theek rehta hai.
        print("❌ Background MarkAsRead failed: $e");
      }
    }
  }

  // ==========================================
  // 🧮 4. HELPER: CALCULATE UNREAD BADGE COUNT
  // ==========================================
  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  // ==========================================
  // 🔔 5. LIVE FOREGROUND LISTENER
  // ==========================================
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Live Foreground Notification Received!");

      // Jaise hi naya message aaye, API ko call karke list refresh kar do
      // Taaki user ko bina screen refresh kiye naya message dikh jaye
      loadNotifications();
    });
  }
}

// 🚀 ADD THIS AT THE BOTTOM OF YOUR PROVIDER FILE
// Ye line Riverpod ko batati hai ki is provider ko kaise use karna hai
final notificationControllerProvider = ChangeNotifierProvider<NotificationProvider>((ref) {
  return NotificationProvider();
});