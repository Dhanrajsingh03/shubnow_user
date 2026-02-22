import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 🔥 TODO: Apne files ka exact path yahan verify kar lena
import '../../Pages/Login_Page/login_screen.dart';
import '../../Pages/Home_Page/home_screen.dart';
import '../splash/onboarding_screen.dart';
import '../splash/splash_screen.dart';
// 🚀 YAHAN NAYI ONBOARDING SCREEN IMPORT KI HAI

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: ${state.uri.toString()}')),
    ),

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 🚀 NAYA ONBOARDING ROUTE WITH PREMIUM TRANSITION
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const OnboardingScreen()),
      ),

      // 🔥 YAHAN CUSTOM PREMIUM TRANSITION LAGAYI HAI
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const LoginScreen()),
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const HomeScreen()),
      ),
    ],
  );

  // 🚀 INDUSTRY-LEVEL ANIMATION CONTROLLER (Apple / CRED Style)
  static CustomTransitionPage _buildPremiumTransition(BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 800), // Ekdum smooth 0.8 seconds
      transitionsBuilder: (context, animation, secondaryAnimation, child) {

        // 1. Smooth Fade-In Effect
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );

        // 2. Smooth Slide-Up Effect (Neeche se halke se upar aayega)
        final slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }
}