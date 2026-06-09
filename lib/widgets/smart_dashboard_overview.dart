import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class SmartDashboardOverview extends StatefulWidget {
  const SmartDashboardOverview({super.key});

  @override
  State<SmartDashboardOverview> createState() => _SmartDashboardOverviewState();
}

class _SmartDashboardOverviewState extends State<SmartDashboardOverview> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final data = await ApiService().getDashboardMetrics();
      if (mounted) {
        setState(() {
          _metrics = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }

    if (_metrics == null) {
      return const SizedBox.shrink();
    }

    final score = _metrics!['productivity_score'] ?? 0;
    final weeklyChart = _metrics!['weekly_chart'] as List<dynamic>? ?? [];
    final habitProgress = _metrics!['habit_progress'] ?? {};
    final aiSummary = _metrics!['ai_summary'] ?? '';
    final todayFocus = _metrics!['today_focus'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Productivity Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Dashboard',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Productivity Score: $score%',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          score > 75 ? Colors.greenAccent : (score > 40 ? Colors.amberAccent : Colors.redAccent)
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildCircularHabitProgress(habitProgress),
            ],
          ),
          const SizedBox(height: 20),

          // AI Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aiSummary,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Weekly Chart & Today Focus Side-by-Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildWeeklyChart(weeklyChart),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTodayFocus(todayFocus),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularHabitProgress(Map<String, dynamic> habitProgress) {
    final percentage = habitProgress['percentage'] ?? 0;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white12,
            color: Colors.blueAccent,
            strokeWidth: 6,
          ),
          Center(
            child: Text(
              '$percentage%',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<dynamic> weeklyChart) {
    if (weeklyChart.isEmpty) return const SizedBox.shrink();

    List<BarChartGroupData> barGroups = [];
    double maxY = 1;
    
    // The weekly chart data comes from oldest to newest (index 0 is 6 days ago)
    for (int i = 0; i < weeklyChart.length; i++) {
      final count = (weeklyChart[i]['completed'] as num).toDouble();
      if (count > maxY) maxY = count;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: Colors.deepPurpleAccent,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Tasks', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + 1,
                barTouchData: const BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < weeklyChart.length) {
                          return Text(
                            weeklyChart[value.toInt()]['day'].toString().substring(0, 1),
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 16,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFocus(List<dynamic> todayFocus) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today Focus', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Expanded(
            child: todayFocus.isEmpty
                ? const Center(child: Text('No focus tasks', style: TextStyle(color: Colors.white54, fontSize: 11)))
                : ListView.builder(
                    itemCount: todayFocus.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final task = todayFocus[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                task['title'] ?? 'Unknown',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
