import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// 🔥 Apna backend service import path check kar lena
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
      return booking['pujaId']['image'] ?? booking['pujaId']['pujaImage'] ?? "";
    }
    return booking['pujaImage'] ?? booking['image'] ?? "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Puja_thali.jpg/640px-Puja_thali.jpg";
  }

  // 🧠 2. SMART AMOUNT EXTRACTOR (Modified to extract individual parts)
  Map<String, double> _extractPricing(Map<String, dynamic> booking) {
    double basePrice = 0;
    double samagriPrice = 0;
    double platformFee = 0;

    if (booking['pricing'] != null && booking['pricing'] is Map) {
      basePrice = double.tryParse(booking['pricing']['basePrice']?.toString() ?? '0') ?? 0.0;
      samagriPrice = double.tryParse(booking['pricing']['itemsPrice']?.toString() ?? '0') ?? 0.0;
      platformFee = double.tryParse(booking['pricing']['platformFee']?.toString() ?? '0') ?? 0.0;
    } else {
      // Fallback if backend structure differs
      basePrice = double.tryParse(booking['basePrice']?.toString() ?? '0') ?? 0.0;
      samagriPrice = double.tryParse(booking['itemsPrice']?.toString() ?? '0') ?? 0.0;
      platformFee = double.tryParse(booking['platformFee']?.toString() ?? '0') ?? 0.0;
    }

    return {
      'base': basePrice,
      'samagri': samagriPrice,
      'advance': platformFee,
      'totalService': basePrice + samagriPrice,
      'grandTotal': basePrice + samagriPrice + platformFee,
    };
  }

  String _getDisplayId(Map<String, dynamic> booking) {
    if (booking['bookingId'] != null && booking['bookingId'].toString().isNotEmpty) {
      return booking['bookingId'].toString();
    }
    return booking['_id']?.toString().toUpperCase().substring(0, 8) ?? "N/A";
  }

  // ==========================================
  // 🧔 PANDIT PROFILE BOTTOM SHEET (Unchanged, it was perfect)
  // ==========================================
  void _showPanditProfile(BuildContext context, Map<String, dynamic> pandit) {
    HapticFeedback.lightImpact();

    final String name = pandit['fullName'] ?? pandit['name'] ?? "Pandit Ji";
    final String image = pandit['profileImage'] ?? pandit['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
    final String bio = pandit['bio'] ?? "Verified Vedic Scholar and Puja Expert registered with us.";
    final String experience = pandit['experience']?.toString() ?? "--";
    final String rating = pandit['rating']?.toString() ?? "New";
    final String pujasDone = pandit['pujasCompleted']?.toString() ?? "--";

    List<String> languages = [];
    if (pandit['languages'] is List) {
      languages = (pandit['languages'] as List).map((e) => e.toString()).toList();
    }
    if (languages.isEmpty) languages = ["Hindi", "Sanskrit"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.deepOrange.shade100, width: 3)),
                            child: CircleAvatar(radius: 50, backgroundImage: NetworkImage(image), backgroundColor: Colors.orange.shade50, onBackgroundImageError: (_,__) => const Icon(Icons.person, size: 50, color: Colors.orange)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.verified_rounded, color: Colors.green, size: 28),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      const Text("Vedic Scholar & Priest", style: TextStyle(color: Colors.deepOrange, fontSize: 14, fontWeight: FontWeight.w800)),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPanditStat(Icons.star_rounded, Colors.amber, rating, "Rating"),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            _buildPanditStat(Icons.workspace_premium_rounded, Colors.blue, experience == "--" ? experience : "$experience Yrs", "Experience"),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            _buildPanditStat(Icons.auto_awesome_rounded, Colors.green, pujasDone, "Pujas Done"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Align(alignment: Alignment.centerLeft, child: Text("About Pandit Ji", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                      const SizedBox(height: 12),
                      Text(bio, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),

                      const Align(alignment: Alignment.centerLeft, child: Text("Languages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: languages.map((lang) => _buildChip(lang)).toList(),
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () { HapticFeedback.mediumImpact(); },
                          icon: const Icon(Icons.call_rounded, color: Colors.white),
                          label: const Text("Call Pandit Ji", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanditStat(IconData icon, Color iconColor, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepOrange.shade100)),
      child: Text(label, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // ==========================================
  // 🌟 THE PREMIUM BOTTOM SHEET (BOOKING DETAILS)
  // ==========================================
  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    HapticFeedback.mediumImpact();
    final status = (booking['status'] ?? "PENDING").toString().toUpperCase();
    final pandit = booking['pandit'] is Map ? booking['pandit'] : null;
    final displayId = _getDisplayId(booking);

    // 🧮 Extract pricing map
    final pricing = _extractPricing(booking);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Booking Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text("ID: $displayId", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          _buildStatusBadge(status, large: true),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Service Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Row(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_extractImage(booking), width: 80, height: 80, fit: BoxFit.cover)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(booking['pujaName'] ?? "Puja Service", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.deepOrange),
                                      const SizedBox(width: 6),
                                      Text(DateFormat('dd MMM yyyy').format(DateTime.tryParse(booking['scheduledDate'] ?? "") ?? DateTime.now()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.deepOrange),
                                      const SizedBox(width: 6),
                                      Text("${booking['scheduledTime']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Location
                      const Text("Puja Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.location_on_rounded, size: 20, color: Colors.deepOrange)),
                          const SizedBox(width: 12),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(booking['location']?['exactAddress'] ?? "Address not provided", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pandit Card
                      if (pandit != null) ...[
                        const Text("Assigned Pandit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showPanditProfile(context, pandit),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 28, backgroundColor: Colors.grey.shade100, backgroundImage: NetworkImage(pandit['profileImage'] ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png")),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pandit['fullName'] ?? pandit['name'] ?? "Pandit Ji", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      const Text("View Full Profile", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // =========================================================
                      // 📜 THE ULTIMATE TRANSPARENT INVOICE
                      // =========================================================
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Payment Receipt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.3)),
                            const SizedBox(height: 20),

                            _buildDetailedBillRow("Puja Ritual Fee", pricing['base']!),

                            if (pricing['samagri']! > 0) ...[
                              const SizedBox(height: 12),
                              _buildDetailedBillRow("Puja Samagri Kit", pricing['samagri']!),
                            ],

                            const SizedBox(height: 12),
                            _buildDetailedBillRow("Platform & Security Fee", pricing['advance']!),

                            // ✂️ Dotted Divider line
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Flex(
                                    direction: Axis.horizontal,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      (constraints.constrainWidth() / 8).floor(),
                                          (index) => SizedBox(width: 4, height: 1.5, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade300))),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 💰 Grand Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                                Text("₹${pricing['grandTotal']!.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ✅ Box 1: Paid Online (Advance)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      const Text("Paid Online (Advance)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.green)),
                                    ],
                                  ),
                                  Text("₹${pricing['advance']!.toInt()}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green.shade700)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ⏳ Box 2: Pay to Pandit
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(color: status == 'COMPLETED' ? Colors.green.shade50 : Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: status == 'COMPLETED' ? Colors.green.shade100 : Colors.deepOrange.shade100)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(status == 'COMPLETED' ? Icons.check_circle_rounded : Icons.handshake_rounded, color: status == 'COMPLETED' ? Colors.green.shade600 : Colors.deepOrange.shade600, size: 20),
                                          const SizedBox(width: 8),
                                          Text(status == 'COMPLETED' ? "Paid to Pandit" : "Pay to Pandit", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: status == 'COMPLETED' ? Colors.green.shade700 : Colors.deepOrange)),
                                        ],
                                      ),
                                      if (status != 'COMPLETED')
                                        Padding(
                                          padding: const EdgeInsets.only(left: 28, top: 2),
                                          child: Text("Cash/UPI after the Puja", style: TextStyle(fontSize: 11, color: Colors.deepOrange.shade300, fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  ),
                                  Text("₹${pricing['totalService']!.toInt()}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: status == 'COMPLETED' ? Colors.green.shade700 : Colors.deepOrange.shade700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 📱 MAIN SCREEN UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
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
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showBookingDetails(context, bookings[index]),
          child: _buildBookingCard(bookings[index], isUpcoming),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isUpcoming) {
    final status = (booking['status'] ?? "PENDING").toString().toUpperCase();
    final String image = _extractImage(booking);
    final displayId = _getDisplayId(booking);
    final Map<String, dynamic>? pandit = booking['pandit'] is Map ? booking['pandit'] : null;

    // Using the new helper to get exact amount Pandit will receive
    final pricing = _extractPricing(booking);

    DateTime date = DateTime.tryParse(booking['scheduledDate'] ?? "") ?? DateTime.now();
    String formattedDate = DateFormat('dd MMM, yyyy').format(date);

    return Container(
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
                    Text(booking['pujaName'] ?? "Puja", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  CircleAvatar(radius: 16, backgroundColor: Colors.white, backgroundImage: NetworkImage(pandit['profileImage'] ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"), onBackgroundImageError: (_,__) => const Icon(Icons.person, size: 18, color: Colors.orange)),
                  const SizedBox(width: 12),
                  Text(pandit['fullName'] ?? pandit['name'] ?? "Pandit Ji", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
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
                  Text(status == 'COMPLETED' ? "Paid Amount" : "Payable Amount", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
                onPressed: () => _showBookingDetails(context, booking),
                child: Text(isUpcoming ? "View Details" : "Receipt", style: TextStyle(color: isUpcoming ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- STYLISH HELPERS ---

  Widget _buildDetailedBillRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
          Text("₹${amount.toInt()}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

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