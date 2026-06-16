import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_container.dart';
import 'main_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        referralCode: _referralController.text.trim(),
      );

      if (response['success'] == true) {
        // Sync FCM token to backend
        await NotificationService().syncFcmToken();
        
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
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
            _errorMessage = response['message'] ?? 'Registration failed';
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
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
                          radius: 30,
                          backgroundColor: const Color(0xFF0F172A),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person_add_alt_1, size: 35, color: Colors.indigoAccent);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Title
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Join TaskDigest and manage tasks easily',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 20),

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

                    // 3. Name Input
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.indigoAccent, size: 20),
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
                          value == null || value.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),

                    // 4. Email Input
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

                    // 5. Password Input
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
                          value == null || value.length < 6 ? 'Password must be 6+ characters' : null,
                    ),
                    const SizedBox(height: 12),

                    // Referral Code Input
                    TextFormField(
                      controller: _referralController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Referral Code (Optional)',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.card_giftcard, color: Colors.indigoAccent, size: 20),
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
                    ),
                    const SizedBox(height: 24),

                    // 6. Submit Button
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
                        onPressed: _isLoading ? null : _register,
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
                                'Sign Up',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 7. Login navigation
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(color: Colors.white60),
                          children: [
                            TextSpan(
                              text: 'Log In',
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

