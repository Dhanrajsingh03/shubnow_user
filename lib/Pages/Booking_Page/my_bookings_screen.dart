import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../Booking_Page/booking_service.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final service = BookingService();
    final rawList = await service.getUserBookings();
    return rawList.where((item) => item is Map).map((item) => Map<String, dynamic>.from(item)).toList();
  } catch (e) {
    throw Exception(e.toString());
  }
});

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => HapticFeedback.selectionClick());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🧠 1. BULLETPROOF IMAGE EXTRACTOR
  String _extractImage(Map<String, dynamic> booking) {
    if (booking['pujaId'] is Map) {
      return booking['pujaId']['image']?.toString() ?? booking['pujaId']['pujaImage']?.toString() ?? "";
    }
    return booking['pujaImage']?.toString() ?? booking['image']?.toString() ?? "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Puja_thali.jpg/640px-Puja_thali.jpg";
  }

  // ==========================================
  // 🧮 2. 100% CORRECT MATH EXTRACTOR (Ultimate Fix)
  // ==========================================
  Map<String, double> _extractPricing(Map<String, dynamic> booking) {
    double rawBasePrice = 0;
    double rawItemsPrice = 0;
    double platformFee = 0;
    double totalPrice = 0;

    // Check pricing object safely
    if (booking['pricing'] != null && booking['pricing'] is Map) {
      rawBasePrice = double.tryParse(booking['pricing']['basePrice']?.toString() ?? '0') ?? 0.0;
      rawItemsPrice = double.tryParse(booking['pricing']['itemsPrice']?.toString() ?? '0') ?? 0.0;
      platformFee = double.tryParse(booking['pricing']['platformFee']?.toString() ?? '0') ?? 0.0;
      totalPrice = double.tryParse(booking['pricing']['totalPrice']?.toString() ?? '0') ?? 0.0;
    } else {
      rawBasePrice = double.tryParse(booking['basePrice']?.toString() ?? '0') ?? 0.0;
      rawItemsPrice = double.tryParse(booking['itemsPrice']?.toString() ?? '0') ?? 0.0;
      platformFee = double.tryParse(booking['platformFee']?.toString() ?? '0') ?? 0.0;
      totalPrice = double.tryParse(booking['totalPrice']?.toString() ?? '0') ?? 0.0;
    }

    // 🔥 THE FIX:
    // Backend se aane wale basePrice me platform fee pehle se add hoti hai (Grand Total).
    // Isliye humein platform fee ko minus karna padega taaki exact "Pandit ji ki pure fee" nikal sake.

    // 1. Find Grand Total (Priority to backend's totalPrice, otherwise sum it up)
    double grandTotal = totalPrice > 0 ? totalPrice : (rawBasePrice + rawItemsPrice);

    // 2. The amount to pay Pandit = Grand Total MINUS the Platform Fee (Advance paid)
    double payToPandit = grandTotal - platformFee;

    // 3. Safety check (In case backend sends something completely wrong)
    if (payToPandit < 0) {
      payToPandit = rawBasePrice + rawItemsPrice;
    }

    return {
      'totalService': payToPandit,  // 🔥 Perfect Amount to pay later
      'platformFee': platformFee,   // Amount paid now
      'grandTotal': grandTotal,     // Everything
    };
  }

  String _getDisplayId(Map<String, dynamic> booking) {
    if (booking['bookingId'] != null && booking['bookingId'].toString().isNotEmpty) {
      return booking['bookingId'].toString();
    }
    return booking['_id']?.toString().toUpperCase().substring(0, 8) ?? "N/A";
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
          ),
        ),
        title: const Text("My Bookings", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.5)),
        bottom: TabBar(
          controller: _tabController, indicatorColor: Colors.deepOrange, labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey, indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          tabs: const [Tab(text: "Upcoming"), Tab(text: "History")],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => _buildShimmerLoading(),
        error: (err, _) => _buildErrorState(ref),
        data: (bookings) {
          final upcoming = bookings.where((b) => ['PAYMENT_PENDING', 'SEARCHING_PANDIT', 'ACCEPTED', 'EN_ROUTE', 'IN_PROGRESS', 'CONFIRMED'].contains(b['status']?.toString().toUpperCase())).toList();
          final past = bookings.where((b) => ['COMPLETED', 'CANCELLED', 'FAILED', 'REJECTED'].contains(b['status']?.toString().toUpperCase())).toList();
          return TabBarView(
            controller: _tabController,
            children: [_buildList(upcoming, true), _buildList(past, false)],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> bookings, bool isUpcoming) {
    if (bookings.isEmpty) return _buildEmptyState(isUpcoming);
    return RefreshIndicator(
      color: Colors.deepOrange,
      backgroundColor: Colors.white,
      onRefresh: () async => ref.refresh(myBookingsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildBookingCard(bookings[index], isUpcoming),
      ),
    );
  }

  // 🚀 MAIN BOOKING CARD WIDGET
  Widget _buildBookingCard(Map<String, dynamic> booking, bool isUpcoming) {
    final status = (booking['status'] ?? "PENDING").toString().toUpperCase();
    final String image = _extractImage(booking);
    final displayId = _getDisplayId(booking);
    final Map<String, dynamic>? pandit = booking['pandit'] is Map ? booking['pandit'] : null;

    // 🔥 Using our new Fixed Pricing logic
    final pricing = _extractPricing(booking);

    DateTime date = DateTime.tryParse(booking['scheduledDate'] ?? "") ?? DateTime.now();
    String formattedDate = DateFormat('dd MMM, yyyy').format(date);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pushNamed('booking-details', extra: booking);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ID: $displayId", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 13, letterSpacing: 0.5)),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(image, width: 75, height: 75, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(width:75, height:75, color:Colors.orange.shade50, child: const Icon(Icons.temple_hindu, color: Colors.orange)))
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['pujaName']?.toString() ?? "Puja", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text("$formattedDate • ${booking['scheduledTime'] ?? ''}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),

            if (isUpcoming && status == 'SEARCHING_PANDIT') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.person_search_rounded, color: Colors.blue, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text("Assigning an Expert Pandit...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ),
            ] else if (pandit != null && status != "CANCELLED") ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.shade100)),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundColor: Colors.white, backgroundImage: NetworkImage(pandit['profileImage']?.toString() ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"), onBackgroundImageError: (_,__) => const Icon(Icons.person, size: 18, color: Colors.orange)),
                    const SizedBox(width: 12),
                    Text(pandit['fullName']?.toString() ?? pandit['name']?.toString() ?? "Pandit Ji", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                    const Spacer(),
                    if (['ACCEPTED', 'EN_ROUTE', 'IN_PROGRESS'].contains(status))
                      const Icon(Icons.call, size: 20, color: Colors.green),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 Label Updated for clarity
                    Text(status == 'COMPLETED' ? "Paid Amount" : "Pay to Pandit", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    // 🚀 Perfect Extracted Pricing (No more platform fee)
                    Text("₹${pricing['totalService']!.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isUpcoming ? Colors.deepOrange : Colors.white,
                      elevation: 0,
                      side: isUpcoming ? BorderSide.none : const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('booking-details', extra: booking);
                  },
                  child: Text(isUpcoming ? "View Details" : "Receipt", style: TextStyle(color: isUpcoming ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- STYLISH HELPERS ---

  Widget _buildStatusBadge(String status, {bool large = false}) {
    Color color = Colors.blue;
    String label = status;
    if (status == 'SEARCHING_PANDIT') { color = Colors.blue; label = "SEARCHING"; }
    else if (status == 'ACCEPTED' || status == 'CONFIRMED') { color = Colors.orange; label = "BOOKED"; }
    else if (status == 'EN_ROUTE') { color = Colors.purple; label = "ON THE WAY"; }
    else if (status == 'IN_PROGRESS') { color = Colors.blueAccent; label = "IN PROGRESS"; }
    else if (status == 'COMPLETED') { color = Colors.green; label = "COMPLETED"; }
    else if (status == 'CANCELLED') { color = Colors.red; label = "CANCELLED"; }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 6 : 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(large ? 12 : 8)),
      child: Text(label, style: TextStyle(color: color, fontSize: large ? 12 : 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200, highlightColor: Colors.white,
        child: Container(height: 220, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
    const SizedBox(height: 16),
    const Text("Connection Lost", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
    TextButton(onPressed: () => ref.refresh(myBookingsProvider), child: const Text("Retry", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)))
  ]));

  Widget _buildEmptyState(bool upcoming) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey.shade200),
    const SizedBox(height: 16),
    Text(upcoming ? "No Active Bookings" : "No Past Orders", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 16)),
  ]));
}