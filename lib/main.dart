import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🔥 Sahi paths check kar lena apne project ke hisaab se
import 'core/app_router.dart';
import 'Pages/Notification_Page/notification_service.dart';

// ==========================================
// 🛡️ TOP-LEVEL BACKGROUND HANDLER
// ==========================================
// Firebase ko ye function class ke bahar chahiye hota hai.
// Ye tab chalta hai jab app minimize ho ya kill ho chuki ho.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 USER Background Notification: ${message.notification?.title}");
}

void main() async {
  // 1. Flutter Engine ko native calls ke liye ready karna
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase ko initialize karna
  await Firebase.initializeApp();

  // 3. Background Message Handler register karna
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
    // 🚀 App load hote hi Firebase setup aur routing listeners on ho jayenge
    setupFirebase();
  }

  // 🔥 Firebase setup logic (Siddha NotificationService use kiya hai)
  void setupFirebase() async {
    try {
      // 1. Humari unified service ko call karna (Token generate + Routing listeners)
      // Ye function wahi hai jo tera Provider call karta hai,
      // isliye architecture ekdum intact rahega.
      await NotificationService().generateAndSendFCMToken();

      // 2. Foreground listener (App khuli hai tab notification aaye toh console me dikhe)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("🔔 USER Foreground Notification: ${message.notification?.title}");
        // Future me yahan tu Local Notification popup dikha sakta hai
      });

      print("✅ Firebase Messaging & Deep-Linking Initialized");
    } catch (e) {
      print("❌ Firebase Setup Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShubhNow User',
      debugShowCheckedModeBanner: false,

      // 🎨 Industry Standard Material 3 Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.orangeAccent,
        ),

        // Global TextField Style
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

        // Global Button Style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),

      // 🚀 Routing via GoRouter (Jisme humne NavigatorKey dali hui hai)
      routerConfig: AppRouter.router,
    );
  }
}