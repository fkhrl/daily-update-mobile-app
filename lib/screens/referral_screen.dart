import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late Future<Map<String, dynamic>> _referralData;

  @override
  void initState() {
    super.initState();
    _referralData = ApiService().getReferralStats();
  }

  void _refreshStats() {
    setState(() {
      _referralData = ApiService().getReferralStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Invite Friends', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _referralData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStats,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final referralCode = data['referral_code'] ?? 'N/A';
          final rewardPoints = data['reward_points'] ?? 0;
          final referredFriends = data['referred_friends'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Promo Card
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.card_giftcard, size: 64, color: Colors.amberAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Invite & Get Rewarded!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your referral code with friends. They get 50 points upon signing up, and you earn 100 points!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Stats Row
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('My Points', style: TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                '$rewardPoints pts',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Total Invites', style: TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                '${referredFriends.length}',
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Referral Code Box
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR REFERRAL CODE', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              referralCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: referralCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Referral code copied to clipboard!'),
                                backgroundColor: Color(0xFF6366F1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16, color: Colors.black),
                          label: const Text('Copy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 4. Referred Friends List
                const Text(
                  'Referred Friends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (referredFriends.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'No friends referred yet.',
                          style: TextStyle(color: Colors.white30),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: referredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = referredFriends[index];
                      final name = friend['name'] ?? 'Anonymous';
                      final email = friend['email'] ?? '';
                      final dateStr = friend['created_at'] != null
                          ? DateFormat('MMM d, yyyy').format(DateTime.parse(friend['created_at']))
                          : '';

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF312E81),
                            child: Icon(Icons.person, color: Color(0xFF818CF8)),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(email, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          trailing: Text(
                            dateStr,
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
