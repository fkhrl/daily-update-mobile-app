import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _badges = [];
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadGamificationData();
  }

  Future<void> _loadGamificationData() async {
    setState(() => _isLoading = true);
    try {
      final badgesList = await _apiService.getBadges();
      final usersList = await _apiService.getLeaderboard();
      setState(() {
        _badges = badgesList;
        _leaderboard = usersList;
      });
    } catch (e) {
      _showSnackbar('Error loading achievements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.indigoAccent, behavior: SnackBarBehavior.floating),
    );
  }

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'star':
        return Icons.star;
      case 'trophy':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'flash_on':
        return Icons.flash_on;
      default:
        return Icons.verified;
    }
  }

  Color _getIconColor(String name) {
    switch (name.toLowerCase()) {
      case 'star':
        return Colors.amberAccent;
      case 'trophy':
        return Colors.yellowAccent;
      case 'local_fire_department':
        return Colors.orangeAccent;
      case 'flash_on':
        return Colors.cyanAccent;
      default:
        return Colors.indigoAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Leaderboard & Badges', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  // 1. Badge Cabinet Grid
                  Text('Achievements Badge Cabinet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: _badges.length,
                    itemBuilder: (ctx, idx) {
                      final b = _badges[idx];
                      final bool earned = b['is_earned'] ?? false;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: earned ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: earned ? Colors.indigoAccent.withValues(alpha: 0.3) : const Color(0xFF1E293B),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconData(b['icon'] ?? 'star'),
                              color: earned ? _getIconColor(b['icon'] ?? 'star') : const Color(0xFF475569),
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b['name'] ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: earned ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b['description'] ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                  color: earned ? Colors.white70 : const Color(0xFF475569),
                                  fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // 2. Users Leaderboard
                  Text('Top Productivity Teammates', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _leaderboard.length,
                      itemBuilder: (ctx, idx) {
                        final u = _leaderboard[idx];
                        final isTopThree = idx < 3;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isTopThree 
                              ? (idx == 0 ? Colors.yellow.shade700 : (idx == 1 ? Colors.grey.shade400 : Colors.orange.shade700))
                              : const Color(0xFF0F172A),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: isTopThree ? Colors.black : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(u['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('Score: ${u['reward_points'] ?? 0} reward points', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigoAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${u['tasks_count'] ?? 0} Done',
                              style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
