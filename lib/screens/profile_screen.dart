import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  User? _user;
  List<dynamic> _sessions = [];
  bool _isLoading = true;

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
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      final sessions = await _apiService.getSessions();
      setState(() {
        _user = profile;
        _sessions = sessions;
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber ?? '';
        _telegramController.text = profile.telegramChatId ?? '';
        _qhStartController.text = profile.quietHoursStart;
        _qhEndController.text = profile.quietHoursEnd;
      });
    } catch (e) {
      _showSnackbar('Failed to load profile data: $e');
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
      _showSnackbar('Failed to update profile: $e');
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
    try {
      await _apiService.updateQuietHours(_qhStartController.text, _qhEndController.text);
      _showSnackbar('Preferences updated successfully!');
      _loadProfileData();
    } catch (e) {
      _showSnackbar('Failed to update quiet hours: $e');
    }
  }

  Future<void> _revokeSession(int id) async {
    try {
      await _apiService.revokeSession(id);
      _showSnackbar('Session revoked.');
      _loadProfileData();
    } catch (e) {
      _showSnackbar('Failed to revoke session: $e');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.indigoAccent, behavior: SnackBarBehavior.floating),
    );
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
                      color: const Color(0xFF1E293B).withOpacity(0.5),
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
                                      color: _user?.isPremium == true ? Colors.amber.withOpacity(0.15) : const Color(0xFF1E293B),
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
                      color: const Color(0xFF1E293B).withOpacity(0.4),
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
                      color: const Color(0xFF1E293B).withOpacity(0.4),
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
                      color: const Color(0xFF1E293B).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Reminders will be suppressed between these hours unless set to Urgent.',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qhStartController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Quiet Hours Start',
                                  labelStyle: TextStyle(color: Colors.indigoAccent, fontSize: 11),
                                  hintText: 'e.g. 22:00',
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: _qhEndController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Quiet Hours End',
                                  labelStyle: TextStyle(color: Colors.indigoAccent, fontSize: 11),
                                  hintText: 'e.g. 06:00',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _updatePreferences,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                          child: const Text('Update Quiet Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 5. Active login tokens list
                  Text('Active User Sessions & Tokens', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  if (_sessions.isEmpty)
                    const Text('No active browser/device tokens found.', style: TextStyle(color: Color(0xFF64748B)))
                  else
                    ..._sessions.map((token) => Card(
                          color: const Color(0xFF1E293B).withOpacity(0.4),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.devices, color: Colors.indigoAccent),
                            title: Text(token['name'] ?? 'Token API', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                              'Created: ${token['created_at'] != null ? token['created_at'].toString().split("T")[0] : "N/A"}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => _revokeSession(token['id']),
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
