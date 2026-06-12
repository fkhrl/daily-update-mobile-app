import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/toast_util.dart';
import '../models/user.dart';
import 'security_screen.dart';
import '../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  bool _isUpdatingQuietHours = false;
  bool _quietHoursEnabled = true;
  bool _biometricEnabled = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _qhStartController = TextEditingController();
  final TextEditingController _qhEndController = TextEditingController();

  // Password Reset controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final enabled = await BiometricService.isBiometricEnabled();
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      setState(() {
        _user = profile;
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber ?? '';
        _telegramController.text = profile.telegramChatId ?? '';
        _qhStartController.text = profile.quietHoursStart ?? '22:00';
        _qhEndController.text = profile.quietHoursEnd ?? '08:00';
        _quietHoursEnabled = profile.quietHoursStart != null && profile.quietHoursEnd != null;
      });
    } catch (e) {
      _showSnackbar('Failed to load profile data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      _showSnackbar('Name and Email cannot be empty.');
      return;
    }

    try {
      final updatedUser = await _apiService.updateProfile(
        name,
        email,
        _phoneController.text.trim(),
        _telegramController.text.trim(),
      );
      setState(() {
        _user = updatedUser;
      });
      _showSnackbar('Profile details updated successfully!');
    } catch (e) {
      _showSnackbar('Failed to update profile: $e', isError: true);
    }
  }

  Future<void> _resetPassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnackbar('All password fields are required.');
      return;
    }

    if (newPass != confirm) {
      _showSnackbar('New passwords do not match.');
      return;
    }

    if (newPass.length < 6) {
      _showSnackbar('Password must be at least 6 characters.');
      return;
    }

    try {
      await _apiService.resetPassword(current, newPass);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnackbar('Password updated successfully!');
    } catch (e) {
      _showSnackbar('Password reset failed: $e');
    }
  }

  Future<void> _updatePreferences() async {
    setState(() => _isUpdatingQuietHours = true);
    try {
      await _apiService.updateQuietHours(
        _quietHoursEnabled ? _qhStartController.text : null,
        _quietHoursEnabled ? _qhEndController.text : null,
      );
      _showSnackbar('Preferences updated successfully!');
      await _loadProfileData();
    } catch (e) {
      _showSnackbar('Failed to update quiet hours: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingQuietHours = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      ToastUtil.showError(context, msg);
    } else {
      ToastUtil.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Security & Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.indigoAccent,
                          child: Icon(Icons.person, size: 30, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_user?.name ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(_user?.email ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _user?.isPremium == true ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _user?.isPremium == true ? '👑 PREMIUM' : 'FREE ACCOUNT',
                                      style: TextStyle(
                                        color: _user?.isPremium == true ? Colors.amberAccent : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '⭐ ${_user?.rewardPoints} points',
                                    style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 2. Profile Details & Alert Channels Preferences
                  Text('Update Profile Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'WhatsApp Phone Number',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _telegramController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Telegram Chat ID',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                          child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 3. Password Reset Form
                  Text('Reset Account Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                          child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 4. Quiet Hours Setup
                  Text('Quiet Hours Rules (Stop Reminders)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Quiet Hours', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: const Text('If disabled, notifications are ON all the time.', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                            activeThumbColor: Colors.indigoAccent,
                            value: _quietHoursEnabled,
                            onChanged: (val) {
                              setState(() {
                                _quietHoursEnabled = val;
                              });
                            },
                          ),
                        ),
                        if (_quietHoursEnabled) ...[
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final parts = _qhStartController.text.split(':');
                                    final initial = TimeOfDay(
                                      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 22 : 22,
                                      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                                    );
                                    final time = await showTimePicker(context: context, initialTime: initial);
                                    if (time != null) {
                                      setState(() => _qhStartController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start Time', style: TextStyle(color: Colors.indigoAccent, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(_qhStartController.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final parts = _qhEndController.text.split(':');
                                    final initial = TimeOfDay(
                                      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8,
                                      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                                    );
                                    final time = await showTimePicker(context: context, initialTime: initial);
                                    if (time != null) {
                                      setState(() => _qhEndController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('End Time', style: TextStyle(color: Colors.indigoAccent, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(_qhEndController.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _isUpdatingQuietHours ? null : _updatePreferences,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                          child: _isUpdatingQuietHours
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Update Quiet Hours', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white24),
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Biometric Login', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Use FaceID or Fingerprint to unlock the app securely.', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                            activeThumbColor: Colors.indigoAccent,
                            value: _biometricEnabled,
                            onChanged: (val) async {
                              setState(() {
                                _biometricEnabled = val;
                              });
                              await BiometricService.setBiometricEnabled(val);
                              _showSnackbar('Biometric setting updated');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text('Security', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: const Icon(Icons.security, color: Colors.indigoAccent),
                        title: const Text('Security & Sessions', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Manage your active devices and login history', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
                        },
                      ),
                    ),
                  ),

                ],
              ),
            ),
    );
  }
}

