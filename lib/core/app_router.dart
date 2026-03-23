import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 🔥 TODO: Apne files ka exact path yahan verify kar lena
import '../../Pages/Login_Page/login_screen.dart';
import '../../Pages/Home_Page/home_screen.dart';
import '../Pages/Home_Page/search_screen.dart';
import '../Pages/Puja_Page/hawan_puja_screen.dart';
import '../Pages/Puja_Page/puja_detail_screen.dart';
import '../Pages/Puja_Page/puja_model.dart';
import '../Pages/Puja_Page/regular_puja_screen.dart';
import '../Pages/Puja_Page/wedding_puja_screen.dart';
import '../splash/onboarding_screen.dart';
import '../splash/splash_screen.dart';
import '../../Pages/Profile_Page/profile_screen.dart';

// 🚀 PROFILE PAGES KI IMPORTS
import '../../Pages/Profile_Page/profile_model.dart';
import '../../Pages/Profile_Page/personal_info_screen.dart';
import '../../Pages/Profile_Page/manage_address_screen.dart';

// 🔔 NOTIFICATION SCREEN KI IMPORT (Apna exact path yahan daal lena)
import '../../Pages/Notification_Page/notification_screen.dart'; // <--- YAHAN PATH CHECK KARNA

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

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const OnboardingScreen()),
      ),

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

      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _buildPremiumTransition(context, state, const ProfileScreen()),
      ),

      // 👤 1. PERSONAL INFORMATION ROUTE
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

      // 📍 2. MANAGE ADDRESSES ROUTE
      GoRoute(
        path: '/manage-address',
        name: 'manage-address',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const ManageAddressScreen(),
        ),
      ),

      // 🪔 3. REGULAR PUJAS ROUTE (Naya Integration)
      GoRoute(
        path: '/regular-pujas',
        name: 'regular-pujas',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const RegularPujaScreen(),
        ),
      ),

      GoRoute(
        path: '/wedding-pujas',
        name: 'wedding-pujas',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const WeddingPujaScreen(),
        ),
      ),

      GoRoute(
        path: '/hawan-pujas',
        name: 'hawan-pujas',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const HawanPujaScreen(),
        ),
      ),

      GoRoute(
        path: '/puja-details',
        name: 'puja-details',
        pageBuilder: (context, state) {
          // 🚀 Extra se poora PujaModel nikaal rahe hain
          final puja = state.extra as PujaModel;
          return _buildPremiumTransition(
            context,
            state,
            PujaDetailScreen(puja: puja),
          );
        },
      ),

      // 🔔 4. NOTIFICATION ROUTE (Ye miss tha bhai!)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => _buildPremiumTransition(
          context,
          state,
          const NotificationScreen(), // 👈 Yahan Notification Screen call ho rahi hai
        ),
      ),

      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 🚀 Search page hamesha fade-in hoke khulta hai professional apps mein
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );

  // 🚀 FAST & SNAPPY NATIVE TRANSITION (300ms)
  static CustomTransitionPage _buildPremiumTransition(BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

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