import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

// 🔥 TODO: Apne exact paths yahan daal lena
import 'puja_provider.dart';
import 'puja_model.dart';

class HawanPujaScreen extends ConsumerWidget {
  const HawanPujaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pujasState = ref.watch(hawanPujasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hawan & Anushthan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.2)),
            Text('Divine purification through sacred fire', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),

      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.deepOrange,
        onRefresh: () async => await ref.refresh(allPujasProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            pujasState.when(
              loading: () => SliverToBoxAdapter(child: _buildShimmerLoading()),
              error: (error, stack) => SliverFillRemaining(child: _buildErrorState(error.toString(), ref)),
              data: (pujas) {
                if (pujas.isEmpty) return SliverFillRemaining(child: _buildEmptyState());

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  sliver: SliverList.separated(
                    itemCount: pujas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildPremiumPujaCard(context, pujas[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- SMART FORMATTER ---
  String _formatDuration(String duration) {
    if (duration.isEmpty) return 'N/A';
    if (!duration.toLowerCase().contains(RegExp(r'[a-z]'))) return '$duration Hours';
    return duration;
  }

  // --- COMPACT CARD ---
  Widget _buildPremiumPujaCard(BuildContext context, PujaModel puja) {
    // 💡 Smart Pricing: Based on availability, show the lowest starting price
    final startingPrice = puja.isWithoutSamagriAvailable
        ? puja.price.withoutSamagriTotal
        : puja.price.withSamagriTotal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // 🚀 NAVIGATION: Detail page par bhej raha hai with full data
          onTap: () => context.pushNamed('puja-details', extra: puja),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 📸 1. IMAGE & OVERLAY BADGES ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      puja.image,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.orange.shade50,
                        child: const Icon(Icons.temple_hindu, color: Colors.deepOrange, size: 40),
                      ),
                    ),
                  ),

                  // 🔥 Samagri Status Badge (Top Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildSamagriBadge(puja),
                  ),

                  // ⏱️ Duration Badge (Bottom Right)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.black87, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(puja.duration),
                            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- 📝 2. DETAILS SECTION ---
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Puja Name & Verified Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            puja.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Tagline
                    Text(
                      puja.title,
                      style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Short Description
                    Text(
                      puja.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 14),
                    Divider(color: Colors.grey.shade100, thickness: 1.5, height: 1),
                    const SizedBox(height: 12),

                    // --- 💰 3. PRICE & CTA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Starts from", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text("₹", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                                Text(
                                  "${startingPrice.toInt()}",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Industry Style Action Button
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.pushNamed('puja-details', extra: puja),
                            child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- DYNAMIC BADGE ---
  Widget _buildSamagriBadge(PujaModel puja) {
    bool hasSamagri = puja.isWithSamagriAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasSamagri ? Colors.green.shade600 : Colors.orange.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        hasSamagri ? "Samagri Included" : "Pandit Only",
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- LOADING / ERROR / EMPTY STATES (Skipped for brevity, use same as Wedding screen) ---
  Widget _buildShimmerLoading() => const Center(child: CircularProgressIndicator());
  Widget _buildErrorState(String e, WidgetRef ref) => Center(child: Text(e));
  Widget _buildEmptyState() => const Center(child: Text("No Hawan available"));
}