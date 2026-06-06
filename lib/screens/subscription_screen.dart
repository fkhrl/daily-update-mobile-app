import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final u = await _apiService.getProfile();
      setState(() => _user = u);
    } catch (e) {
      _showSnackbar('Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerUpgrade() async {
    setState(() => _isUpgrading = true);
    try {
      final updatedUser = await _apiService.upgradeToPremium();
      setState(() => _user = updatedUser);
      _showSnackbar('👑 Welcome to Premium Tier! All features unlocked.');
    } catch (e) {
      _showSnackbar('Upgrade simulation failed: $e');
    } finally {
      setState(() => _isUpgrading = false);
    }
  }

  // Handle exports via launching endpoints in browser or downloading
  Future<void> _triggerExport(String type) async {
    final token = await _apiService.getToken();
    if (token == null) return;

    final url = '${ApiService.baseUrl}/export/$type?api_token=$token';
    final uri = Uri.parse(url);

    try {
      // Direct launch or alert instructions
      _showSnackbar('Generating export file... Opening browser.');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackbar('Could not open export download: $e');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.indigoAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPremium = _user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Membership & Backup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Premium Paywall card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isPremium 
                          ? [const Color(0xFFD97706), const Color(0xFFF59E0B)]
                          : [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (isPremium ? Colors.amber : Colors.indigoAccent).withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPremium ? '👑 PREMIUM USER' : 'UPGRADE TO ELITE',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                            if (!isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '\$4.99/mo',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          isPremium ? 'Congratulations!' : 'Unlock Premium Features',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPremium 
                            ? 'You have complete access to categorised tasks, collaborative workspace members, alerts, and dynamic planning.'
                            : 'Create tasks in Work, Health, Study categories. Enable WhatsApp reminders, workspace comments, and PDF backups.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 25),

                        // Main trigger button
                        if (!isPremium)
                          GestureDetector(
                            onTap: _isUpgrading ? null : _triggerUpgrade,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: _isUpgrading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent))
                                  : const Text(
                                      'Upgrade Now (Sandbox Mock)',
                                      style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                            ),
                          )
                        else
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '✓ Lifetime Access Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // 2. Data Exports & Cloud Backups
                  Text('Cloud Backups & Local Exports', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 5),
                  Text(
                    'Export your checklist logs to keep offline records or print details.',
                    style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      // CSV
                      Expanded(
                        child: _exportButton(
                          icon: Icons.table_view,
                          label: 'CSV Data',
                          color: Colors.teal,
                          onPressed: () => _triggerExport('csv'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Excel
                      Expanded(
                        child: _exportButton(
                          icon: Icons.border_all,
                          label: 'Excel File',
                          color: Colors.green,
                          onPressed: () => _triggerExport('excel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // PDF
                      Expanded(
                        child: _exportButton(
                          icon: Icons.picture_as_pdf,
                          label: 'PDF Document',
                          color: Colors.redAccent,
                          onPressed: () => _triggerExport('pdf'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
