import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_provider.dart';

// ⚠️ YAHAN APNE PROVIDER FILE KA PATH SAHI SE DAALNA
// import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {

  @override
  void initState() {
    super.initState();
    // Screen khulte hi data fetch karo
    Future.microtask(() {
      ref.read(notificationControllerProvider).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 MAGIC RIVERPOD LINE: Tera provider yahan watch ho raha hai
    final provider = ref.watch(notificationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          // ==========================================
          // 🛑 1. ERROR STATE (Internet Issue / Timeout)
          // ==========================================
          if (provider.errorMessage != null && provider.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(notificationControllerProvider).loadNotifications(), // 👈 RETRY
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          // ==========================================
          // ⏳ 2. LOADING STATE
          // ==========================================
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          // ==========================================
          // 📭 3. EMPTY STATE (No Notifications)
          // ==========================================
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 90, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                      "No notifications yet 🪔",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600)
                  ),
                  const SizedBox(height: 8),
                  Text(
                      "We'll let you know when something happens.",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)
                  ),
                ],
              ),
            );
          }

          // ==========================================
          // ✅ 4. SUCCESS STATE (The List)
          // ==========================================
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationControllerProvider).loadNotifications(), // Pull to refresh
            color: Colors.orange,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];

                return ListTile(
                  tileColor: notification.isRead ? Colors.white : Colors.orange.withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

                  // 🔔 Icon
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: notification.isRead ? Colors.grey.shade100 : Colors.orange.shade100,
                        radius: 24,
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: notification.isRead ? Colors.grey.shade500 : Colors.orange,
                          size: 24,
                        ),
                      ),
                      // Red dot for unread
                      if (!notification.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        )
                    ],
                  ),

                  // 📝 Texts
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: notification.isRead ? Colors.black87 : Colors.black,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),

                  // 👆 Action on Tap
                  onTap: () {
                    // Mark as read
                    ref.read(notificationControllerProvider).markAsRead(notification.id);

                    // Redirect Logic
                    if (notification.relatedId != null) {
                      print("Redirecting to: ${notification.relatedId}");
                      if (notification.type == 'BOOKING_ACCEPTED' || notification.type == 'NEW_BOOKING') {
                        // context.pushNamed('booking_details', extra: notification.relatedId);
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}