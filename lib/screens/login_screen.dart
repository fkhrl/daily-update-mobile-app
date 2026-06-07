import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
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
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF311042)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Card(
                color: const Color(0xFF1E293B).withValues(alpha: 0.65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                ),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Logo with robust fallback
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF312E81).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 60,
                                  color: Color(0xFF818CF8),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Title & Subtitle
                      const Text(
                        'TaskDigest',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smart task scheduling with AI assistance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 3. Email Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@') ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),

                      // 4. Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.length < 6 ? 'Password must be 6+ chars' : null,
                      ),
                      const SizedBox(height: 4),
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
                            style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // 6. Navigate to register
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Don\'t have an account? Sign Up',
                          style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
