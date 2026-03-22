import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/app_router.dart';

// 🔥 Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 USER Background: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase init
  await Firebase.initializeApp();

  // 🔥 Background handler register
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: ShubhNowApp(),
    ),
  );
}

class ShubhNowApp extends ConsumerStatefulWidget {
  const ShubhNowApp({super.key});

  @override
  ConsumerState<ShubhNowApp> createState() => _ShubhNowAppState();
}

class _ShubhNowAppState extends ConsumerState<ShubhNowApp> {

  @override
  void initState() {
    super.initState();
    setupFirebase();
  }

  // 🔥 Firebase setup
  void setupFirebase() async {
    // ✅ Permission
    await FirebaseMessaging.instance.requestPermission();

    // ✅ Token generate
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔥 USER FCM TOKEN: $token");

    // ✅ Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 USER Foreground: ${message.notification?.title}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShubhNow User',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,

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

      routerConfig: AppRouter.router,
    );
  }
}