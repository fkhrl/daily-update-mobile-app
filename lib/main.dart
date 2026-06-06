import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    if (Firebase.apps.isEmpty) {
      FirebaseOptions options;
      if (kIsWeb) {
        options = const FirebaseOptions(
          apiKey: "AIzaSyAlRE3DokRheJytePJH7BSkTbz8qJA5_7Y", // Browser key
          appId: "1:925566632947:web:73d69f019d92ffbf714886",
          messagingSenderId: "925566632947",
          projectId: "daily-update-app-2ff4c",
          storageBucket: "daily-update-app-2ff4c.firebasestorage.app",
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        options = const FirebaseOptions(
          apiKey: "AIzaSyApPCUo-pVplIS0BGmVHmGqnU2anSmOozg", // iOS key
          appId: "1:925566632947:ios:3bcb8a4c2ab847fa714886",
          messagingSenderId: "925566632947",
          projectId: "daily-update-app-2ff4c",
          storageBucket: "daily-update-app-2ff4c.firebasestorage.app",
          iosBundleId: "com.example.dailyUpdateApp",
        );
      } else {
        // Android fallback configuration
        options = const FirebaseOptions(
          apiKey: "AIzaSyDzsIyWzKZi5OmxVolgUtDfzLvc-H1eCyc", // Android key
          appId: "1:925566632947:android:73d69f019d92ffbf714886",
          messagingSenderId: "925566632947",
          projectId: "daily-update-app-2ff4c",
          storageBucket: "daily-update-app-2ff4c.firebasestorage.app",
        );
      }
      await Firebase.initializeApp(options: options);
    }
    // Initialize Push Notifications
    await NotificationService().initialize();
  } catch (e, stackTrace) {
    // Fallback if Firebase config is missing or not fully initialized
    debugPrint("Firebase init failed: $e\n$stackTrace");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskDigest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
