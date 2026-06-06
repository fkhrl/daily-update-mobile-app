import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _successMessage;
  String? _demoOtp;

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await ApiService().forgotPassword(_emailController.text.trim());
      if (response['success'] == true) {
        setState(() {
          _otpSent = true;
          _successMessage = response['message'] ?? 'OTP code has been generated.';
          _demoOtp = response['demo_otp']; // Available in local dev/testing
        });
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
            _errorMessage = response['message'] ?? 'Failed to send OTP. Please try again.';
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

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await ApiService().resetPasswordWithOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _passwordController.text,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password reset successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(); // Go back to login screen
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
            _errorMessage = response['message'] ?? 'Failed to reset password.';
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
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            child: Card(
              color: const Color(0xFF1E293B).withOpacity(0.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5),
              ),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back to login header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Color(0xFF34D399)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Development Mode Demo OTP Box
                    if (_demoOtp != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'DEVELOPMENT MODE OTP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF818CF8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              _demoOtp!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_otpSent) ...[
                      // STEP 1: Request OTP Form
                      Form(
                        key: _emailFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter your registered email address and we will send you a 6-digit OTP code to reset your password.',
                              style: TextStyle(color: Colors.white60, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email Address',
                                hintStyle: const TextStyle(color: Colors.white38),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || !value.contains('@') ? 'Enter a valid email' : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _requestOtp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      'Send Reset OTP',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // STEP 2: Verify OTP and Reset Password Form
                      Form(
                        key: _resetFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '6-digit OTP Code',
                                hintStyle: const TextStyle(color: Colors.white38),
                                prefixIcon: const Icon(Icons.security_outlined, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().length != 6 ? 'Enter a 6-digit OTP code' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'New Password',
                                hintStyle: const TextStyle(color: Colors.white38),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.length < 6 ? 'Password must be 6+ characters' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Confirm New Password',
                                hintStyle: const TextStyle(color: Colors.white38),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.length < 6 ? 'Confirm password' : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      'Reset Password',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _otpSent = false;
                                  _demoOtp = null;
                                  _successMessage = null;
                                  _errorMessage = null;
                                  _otpController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                });
                              },
                              child: const Text(
                                'Resend OTP / Change Email',
                                style: TextStyle(color: Color(0xFF818CF8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
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
