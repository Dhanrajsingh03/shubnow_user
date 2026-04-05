import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔥 PujaModel import zaroori hai details page pe bhejne ke liye
import '../Puja_Page/puja_model.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  // 🧠 SMART EXTRACTORS
  String _extractImage(Map<String, dynamic> booking) {
    if (booking['pujaId'] is Map) return booking['pujaId']['image']?.toString() ?? booking['pujaId']['pujaImage']?.toString() ?? "";
    return booking['pujaImage']?.toString() ?? booking['image']?.toString() ?? "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Puja_thali.jpg/640px-Puja_thali.jpg";
  }

  Map<String, double> _extractPricing(Map<String, dynamic> booking) {
    double basePrice = 0, samagriPrice = 0, platformFee = 0;
    if (booking['pricing'] != null && booking['pricing'] is Map) {
      basePrice = double.tryParse(booking['pricing']['basePrice']?.toString() ?? '0') ?? 0.0;
      samagriPrice = double.tryParse(booking['pricing']['itemsPrice']?.toString() ?? '0') ?? 0.0;
      platformFee = double.tryParse(booking['pricing']['platformFee']?.toString() ?? '0') ?? 0.0;
    } else {
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
    if (booking['bookingId'] != null && booking['bookingId'].toString().isNotEmpty) return booking['bookingId'].toString();
    return booking['_id']?.toString().toUpperCase().substring(0, 8) ?? "N/A";
  }

  // 📞 PHONE DIALER HELPER
  Future<void> _makePhoneCall(String phone) async {
    HapticFeedback.mediumImpact();
    if (phone.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number not available")));
      return;
    }
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch dialer")));
    }
  }

  // ==========================================
  // 🧔 PANDIT PROFILE - ULTRA SMOOTH POPUP
  // ==========================================
  void _showPanditProfile(BuildContext context, Map<String, dynamic> pandit) {
    HapticFeedback.mediumImpact();

    // 🔥 DATA EXTRACTION
    final String name = pandit['fullName']?.toString() ?? pandit['name']?.toString() ?? "Pandit Ji";
    final String image = pandit['profileImage']?.toString() ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
    final String phone = pandit['phone']?.toString() ?? "";
    final String email = pandit['email']?.toString() ?? "Not Provided";
    final String age = pandit['age']?.toString() ?? "--";

    // 🚨 Safe Address Extraction
    String address = "Address not specified";
    if (pandit['address'] is String && pandit['address'].toString().isNotEmpty) {
      address = pandit['address'].toString();
    } else if (pandit['address'] is Map && pandit['address']['exactAddress'] != null) {
      address = pandit['address']['exactAddress'].toString();
    } else if (pandit['location'] is Map && pandit['location']['exactAddress'] != null) {
      address = pandit['location']['exactAddress'].toString();
    }

    final String bio = (pandit['aboutMe'] is String && pandit['aboutMe'].toString().isNotEmpty)
        ? pandit['aboutMe'].toString()
        : "Expert Vedic Scholar and Puja Specialist.";

    final String experience = pandit['experience']?.toString() ?? "--";
    const String rating = "4.5"; // 🔥 Hardcoded 4.5

    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: "PanditProfile",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart);

        return FadeTransition(
          opacity: curvedAnimation,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.90, end: 1.0).animate(curvedAnimation),
                child: Dialog(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.deepOrange.shade100, width: 3)),
                                      child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(image), backgroundColor: Colors.orange.shade50, onBackgroundImageError: (_,__) => const Icon(Icons.person, size: 40, color: Colors.orange)),
                                    ),
                                    if (pandit['isProfileApproved'] == true)
                                      Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: Colors.green, size: 22))
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5), textAlign: TextAlign.center),
                                const SizedBox(height: 4),
                                const Text("Verified Pandit", style: TextStyle(color: Colors.deepOrange, fontSize: 13, fontWeight: FontWeight.w800)),

                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildPanditStat(Icons.star_rounded, Colors.amber, rating, "Rating"),
                                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                                      _buildPanditStat(Icons.workspace_premium_rounded, Colors.blue, experience == "--" ? "--" : "$experience Yrs", "Experience"),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                const Align(alignment: Alignment.centerLeft, child: Text("Personal Info", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                                const SizedBox(height: 10),
                                _buildInfoRow(Icons.cake_rounded, "Age", "$age Years"),
                                _buildInfoRow(Icons.email_rounded, "Email", email),
                                _buildInfoRow(Icons.location_on_rounded, "Address", address),
                                const SizedBox(height: 20),

                                const Align(alignment: Alignment.centerLeft, child: Text("About", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(bio, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5, fontWeight: FontWeight.w500)),
                                ),

                                const SizedBox(height: 32),

                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300))),
                                        child: Text("Close", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _makePhoneCall(phone);
                                        },
                                        icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                                        label: const Text("Call Pandit", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 📝 Helper for Personal Info Rows
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPanditStat(IconData icon, Color iconColor, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final status = (booking['status'] ?? "PENDING").toString().toUpperCase();
    final pandit = booking['pandit'] is Map ? booking['pandit'] : null;
    final displayId = _getDisplayId(booking);
    final pricing = _extractPricing(booking);

    DateTime date = DateTime.tryParse(booking['scheduledDate'] ?? "") ?? DateTime.now();
    String formattedDate = DateFormat('EEEE, dd MMM yyyy').format(date);
    String time = booking['scheduledTime'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        title: const Text("Booking Details", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 📍 1. STATUS HEADER & LIVE TIMELINE
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("ID: $displayId", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTrackingTimeline(status),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 🧔 2. ASSIGNED PANDIT JI
            if (pandit != null) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Assigned Pandit Ji", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showPanditProfile(context, pandit),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(radius: 30, backgroundColor: Colors.orange.shade50, backgroundImage: NetworkImage(pandit['profileImage']?.toString() ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"), onBackgroundImageError: (_,__) => const Icon(Icons.person, color: Colors.orange)),
                                if (pandit['isProfileApproved'] == true)
                                  Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: Colors.green, size: 16)),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pandit['fullName']?.toString() ?? "Pandit Ji", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  const Text("View Complete Profile", style: TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            // 🔥 CALL BUTTON
                            GestureDetector(
                              onTap: () => _makePhoneCall(pandit['phone']?.toString() ?? ""),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.call_rounded, color: Colors.green, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 🪔 3. SERVICE DETAILS & LOCATION
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Service Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  const SizedBox(height: 20),

                  // 🔥 THE FIX: GESTURE DETECTOR ON PUJA CARD (FLIPKART STYLE)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (booking['pujaId'] is Map) {
                        try {
                          final pujaData = booking['pujaId'] as Map<String, dynamic>;
                          final pujaModel = PujaModel.fromJson(pujaData);
                          // Send user to Puja details screen smoothly
                          context.pushNamed('puja-details', extra: pujaModel);
                        } catch (e) {
                          print("Error navigating to Puja Details: $e");
                        }
                      }
                    },
                    child: Container(
                      color: Colors.transparent, // Ensures the entire row area is clickable
                      child: Row(
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(_extractImage(booking), width: 75, height: 75, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 75, height: 75, color: Colors.orange.shade50, child: const Icon(Icons.temple_hindu, color: Colors.orange)))
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking['pujaName']?.toString() ?? "Puja Service", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.deepOrange),
                                    const SizedBox(width: 6),
                                    Text(formattedDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.deepOrange),
                                    const SizedBox(width: 6),
                                    Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 🚀 Added a forward arrow to visually tell users it's clickable
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
                  const Text("Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.location_on_rounded, size: 20, color: Colors.deepOrange)),
                      const SizedBox(width: 16),
                      Expanded(child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(booking['location']?['exactAddress']?.toString() ?? "Address not provided", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5, color: Colors.black87)),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 📜 4. TRANSPARENT PAYMENT RECEIPT
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                      Text("₹${pricing['grandTotal']!.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 24),

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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    String label = status;
    if (status == 'SEARCHING_PANDIT') { color = Colors.blue; label = "SEARCHING"; }
    else if (status == 'ACCEPTED' || status == 'CONFIRMED') { color = Colors.orange; label = "BOOKED"; }
    else if (status == 'EN_ROUTE') { color = Colors.purple; label = "ON THE WAY"; }
    else if (status == 'IN_PROGRESS') { color = Colors.blueAccent; label = "IN PROGRESS"; }
    else if (status == 'COMPLETED') { color = Colors.green; label = "COMPLETED"; }
    else if (status == 'CANCELLED') { color = Colors.red; label = "CANCELLED"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildTrackingTimeline(String status) {
    bool isAssigned = ['ACCEPTED', 'EN_ROUTE', 'IN_PROGRESS', 'COMPLETED'].contains(status);
    bool isOnWay = ['EN_ROUTE', 'IN_PROGRESS', 'COMPLETED'].contains(status);
    bool isCompleted = status == 'COMPLETED';
    bool isCancelled = status == 'CANCELLED';

    if (isCancelled) {
      return _buildTimelineStep(title: "Booking Cancelled", isLast: true, isActive: false, isError: true, icon: Icons.cancel_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineStep(title: "Booking Confirmed", subtitle: "Advance paid successfully.", isActive: true, icon: Icons.receipt_long_rounded),
        _buildTimelineStep(title: "Pandit Assigned", subtitle: isAssigned ? "A verified Pandit is assigned." : "Searching for a Pandit...", isActive: isAssigned, isCurrent: !isAssigned, icon: Icons.person_search_rounded),
        _buildTimelineStep(title: "On The Way", subtitle: isOnWay ? "Pandit ji has arrived." : "Pandit ji will arrive on scheduled time.", isActive: isOnWay, isCurrent: isAssigned && !isOnWay, icon: Icons.directions_car_rounded),
        _buildTimelineStep(title: "Puja Completed", subtitle: isCompleted ? "May god bless you." : "Waiting for completion.", isLast: true, isActive: isCompleted, isCurrent: isOnWay && !isCompleted, icon: Icons.check_circle_rounded),
      ],
    );
  }

  Widget _buildTimelineStep({required String title, String? subtitle, required bool isActive, bool isCurrent = false, bool isLast = false, bool isError = false, required IconData icon}) {
    Color iconColor = isError ? Colors.red : (isActive ? Colors.green : (isCurrent ? Colors.deepOrange : Colors.grey.shade400));
    Color lineColor = isActive ? Colors.green : Colors.grey.shade200;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            if (!isLast)
              Container(width: 2, height: 35, color: lineColor, margin: const EdgeInsets.symmetric(vertical: 4)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold, color: isError ? Colors.red : (isActive || isCurrent ? Colors.black87 : Colors.grey))),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}