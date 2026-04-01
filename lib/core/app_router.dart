import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- 🏠 HOME & LOGIN IMPORTS ---
import '../../Pages/Login_Page/login_screen.dart';
import '../../Pages/Home_Page/home_screen.dart';
import '../Pages/Booking_Page/my_bookings_screen.dart';
import '../Pages/Home_Page/search_screen.dart';

// --- 🕉️ PUJA PAGES IMPORTS ---
import '../Pages/Puja_Page/hawan_puja_screen.dart';
import '../Pages/Puja_Page/puja_detail_screen.dart';
import '../Pages/Puja_Page/puja_model.dart';
import '../Pages/Puja_Page/regular_puja_screen.dart';
import '../Pages/Puja_Page/wedding_puja_screen.dart';

// --- 🌊 SPLASH & ONBOARDING ---
import '../splash/onboarding_screen.dart';
import '../splash/splash_screen.dart';

// --- 👤 PROFILE PAGES IMPORTS ---
import '../../Pages/Profile_Page/profile_screen.dart';
import '../../Pages/Profile_Page/profile_model.dart';
import '../../Pages/Profile_Page/personal_info_screen.dart';
import '../../Pages/Profile_Page/manage_address_screen.dart';

// --- 🔔 NOTIFICATION IMPORT ---
import '../../Pages/Notification_Page/notification_screen.dart';

// --- 💳 BOOKING & PAYMENT INTEGRATION IMPORTS (NEW) ---
import '../../Pages/Booking_Page/booking_summary_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',

    // 🛠️ Global Error Handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: ${state.uri.toString()}')),
    ),

    routes: [
      // 1. Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 2. Onboarding with Premium Transition
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const OnboardingScreen()),
      ),

      // 3. Login Screen
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const LoginScreen()),
      ),

      // 4. Home Screen
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const HomeScreen()),
      ),

      // 5. Profile Main Screen
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const ProfileScreen()),
      ),

      // 6. Personal Information (Expects ProfileModel)
      GoRoute(
        path: '/personal-info',
        name: 'personal-info',
        pageBuilder: (context, state) {
          final user = state.extra as ProfileModel;
          return _buildPremiumTransition(
            context,
            state,
            PersonalInfoScreen(user: user),
          );
        },
      ),

      // 7. Manage Address
      GoRoute(
        path: '/manage-address',
        name: 'manage-address',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const ManageAddressScreen(),
        ),
      ),

      // 8. Regular Pujas List
      GoRoute(
        path: '/regular-pujas',
        name: 'regular-pujas',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const RegularPujaScreen(),
        ),
      ),

      // 9. Wedding Pujas List
      GoRoute(
        path: '/wedding-pujas',
        name: 'wedding-pujas',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const WeddingPujaScreen(),
        ),
      ),

      // 10. Hawan Pujas List
      GoRoute(
        path: '/hawan-pujas',
        name: 'hawan-pujas',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const HawanPujaScreen(),
        ),
      ),

      // 11. Puja Details (Expects PujaModel)
      GoRoute(
        path: '/puja-details',
        name: 'puja-details',
        pageBuilder: (context, state) {
          final puja = state.extra as PujaModel;
          return _buildPremiumTransition(
            context,
            state,
            PujaDetailScreen(puja: puja),
          );
        },
      ),

      // 🚀 12. BOOKING SUMMARY / CHECKOUT (INTEGRATED)
      GoRoute(
        path: '/booking-summary',
        name: 'booking-summary',
        pageBuilder: (context, state) {
          final puja = state.extra as PujaModel;
          return _buildPremiumTransition(
            context,
            state,
            BookingSummaryScreen(puja: puja),
          );
        },
      ),

      // 🎉 13. BOOKING SUCCESS (INTEGRATED)

      GoRoute(
        path: '/my-bookings',
        name: 'my-bookings',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const MyBookingsScreen(),
        ),
      ),
      // 🔔 14. Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const NotificationScreen(),
        ),
      ),

      // 🔍 15. Search (Special Fade Transition)
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

    ],
  );

  // ==========================================
  // 🚀 PREMIUM NATIVE TRANSITION ENGINE
  // ==========================================
  static CustomTransitionPage _buildPremiumTransition(BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth Fade
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        // Snappy Slide from Right (5%)
        final slideAnimation = Tween<Offset>(begin: const Offset(0.05, 0.0), end: Offset.zero).animate(
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