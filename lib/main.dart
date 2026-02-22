import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_router.dart';

void main() async {
  // Flutter engine initialization (Required before using secure storage or other native bindings)
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope is mandatory to enable Riverpod across the entire app
  runApp(
    const ProviderScope(
      child: ShubhNowApp(),
    ),
  );
}

class ShubhNowApp extends StatelessWidget {
  const ShubhNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShubhNow User',
      debugShowCheckedModeBanner: false, // Removes the red debug banner

      // 🎨 Global Theme Setup (Deep Orange for that Spiritual/Startup vibe)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,

        // Universal Input Decoration for clean TextFields across the app
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        // Universal Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // 🚦 Connecting the GoRouter configuration here
      routerConfig: AppRouter.router,
    );
  }
}