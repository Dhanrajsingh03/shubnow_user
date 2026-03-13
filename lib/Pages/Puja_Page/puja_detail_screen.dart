import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'puja_model.dart';

class PujaDetailScreen extends StatefulWidget {
  final PujaModel puja;
  const PujaDetailScreen({super.key, required this.puja});

  @override
  State<PujaDetailScreen> createState() => _PujaDetailScreenState();
}

class _PujaDetailScreenState extends State<PujaDetailScreen> {
  bool isWithSamagri = true;

  @override
  void initState() {
    super.initState();
    // 🚦 Safety check for selection defaults
    if (!widget.puja.isWithSamagriAvailable) isWithSamagri = false;
  }

  @override
  Widget build(BuildContext context) {
    final puja = widget.puja;
    final currentPrice = isWithSamagri
        ? puja.price.withSamagriTotal
        : puja.price.withoutSamagriTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // 🏛️ Premium off-white background
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- 📸 1. DYNAMIC SLIVER HEADER ---
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: Colors.white,
                leadingWidth: 60,
                leading: _buildHeaderAction(Icons.arrow_back_ios_new_rounded, () => context.pop()),
                actions: [
                  _buildHeaderAction(Icons.share_outlined, () {}),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: puja.id, child: Image.network(puja.image, fit: BoxFit.cover)),
                      // Premium Bottom Gradient for text clarity
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black38, Colors.black87],
                            stops: [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40, left: 20, right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(6)),
                              child: const Text("TOP RATED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                            const SizedBox(height: 8),
                            Text(puja.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 📝 2. MAIN CONTENT ---
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tagline & Verification
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text(puja.title, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 🛠️ Feature Icons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildModernStat(Icons.access_time_filled_rounded, puja.duration, "Duration"),
                          _buildModernStat(Icons.language_rounded, "Hindi", "Language"),
                          _buildModernStat(Icons.stars_rounded, "4.9/5", "Rating"),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text("About Ritual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Text(puja.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6, letterSpacing: 0.2)),

                      const SizedBox(height: 32),

                      // 💳 3. PACKAGE SELECTION TILES
                      const Text("Choose Package", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),

                      if (puja.isWithSamagriAvailable)
                        _buildPackageTile(
                          title: "Premium (Pooja + Samagri)",
                          desc: "Pandit ji + Flowers + Fruits + All Essentials",
                          price: puja.price.withSamagriTotal,
                          isSelected: isWithSamagri,
                          onTap: () => setState(() => isWithSamagri = true),
                          tag: "BEST VALUE",
                        ),

                      const SizedBox(height: 12),

                      if (puja.isWithoutSamagriAvailable)
                        _buildPackageTile(
                          title: "Essential (Pandit Only)",
                          desc: "Expert Pandit ji for rituals. You provide Samagri.",
                          price: puja.price.withoutSamagriTotal,
                          isSelected: !isWithSamagri,
                          onTap: () => setState(() => isWithSamagri = false),
                        ),

                      const SizedBox(height: 32),

                      // 📜 4. WHAT'S INCLUDED SECTION
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("What's Included", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 16),
                            _buildCheckItem("Verified & Experienced Pandit ji"),
                            _buildCheckItem("Proper Vedic Ritual Execution"),
                            if (isWithSamagri) _buildCheckItem("Fresh Samagri & Flower Kit"),
                            _buildCheckItem("Digital Dakshina (No Hidden Charges)"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- 💰 5. STICKY ACTION FOOTER ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildStickyFooter(currentPrice.toInt()),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
        child: IconButton(icon: Icon(icon, color: Colors.black, size: 20), onPressed: onTap),
      ),
    );
  }

  Widget _buildModernStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 26),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPackageTile({required String title, required String desc, required double price, required bool isSelected, required VoidCallback onTap, String? tag}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                      child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text("₹${price.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(int price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL PAYABLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                Text("₹$price", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
              ],
            ),
          ),
          SizedBox(
            width: 170, height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {},
              child: const Text("Select Slot", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}