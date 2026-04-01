import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'puja_model.dart';
// 🔥 Apne folder structure ke hisaab se path adjust kar lena:
import '../Booking_Page/booking_provider.dart';

class PujaDetailScreen extends ConsumerStatefulWidget {
  final PujaModel puja;
  const PujaDetailScreen({super.key, required this.puja});

  @override
  ConsumerState<PujaDetailScreen> createState() => _PujaDetailScreenState();
}

class _PujaDetailScreenState extends ConsumerState<PujaDetailScreen> {
  // 🌟 Premium Button State Variables
  double _buttonScale = 1.0;
  bool _isNavigating = false;

  // ==========================================
  // 🚀 NAVIGATION LOGIC (Glitch-Free Fix)
  // ==========================================
  void _navigateToBooking() async {
    if (_isNavigating) return; // Prevent double taps

    // 1. Start loading animation (Shrink to circle)
    setState(() {
      _buttonScale = 1.0;
      _isNavigating = true;
    });

    HapticFeedback.mediumImpact();

    // 2. Reset the booking state so the next page starts fresh
    ref.read(bookingControllerProvider.notifier).clearState();

    // 3. Satisfying micro-delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      // 🚀 THE FIX: We wait for the new screen to pop back!
      // Isse button tab tak loader hi rahega jab tak Summary page slide hoke aa nahi jata.
      await context.pushNamed('booking-summary', extra: widget.puja);

      // Ye code tab chalega jab user Summary screen se "Back" dabayega.
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puja = widget.puja;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Ultra clean background
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- 📸 1. PREMIUM HEADER ---
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: puja.id, child: Image.network(puja.image, fit: BoxFit.cover)),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24, left: 24, right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white38, width: 0.5)
                              ),
                              child: const Text("EXPERT PANDIT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                puja.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 📝 2. MAIN CONTENT ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 STATUS & RATING BAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: Colors.green, size: 20),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    puja.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                              const SizedBox(width: 4),
                              const Text("4.9", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                              Text(" (1k+)", style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // 🛠️ PACKAGE EXPLANATION CARDS
                      const Text("Available Packages", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 16),

                      if (puja.isWithSamagriAvailable)
                        _buildInfoCard(
                          title: "Premium (With Samagri)",
                          price: puja.price.withSamagriTotal,
                          description: "Zero hassle for you. Pandit ji will bring all fresh, high-quality puja materials including flowers, fruits, and havan essentials.",
                          icon: Icons.shopping_bag_rounded,
                          iconColor: Colors.green,
                          isPopular: true,
                        ),

                      const SizedBox(height: 12),

                      if (puja.isWithoutSamagriAvailable)
                        _buildInfoCard(
                          title: "Basic (Without Samagri)",
                          price: puja.price.withoutSamagriTotal,
                          description: "Only Expert Pandit ji will arrive. You will be provided with a complete checklist to arrange all the required puja samagri yourself.",
                          icon: Icons.person_rounded,
                          iconColor: Colors.deepOrange,
                          isPopular: false,
                        ),

                      const SizedBox(height: 36),

                      // 📖 PREMIUM "ABOUT RITUAL" SECTION
                      const Text("About Ritual", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: const Border(left: BorderSide(color: Colors.deepOrange, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.menu_book_rounded, color: Colors.deepOrange.shade400, size: 20),
                                const SizedBox(width: 10),
                                const Text("Vedic Significance", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.deepOrange)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              puja.description,
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.7, letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 📋 SERVICE HIGHLIGHTS
                      const Text("Service Includes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      _buildServiceItem(Icons.timer_rounded, "Duration: ${puja.duration}", "Fixed time for proper execution"),
                      _buildServiceItem(Icons.auto_awesome_rounded, "Expert Pandit", "Verified and highly experienced"),

                      const SizedBox(height: 120), // Spacing for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- 💰 3. STICKY BOTTOM BAR WITH FIXED MORPHING BUTTON ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -10))],
              ),
              child: Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTapDown: (_) {
                    if (!_isNavigating) setState(() => _buttonScale = 0.95);
                  },
                  onTapUp: (_) {
                    if (!_isNavigating) {
                      setState(() => _buttonScale = 1.0);
                      _navigateToBooking();
                    }
                  },
                  onTapCancel: () {
                    if (!_isNavigating) setState(() => _buttonScale = 1.0);
                  },
                  child: AnimatedScale(
                    scale: _buttonScale,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300), // Adjusted for snappier feel
                      curve: Curves.fastOutSlowIn,
                      height: 56,
                      width: _isNavigating ? 56 : MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color: _isNavigating ? Colors.deepOrange.shade400 : Colors.deepOrange,
                          borderRadius: BorderRadius.circular(_isNavigating ? 28 : 16),
                          boxShadow: _isNavigating ? [] : [
                            BoxShadow(color: Colors.deepOrange.withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 6))
                          ]
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isNavigating
                            ? const SizedBox(
                          key: ValueKey("loader"),
                          height: 24, width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3, strokeCap: StrokeCap.round),
                        )
                            : const Text(
                          "Book Now",
                          key: ValueKey("text"),
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildInfoCard({
    required String title,
    required double price,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isPopular
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                        child: const Text("RECOMMENDED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                  ],
                ),
              ),
              Text("₹${price.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}