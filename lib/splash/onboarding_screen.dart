import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 🚀 SHORT, CRISP & HIGHLY EFFECTIVE CONTENT
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Verified Pandits.\nZero Stress.",
      "desc": "Book experienced Pandits and authentic Samagri with just a single tap.",
      "image": "assets/images/onboade1.png"
    },
    {
      "title": "Align Your Stars.\nFind Success.",
      "desc": "Connect with top astrologers for daily insights and accurate Kundali matching.",
      "image": "assets/images/onboard2.png"
    },
    {
      "title": "Your Spiritual\nCompanion.",
      "desc": "From Shubh Muhurat to peaceful Pujas, we handle everything for your devotion.",
      "image": "assets/images/onboard3.png"
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. SKIP BUTTON
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _currentPage == onboardingData.length - 1 ? 0.0 : 1.0,
                  child: TextButton(
                    onPressed: () => context.pushReplacementNamed('login'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),

            // 2. MAIN SLIDER
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // 🔥 YAHAN MAGIC HAI: Text aur Image sab Left Aligned ho gaya
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floating Image Container
                        Container(
                          height: MediaQuery.of(context).size.height * 0.42,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              onboardingData[index]["image"]!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade100,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                    Text("Image missing in assets", style: TextStyle(color: Colors.grey, fontSize: 12))
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // 🔥 LEFT ALIGNED TITLE
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 34, // Thoda font bada kiya left-align ke hisab se
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔥 LEFT ALIGNED DESCRIPTION
                        Text(
                          onboardingData[index]["desc"]!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. BOTTOM NAVIGATION AREA (Dots & Morphing Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                          (index) => _buildDot(index: index),
                    ),
                  ),

                  // Animated Morphing Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage == onboardingData.length - 1) {
                        context.pushReplacementNamed('login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: 64,
                      width: _currentPage == onboardingData.length - 1 ? 160 : 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A00), Color(0xFFFF4500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            );
                          },
                          child: _currentPage == onboardingData.length - 1
                              ? const Text(
                            "Get Started",
                            key: ValueKey("text"),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : const Icon(
                            Icons.arrow_forward_rounded,
                            key: ValueKey("icon"),
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 28 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.deepOrange : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}