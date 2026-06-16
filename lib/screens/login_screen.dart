import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_container.dart';
import 'register_screen.dart';
import 'main_layout.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response['success'] == true) {
        // Sync FCM token to backend
        await NotificationService().syncFcmToken();
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      } else {
        setState(() {
          if (response['errors'] != null && response['errors'] is Map) {
            final Map<String, dynamic> errors = response['errors'];
            final List<String> errorList = [];
            errors.forEach((key, value) {
              if (value is List) {
                errorList.addAll(value.map((e) => e.toString()));
              } else {
                errorList.add(value.toString());
              }
            });
            _errorMessage = errorList.join('\n');
          } else {
            _errorMessage = response['message'] ?? 'Login failed';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Check server connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? 'dummy-client-id.apps.googleusercontent.com' : null, // Replace with your actual Web Client ID for web
        serverClientId: '925566632947-qhm2gt78mjtf6vap178bhtdr8v9k6cuk.apps.googleusercontent.com', // Required for Android to get idToken
        scopes: ['email'],
      );
      final account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.idToken != null) {
          final response = await ApiService().loginWithGoogle(auth.idToken!);
          if (response['success'] == true) {
            await NotificationService().syncFcmToken();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          } else {
            setState(() {
              _errorMessage = response['message'] ?? 'Google Login failed';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Google Login failed: No ID Token provided. Make sure Server Client ID is configured correctly.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In Error: $e\n(Check SHA-1/SHA-256 in Firebase & Web Client ID)';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              key: _formKey,
              child: GlassContainer(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 1),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFF0F172A),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.task_alt, size: 40, color: Colors.indigoAccent);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Title & Subtitle
                    Text(
                      'TaskDigest',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Smart task scheduling with AI assistance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigoAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.indigoAccent),
                        ),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 12),

                    // 4. Password Input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigoAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.indigoAccent),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.length < 6 ? 'Password must be 6+ chars' : null,
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Submit Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Log In',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Social Logins
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: Image.asset('assets/images/google_logo.png', height: 20, width: 20),
                        label: Text('Continue with Google', style: GoogleFonts.outfit(fontSize: 14, color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Navigate to register
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Don\'t have an account? ',
                          style: const TextStyle(color: Colors.white60),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: GoogleFonts.outfit(color: Colors.indigoAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

