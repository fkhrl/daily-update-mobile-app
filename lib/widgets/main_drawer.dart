import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../screens/profile_screen.dart';
import '../screens/workspace_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/ai_planner_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/referral_screen.dart';
import '../screens/security_screen.dart';
import '../screens/login_screen.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userProfile = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _currentUser = userProfile;
        });
      }
    } catch (e) {
      // Ignore user profile fetch error if offline
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  const SizedBox(height: 10),
                  Text(_currentUser?.name ?? 'Loading...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_currentUser != null ? (_currentUser!.isPremium ? 'Premium Member' : 'Free Member') : '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined, color: Colors.white),
              title: const Text('Workspace', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkspaceScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined, color: Colors.white),
              title: const Text('Leaderboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.white),
              title: const Text('AI Planner', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPlannerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined, color: Colors.white),
              title: const Text('Notes', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border_rounded, color: Colors.white),
              title: const Text('Subscription', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.white),
              title: const Text('Refer a Friend', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.security_outlined, color: Colors.white),
              title: const Text('Security & Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                // Close drawer
                Navigator.pop(context);
                
                // Perform actual logout from API (clears session and token)
                try {
                  await ApiService().logout();
                } catch (e) {
                  debugPrint('Logout error: $e');
                }

                if (!context.mounted) return;
                
                // Go to Login Screen
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
