import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // 🔥 Auto-slide controllers
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);

    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- 📝 EXACT DATA AS PER DOCUMENT ---
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

  final List<Map<String, dynamic>> _upcomingFestivals = [
    {
      'title': 'Mahashivratri Rudrabhishek',
      'date': '8 March 2024',
      'slots': 'Only 5 slots left',
      'image': 'https://images.unsplash.com/photo-1590212046835-b61184d0bd92?q=80&w=800&auto=format&fit=crop',
    },
    {
      'title': 'Ganesh Pooja',
      'date': '7 September 2024',
      'slots': 'Filling fast',
      'image': 'https://images.unsplash.com/photo-1604505963966-2615456f9479?q=80&w=800&auto=format&fit=crop',
    },
    {
      'title': 'Diwali Lakshmi Pooja',
      'date': '1 November 2024',
      'slots': 'Limited slots available',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/fake_image.jpg',
    },
  ];

  final List<Map<String, dynamic>> _popularPujas = [
    {
      'title': 'Satyanarayan Katha',
      'desc': 'Bring peace and prosperity',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Hindu_marriage_ceremony_offerings.jpg/800px-Hindu_marriage_ceremony_offerings.jpg',
    },
    {
      'title': 'Griha Pravesh Pooja',
      'desc': 'Auspicious start for your home',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Homa_fire_ritual_offerings.jpg/800px-Homa_fire_ritual_offerings.jpg',
    },
    {
      'title': 'Navgrah Shanti',
      'desc': 'Balance cosmic energies',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Ganesha_Festival_in_India.jpg/800px-Ganesha_Festival_in_India.jpg',
    },
  ];

  // 🔥 NAYA INDUSTRY-LEVEL NAVIGATION DATA
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home_filled, 'label': 'Home'},
    {'icon': Icons.calendar_today, 'activeIcon': Icons.calendar_month, 'label': 'Bookings'},
    {'icon': Icons.smart_toy_outlined, 'activeIcon': Icons.smart_toy, 'label': 'AI Pandit'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    String userName = "Dhanraj";

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- HEADER ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.deepOrange, size: 20),
                              const SizedBox(width: 4),
                              const Flexible(
                                child: Text(
                                  'Patna, Bihar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome back, $userName ',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.deepOrange,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // --- SEARCH BAR ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search for pujas, pandits...',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ),
                      Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      const Icon(Icons.mic, color: Colors.deepOrange, size: 22),
                    ],
                  ),
                ),
              ),
            ),

            // 🔥 PROMOTIONAL BANNER POSTER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: SizedBox(
                  height: 160,
                  child: PageView.builder(
                    itemCount: 3,
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: index % 2 == 0
                                ? [const Color(0xFFFF7A00), const Color(0xFFFF4500)]
                                : [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (index % 2 == 0 ? Colors.deepOrange : Colors.deepPurple).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(Icons.temple_hindu, size: 130, color: Colors.white.withOpacity(0.15)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('FLAT 20% OFF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Book your first\nPuja today!',
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 🔥 SECTION 1: FEATURED
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Featured Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 24,
                      children: _featuredServices.map((service) => _buildIconService(context, service)).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 SECTION 2: SUBSCRIPTION SERVICES
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subscription Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _subscriptionServices.map((service) => Expanded(child: _buildIconService(context, service))).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 SECTION 3: UPCOMING FESTIVAL POOJA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Upcoming Festival Pooja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                          TextButton(
                              onPressed: () {},
                              child: const Text('View All', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 310,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _upcomingFestivals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return _buildFestivalCard(_upcomingFestivals[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 SECTION 4: POPULAR POOJA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Popular / Recommended Pooja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _popularPujas.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildPopularCard(_popularPujas[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 🚀 THE ULTIMATE FULL-WIDTH DOT INDICATOR TAB BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Halki si shadow taaki ui overlap na ho
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space evenly ensures no side overlapping
              children: List.generate(_navItems.length, (index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = index),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 4 - 8, // Exact calculation to fit items perfectly
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Scale Transition for Icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: Icon(
                            isSelected ? _navItems[index]['activeIcon'] : _navItems[index]['icon'],
                            key: ValueKey(isSelected),
                            color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Text Label
                        Text(
                          _navItems[index]['label'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.deepOrange : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 🔥 THE PREMIUM ANIMATED DOT INDICATOR
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Container(
                            height: 4,
                            width: 16,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // --- 🎨 PREMIUM IMAGE PLACEHOLDER ---
  Widget _buildPremiumPlaceholder(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: Colors.orange.shade50),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.temple_hindu_rounded, color: Colors.deepOrange.withOpacity(0.3), size: height * 0.35),
            const SizedBox(height: 6),
            Text('ShubhNow', style: TextStyle(color: Colors.deepOrange.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS FOR SECTIONS ---

  Widget _buildIconService(BuildContext context, Map<String, dynamic> service) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: (service['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(service['icon'] as IconData, color: service['color'] as Color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            service['name'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFestivalCard(Map<String, dynamic> fest) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            child: Image.network(
              fest['image'] as String,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPremiumPlaceholder(130, double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: Colors.deepOrange),
                      const SizedBox(width: 4),
                      Text(fest['date'] as String, style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(fest['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(fest['slots'] as String, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(Map<String, dynamic> puja) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: Image.network(
              puja['image'] as String,
              height: 110,
              width: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPremiumPlaceholder(110, 100),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(puja['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(puja['desc'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF4500)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}