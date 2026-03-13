import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';

// 🔥 API & Provider Imports (Ensure these paths are correct in your project)
import '../Login_Page/auth_provider.dart';
import '../Profile_Page/profile_provider.dart';
import '../Puja_Page/puja_model.dart';
import '../Puja_Page/puja_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String _currentLocationName = "Detecting location...";
  bool _isLocationLoading = false;
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocationSequence());

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 2) _currentPage++; else _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
      }
    });
  }

  // ==========================================
  // 📍 BULLETPROOF LOCATION LOGIC
  // ==========================================
  Future<void> _initLocationSequence() async {
    if (!mounted) return;
    setState(() => _isLocationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _currentLocationName = "Enable GPS"; _isLocationLoading = false; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() { _currentLocationName = "Permission Denied"; _isLocationLoading = false; });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      ref.read(authControllerProvider.notifier).updateLiveLocation(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        setState(() {
          _currentLocationName = "${placemarks[0].locality}, ${placemarks[0].subAdministrativeArea}";
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _currentLocationName = "Patna, Bihar"; _isLocationLoading = false; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- 📝 DATA CONFIG ---
  final List<Map<String, dynamic>> _featuredServices = [
    {'name': 'Free Muhurat\nConsultation', 'icon': Icons.access_time_filled, 'color': Colors.orange},
    {'name': 'Regular\nPuja', 'icon': Icons.temple_hindu, 'color': Colors.red},
    {'name': 'Wedding\nPooja', 'icon': Icons.diversity_1, 'color': Colors.pink},
    {'name': 'Havan /\nAnushthan', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'name': '99 Pooja\nSeva', 'icon': Icons.volunteer_activism, 'color': Colors.green},
    {'name': 'Special\nVrat Kit', 'icon': Icons.card_giftcard, 'color': Colors.blue},
  ];

  final List<Map<String, dynamic>> _subscriptionServices = [
    {'name': '99 Pooja\nSeva', 'icon': Icons.volunteer_activism, 'color': Colors.green},
    {'name': 'Special\nVrat Kit', 'icon': Icons.card_giftcard, 'color': Colors.blue},
    {'name': 'Monthly\nPooja Kit', 'icon': Icons.calendar_month, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home_filled, 'label': 'Home'},
    {'icon': Icons.calendar_today, 'activeIcon': Icons.calendar_month, 'label': 'Bookings'},
    {'icon': Icons.smart_toy_outlined, 'activeIcon': Icons.smart_toy, 'label': 'AI Pandit'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    final pujasState = ref.watch(allPujasProvider);
    final profileState = ref.watch(profileControllerProvider);
    String userName = profileState.maybeWhen(data: (u) => u.fullName.split(" ")[0], orElse: () => "User");

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.deepOrange,
          strokeWidth: 3,
          displacement: 20,
          onRefresh: () async {
            await _initLocationSequence();
            return await ref.refresh(allPujasProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              _buildHeader(userName),
              _buildSearchBar(),
              _buildBanner(),

              // --- FEATURED ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Featured Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12, runSpacing: 24,
                        children: _featuredServices.map((s) => _buildIconService(context, s)).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // --- SUBSCRIPTIONS ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subscription Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _subscriptionServices.map((s) => Expanded(child: _buildIconService(context, s))).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- UPCOMING FESTIVALS ---
              _buildSectionTitleSliver("Upcoming Festival Pooja"),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 330, // Thodi height badhayi price include karne ke liye
                  child: pujasState.when(
                    loading: () => _buildHorizontalShimmerBox(),
                    error: (e, _) => const Center(child: Text("Unable to load festivals")),
                    data: (pujas) {
                      final fests = pujas.where((p) => p.pujaType == 'festival').toList();
                      if (fests.isEmpty) return const Center(child: Text("No upcoming festivals", style: TextStyle(color: Colors.grey)));

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: fests.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => _buildFestivalCard(fests[index]),
                      );
                    },
                  ),
                ),
              ),

              // --- RECOMMENDED ---
              _buildSectionTitleSliver("Popular / Recommended Pooja"),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: pujasState.when(
                  loading: () => SliverToBoxAdapter(child: _buildVerticalShimmerBox()),
                  error: (e, _) => const SliverToBoxAdapter(child: SizedBox()),
                  data: (pujas) {
                    final recs = pujas.where((p) => p.pujaType == 'regular').take(5).toList();
                    if (recs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPopularCard(recs[index]),
                        childCount: recs.length,
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================
  // 🎨 PROFESSIONAL UI COMPONENTS WITH CLICKS
  // ==========================================

  Widget _buildIconService(BuildContext context, Map<String, dynamic> service) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
      child: InkWell(
        onTap: () {
          if (service['name'].contains('Regular')) context.pushNamed('regular-pujas');
          else if (service['name'].contains('Wedding')) context.pushNamed('wedding-pujas');
          else if (service['name'].contains('Havan')) context.pushNamed('hawan-pujas');
        },
        child: Column(
          children: [
            Container(
              height: 60, width: 60,
              decoration: BoxDecoration(color: (service['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
              child: Icon(service['icon'] as IconData, color: service['color'] as Color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(service['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
          ],
        ),
      ),
    );
  }

  // 🚀 FIXED: InkWell & Material for perfect clicks + Added Price
  Widget _buildFestivalCard(PujaModel puja) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 8), // Shadow space
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias, // Ensures InkWell doesn't leak out of borders
        child: InkWell(
          onTap: () => context.pushNamed('puja-details', extra: puja),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  puja.image, height: 130, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 130, width: double.infinity, color: Colors.orange.shade50, child: const Icon(Icons.temple_hindu, color: Colors.deepOrange)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Text("Limited Slots", style: TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 10),
                      Text(puja.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(puja.title, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),

                      // 💰 ADDED PRICE SECTION HERE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Starts from", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text("₹${puja.price.basePrice.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                            ],
                          ),
                          SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0
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
      ),
    );
  }

  // 🚀 FIXED: InkWell & Material for perfect clicks
  Widget _buildPopularCard(PujaModel puja) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed('puja-details', extra: puja),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Image.network(
                  puja.image, height: 110, width: 110, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 110, width: 110, color: Colors.orange.shade50, child: const Icon(Icons.temple_hindu, color: Colors.deepOrange)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(puja.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(puja.title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("₹${puja.price.basePrice.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(10)),
                              child: const Text('Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
    );
  }

  // --- REUSABLE HELPERS ---

  Widget _buildHeader(String name) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _isLocationLoading ? null : _initLocationSequence,
                    child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.deepOrange, size: 20),
                          const SizedBox(width: 4),
                          Flexible(child: Text(_currentLocationName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          if (_isLocationLoading) const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange))
                          else const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                        ]
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text("Welcome back, $name", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ]
            ),
          ),
          const CircleAvatar(backgroundColor: Colors.deepOrange, child: Icon(Icons.person, color: Colors.white)),
        ],
      ),
    ),
  );

  Widget _buildSearchBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
          height: 52,
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                const Expanded(child: Text("Search for Puja, Pandits...", style: TextStyle(color: Colors.grey, fontSize: 14))),
                Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
                const Icon(Icons.mic, color: Colors.deepOrange, size: 22),
                const SizedBox(width: 16),
              ]
          )
      ),
    ),
  );

  Widget _buildBanner() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SizedBox(
        height: 160,
        child: PageView.builder(
            itemCount: 3,
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(colors: index % 2 == 0 ? [const Color(0xFFFF7A00), const Color(0xFFFF4500)] : [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]),
                  boxShadow: [BoxShadow(color: (index % 2 == 0 ? Colors.orange : Colors.deepPurple).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
              ),
              child: Stack(
                children: [
                  Positioned(right: -20, bottom: -20, child: Icon(Icons.temple_hindu, size: 130, color: Colors.white.withOpacity(0.15))),
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text("Book your first\nPuja today!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2))]
                      )
                  ),
                ],
              ),
            )
        ),
      ),
    ),
  );

  Widget _buildSectionTitleSliver(String title) => SliverToBoxAdapter(
    child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const Text("View All", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        )
    ),
  );

  Widget _buildBottomNav() => Container(
    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))]),
    child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => index == 3 ? context.push('/profile') : setState(() => _currentIndex = index),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 4 - 8,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isSelected ? _navItems[index]['activeIcon'] : _navItems[index]['icon'], color: isSelected ? Colors.deepOrange : Colors.grey.shade400, size: 26),
                          const SizedBox(height: 4),
                          Text(_navItems[index]['label'], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.deepOrange : Colors.grey.shade500)),
                          if (isSelected) Container(height: 4, width: 16, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(2))),
                        ]
                    ),
                  ),
                );
              })
          ),
        )
    ),
  );

  // 🚀 SHIMMERS
  Widget _buildHorizontalShimmerBox() => ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.white, child: Container(width: 250, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))))
  );

  Widget _buildVerticalShimmerBox() => Column(
      children: List.generate(3, (_) => Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.white, child: Container(height: 110, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))))
  );
}