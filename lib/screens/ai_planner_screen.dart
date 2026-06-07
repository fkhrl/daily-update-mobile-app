import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // AI contents
  List<dynamic> _recommendations = [];
  List<dynamic> _optimalHours = [];
  Map<String, dynamic>? _coachingReport;

  // Task breakdown inputs
  final TextEditingController _taskTitleController = TextEditingController();
  List<dynamic> _breakdownSubtasks = [];
  bool _isBreakingDown = false;

  @override
  void initState() {
    super.initState();
    _loadAiData();
  }

  Future<void> _loadAiData() async {
    setState(() => _isLoading = true);
    try {
      final recs = await _apiService.getAiRecommendedToday();
      final hours = await _apiService.getAiRecommendedHours();
      final report = await _apiService.getAiCoachingTips();
      setState(() {
        _recommendations = recs;
        _optimalHours = hours;
        _coachingReport = report;
      });
    } catch (e) {
      _showSnackbar('Error loading AI advice: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _breakdownTask() async {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isBreakingDown = true);
    try {
      final subtasks = await _apiService.breakdownTaskWithAi(title);
      setState(() {
        _breakdownSubtasks = subtasks;
      });
    } catch (e) {
      _showSnackbar('AI breakdown failed: $e');
    } finally {
      setState(() => _isBreakingDown = false);
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.indigoAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Smart AI Planner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  // 1. Morning Daily Planner Suggestions
                  Text(
                    'AI Recommendation: Top 3 Tasks Today 🎯',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                  ),
                  const SizedBox(height: 10),
                  if (_recommendations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('No pending tasks to rank. Create some tasks first!', style: TextStyle(color: Color(0xFF94A3B8))),
                    )
                  else
                    ..._recommendations.map((item) => Card(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF1E293B)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.indigoAccent, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Task ID: #${item['id']}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['ai_reason'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),

                  const SizedBox(height: 25),

                  // 2. AI Task Breakdown Engine
                  Text(
                    'AI Task Checklist Breakdown ⚙️',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                  ),
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
                        const Text(
                          'Input a large task, and the AI will split it into manageable subtasks instantly.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _taskTitleController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Build product pricing page',
                                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _isBreakingDown ? null : _breakdownTask,
                              icon: _isBreakingDown
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.bolt, color: Colors.indigoAccent, size: 28),
                            ),
                          ],
                        ),

                        // Subtasks output
                        if (_breakdownSubtasks.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 15, bottom: 8),
                            child: Text('Recommended Subtasks Checklist:', style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          ..._breakdownSubtasks.map((st) => Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.indigoAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(st, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                  ],
                                ),
                              )),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 3. Optimal Productivity Hours
                  Text(
                    'Optimal Time Allocations ⏰',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _optimalHours.length,
                      itemBuilder: (ctx, idx) {
                        final item = _optimalHours[idx];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (item['category'] ?? '').toUpperCase(),
                                style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['optimal_time'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['explanation'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 4. AI Coaching Tips
                  if (_coachingReport != null) ...[
                    Text(
                      'AI Productivity Coach Report 🧘',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.indigoAccent,
                                child: Icon(Icons.sentiment_satisfied_alt, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text('Elite Coach Insight', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _coachingReport!['summary'] ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          const Text('COACHING TIPS:', style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                          const SizedBox(height: 5),
                          if (_coachingReport!['tips'] != null)
                            ...(_coachingReport!['tips'] as List).map((tip) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('⚡ ', style: TextStyle(fontSize: 12)),
                                      Expanded(child: Text(tip, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
