import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 🔥 TODO: Apne auth provider ka sahi path yahan check kar lena
import '../Pages/Login_Page/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 🔥 Naye variables taaki hum abrupt jumps ko rok sakein
  bool _isExiting = false;
  String _targetRoute = '';

  @override
  void initState() {
    super.initState();

    // 1. Minimum 2.2 Seconds ki Premium Animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Smooth Breathing Scale
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Smooth Fade In
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text Slide Animation
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start Animation
    _animationController.forward().then((_) {
      // Jab animation poori ho jaye, tab route check karo
      _checkAndNavigate();
    });

    // Background mein session check hone do, par redirect hum control karenge
    Future.delayed(Duration.zero, () {
      ref.read(authControllerProvider.notifier).checkSession();
    });
  }

  // 🔥 CUSTOM EXIT ANIMATION FUNCTION
  void _checkAndNavigate() {
    if (_animationController.isCompleted && _targetRoute.isNotEmpty && !_isExiting) {
      setState(() {
        _isExiting = true; // Isse content fade/zoom hoga, background nahi!
      });

      // Exit animation complete hone ke liye 400ms ka wait, fir route push
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          context.pushReplacementNamed(_targetRoute);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Yahan directly redirect karne ki jagah, hum target route save kar rahe hain
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthVerified) {
        _targetRoute = 'home';
      } else if (next is AuthInitial || next is AuthError) {
        _targetRoute = 'onboarding';
      }
      _checkAndNavigate();
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        // 🔥 MAGIC FIX: Ye gradient background ab screen par chipka rahega.
        // Ye fade out nahi hoga, isliye white flash aane ka sawal hi paida nahi hota!
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFD53A00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // 🔥 Sirf andar ka content (Logo/Text) Fade-Out aur Zoom-In hoga
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          opacity: _isExiting ? 0.0 : 1.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInCubic,
            scale: _isExiting ? 1.15 : 1.0, // Exit ke time halke se screen ke paas aake gayab hoga
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Watermark Background
                Positioned(
                  right: -40,
                  top: -40,
                  child: Icon(
                    Icons.temple_hindu_rounded,
                    size: 320,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),

                // 2. Main Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.3 * _fadeAnimation.value),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.temple_hindu,
                                size: 80,
                                color: Color(0xFFFF512F),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Text
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          const Text(
                            'ShubhNow',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Your Spiritual Journey Begins',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}