import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'package:toastification/toastification.dart';
import 'dart:ui';
import 'services/biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone for local notifications
  if (!kIsWeb) {
    try {
      tz.initializeTimeZones();
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
      
      await AlarmService.initialize();
    } catch (e) {
      debugPrint('Timezone/Alarm setup error: $e');
    }
  }

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ApiService().reportCrash(details.exceptionAsString(), details.stack?.toString());
  };

  // Catch asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    ApiService().reportCrash(error.toString(), stack.toString());
    return true;
  };
  
  try {
    // Initialize Firebase only for mobile platforms to prevent web adblocker/gstatic errors
    if (!kIsWeb && Firebase.apps.isEmpty) {
      FirebaseOptions options;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
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
      // Initialize Push Notifications
      await NotificationService().initialize();
    }
  } catch (e, stackTrace) {
    // Fallback if Firebase config is missing or not fully initialized
    debugPrint("Firebase init failed: $e\n$stackTrace");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
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
          ),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // Ensure button text is visible
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isOnboarded = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ApiService().getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
      });
      return;
    }

    final biometricEnabled = await BiometricService.isBiometricEnabled();
    if (biometricEnabled) {
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        // If they fail biometrics, they stay on the loading screen or we can log them out.
        // We will push them to login screen for security.
        await ApiService().logout();
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
        return;
      }
    }

    bool isOnboarded = false;
    try {
      final userResponse = await ApiService().getUser();
      isOnboarded = userResponse['onboarding_completed'] == 1 || userResponse['onboarding_completed'] == true;
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        await ApiService().logout();
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
        return;
      } else {
        // Network error or other API error, assume authenticated and onboarded
        // to prevent forced logout on slow/no connection.
        isOnboarded = true; 
      }
    }

    setState(() {
      _isLoading = false;
      _isAuthenticated = true;
      _isOnboarded = isOnboarded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }
    if (!_isAuthenticated) {
      return const LoginScreen();
    }
    return _isOnboarded ? const MainLayout() : const OnboardingScreen();
  }
}

