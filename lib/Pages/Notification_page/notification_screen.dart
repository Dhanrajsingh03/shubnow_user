import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

// 🔥 API & Provider Imports (Ensure these paths are correct in your project)
import 'notification_provider.dart';
import 'notification_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {

  @override
  void initState() {
    super.initState();
    // 🚀 Screen khulte hi data fetch karo
    Future.microtask(() {
      ref.read(notificationControllerProvider).loadNotifications();
    });
  }

  // ==========================================
  // 🎨 SMART ICON & COLOR MAPPER
  // ==========================================
  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'NEW_BOOKING':
      case 'BOOKING_ACCEPTED':
      case 'BOOKING_COMPLETED':
        return {'icon': Icons.calendar_month_rounded, 'color': Colors.blue.shade600, 'bg': Colors.blue.shade50};
      case 'BOOKING_CANCELLED':
        return {'icon': Icons.cancel_rounded, 'color': Colors.red.shade600, 'bg': Colors.red.shade50};
      case 'PAYMENT_SUCCESS':
        return {'icon': Icons.verified_rounded, 'color': Colors.green.shade600, 'bg': Colors.green.shade50};
      case 'PROMO_ALERT':
        return {'icon': Icons.local_offer_rounded, 'color': Colors.purple.shade600, 'bg': Colors.purple.shade50};
      case 'SYSTEM_ALERT':
      default:
        return {'icon': Icons.notifications_rounded, 'color': Colors.orange.shade600, 'bg': Colors.orange.shade50};
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(notificationControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Premium Off-White Background
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        // 🚀 PREMIUM ACTION MENU (Only show if notifications exist)
        actions: [
          if (provider.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'read_all') {
                  ref.read(notificationControllerProvider).markAllAsRead();
                } else if (value == 'clear_all') {
                  _showClearAllDialog(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(children: [
                    Icon(Icons.checklist_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text("Mark all as read", style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("Clear all", style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            )
        ],
      ),
      body: Builder(
        builder: (context) {
          // ==========================================
          // 🛑 1. ERROR STATE
          // ==========================================
          if (provider.errorMessage != null && provider.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.wifi_off_rounded, size: 60, color: Colors.red.shade300),
                    ),
                    const SizedBox(height: 24),
                    const Text("Connection Lost", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(notificationControllerProvider).loadNotifications(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          // ==========================================
          // ⏳ 2. SHIMMER LOADING STATE
          // ==========================================
          if (provider.isLoading && provider.notifications.isEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.white,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                ),
              ),
            );
          }

          // ==========================================
          // 📭 3. EMPTY STATE
          // ==========================================
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.notifications_paused_rounded, size: 80, color: Colors.orange.shade300),
                  ),
                  const SizedBox(height: 24),
                  const Text("All Caught Up!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text("You have no new notifications right now.", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // ==========================================
          // ✅ 4. SUCCESS STATE (The Premium List)
          // ==========================================
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationControllerProvider).loadNotifications(isRefresh: true),
            color: Colors.white,
            backgroundColor: Colors.deepOrange,
            strokeWidth: 3,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100, indent: 76),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                final style = _getNotificationStyle(notification.type);

                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Colors.red.shade500,
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                  ),
                  onDismissed: (direction) {
                    ref.read(notificationControllerProvider).deleteNotification(notification.id);
                  },
                  child: Material(
                    color: notification.isRead ? Colors.white : Colors.orange.shade50.withOpacity(0.4),
                    child: InkWell(
                      onTap: () {
                        // Mark as read immediately
                        ref.read(notificationControllerProvider).markAsRead(notification.id);

                        // Routing Logic
                        if (notification.relatedId != null) {
                          if (notification.type.contains('BOOKING')) {
                            // context.pushNamed('booking_details', extra: notification.relatedId);
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔔 Smart Icon
                            Stack(
                              children: [
                                Container(
                                  height: 48, width: 48,
                                  decoration: BoxDecoration(
                                    color: notification.isRead ? Colors.grey.shade100 : style['bg'],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                      style['icon'],
                                      color: notification.isRead ? Colors.grey.shade500 : style['color'],
                                      size: 22
                                  ),
                                ),
                                // Unread Dot
                                if (!notification.isRead)
                                  Positioned(
                                    right: 2, top: 2,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(width: 16),

                            // 📝 Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: notification.isRead ? Colors.black87 : Colors.black,
                                        letterSpacing: -0.3
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.body,
                                    style: TextStyle(
                                      color: notification.isRead ? Colors.grey.shade500 : Colors.grey.shade700,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // ⚠️ DIALOG: CONFIRM CLEAR ALL
  // ==========================================
  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear All Notifications?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: const Text("This action cannot be undone. Are you sure you want to delete your entire history?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationControllerProvider).deleteAllNotifications();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Clear All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}