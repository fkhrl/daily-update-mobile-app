import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../utils/toast_util.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';
class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSavingTasks = false;

  // AI contents
  List<dynamic> _recommendations = [];
  List<dynamic> _optimalHours = [];
  Map<String, dynamic>? _coachingReport;

  // Task breakdown inputs
  final TextEditingController _taskTitleController = TextEditingController();
  List<dynamic> _breakdownSubtasks = [];
  bool _isBreakingDown = false;
  
  // Selected subtasks
  final Set<int> _selectedSubtasks = {};

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
      _showSnackbar('Error loading AI advice: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _breakdownTask() async {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isBreakingDown = true;
      _selectedSubtasks.clear();
      _breakdownSubtasks = [];
    });
    
    try {
      final subtasks = await _apiService.breakdownTaskWithAi(title);
      setState(() {
        _breakdownSubtasks = subtasks;
        // Select all by default
        for (int i = 0; i < subtasks.length; i++) {
          _selectedSubtasks.add(i);
        }
      });
    } catch (e) {
      _showSnackbar('AI breakdown failed: $e', isError: true);
    } finally {
      setState(() => _isBreakingDown = false);
    }
  }

  Future<void> _saveSelectedTasks() async {
    if (_selectedSubtasks.isEmpty) {
      _showSnackbar('Please select at least one task to save.', isError: true);
      return;
    }

    setState(() => _isSavingTasks = true);
    int successCount = 0;
    
    try {
      // Loop through selected items and create tasks
      for (int i in _selectedSubtasks) {
        String subtaskTitle = _breakdownSubtasks[i];
        
        // Strip out leading numbers/bullets if AI returned them e.g. "1. Setup DB" -> "Setup DB"
        subtaskTitle = subtaskTitle.replaceAll(RegExp(r'^[\d\.\-\*\s]+'), '');

        await _apiService.createTask(
          subtaskTitle,
          'AI Generated Subtask for: ${_taskTitleController.text}',
          DateTime.now(), // scheduledAt
          false,          // isInstant
          priority: 'medium',
          status: 'pending',
          workspaceId: null,
        );
        successCount++;
      }
      
      _showSnackbar('Successfully added $successCount tasks to your list!');
      setState(() {
        _breakdownSubtasks.clear();
        _selectedSubtasks.clear();
        _taskTitleController.clear();
      });
      
      // Reload recommendations since tasks changed
      _loadAiData();
    } catch (e) {
      _showSnackbar('Failed to save some tasks: $e', isError: true);
    } finally {
      setState(() => _isSavingTasks = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      ToastUtil.handleApiError(context, 'AI PLANNER', msg);
    } else {
      ToastUtil.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SyncService().isOnline) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Planner & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'AI features require an internet connection.\nPlease go online to use the AI Planner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Smart AI Planner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // 1. Interactive AI Task Breakdown Engine
                      _buildSectionHeader('AI Task Breakdown Engine ⚙️', 'Convert any big project into an actionable plan.'),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: TextField(
                                      controller: _taskTitleController,
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Build product pricing page',
                                        hintStyle: TextStyle(color: Colors.white54),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: _isBreakingDown ? null : _breakdownTask,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: _isBreakingDown
                                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                        : const Icon(Icons.bolt, color: Colors.white, size: 28),
                                  ),
                                ),
                              ],
                            ),

                            // Subtasks Output & Selection
                            if (_breakdownSubtasks.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 10),
                              const Text('Select tasks to add to your database:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 12),
                              
                              ...List.generate(_breakdownSubtasks.length, (index) {
                                final isSelected = _selectedSubtasks.contains(index);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedSubtasks.remove(index);
                                      } else {
                                        _selectedSubtasks.add(index);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.indigoAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isSelected ? Colors.indigoAccent : Colors.transparent),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                                          color: isSelected ? Colors.indigoAccent : Colors.white38,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _breakdownSubtasks[index],
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isSavingTasks || _selectedSubtasks.isEmpty ? null : _saveSelectedTasks,
                                  icon: _isSavingTasks 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : const Icon(Icons.add_task, color: Colors.white),
                                  label: Text(
                                    _isSavingTasks ? 'Saving Tasks...' : 'Add ${_selectedSubtasks.length} Selected to Tasks',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 2. Morning Daily Planner Suggestions
                      _buildSectionHeader('AI Recommendation: Top 3 Tasks Today 🎯', 'Based on priority and deadlines, AI suggests you focus on these.'),
                      const SizedBox(height: 12),
                      if (_recommendations.isEmpty)
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: const Center(child: Text('No pending tasks to rank. Build your plan above!', style: TextStyle(color: Colors.white54))),
                        )
                      else
                        ..._recommendations.map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.indigoAccent.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['ai_reason'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Related to Task #${item['id']}',
                                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),

                      const SizedBox(height: 30),

                      // 3. AI Coaching Tips
                      if (_coachingReport != null) ...[
                        _buildSectionHeader('AI Productivity Coach Report 🧘', 'Weekly insight tailored to your performance.'),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.psychology, color: Colors.amberAccent, size: 28),
                                  const SizedBox(width: 10),
                                  Text('Elite Coach Insight', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _coachingReport!['summary'] ?? '',
                                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(color: Colors.white24),
                              ),
                              const Text('ACTIONABLE TIPS:', style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                              const SizedBox(height: 12),
                              if (_coachingReport!['tips'] != null)
                                ...(_coachingReport!['tips'] as List).map((tip) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('✨', style: TextStyle(fontSize: 14)),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(tip, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                                        ],
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),
                      
                      // 4. Optimal Productivity Hours
                      _buildSectionHeader('Optimal Time Allocations ⏰', 'AI analyzes when you are most productive.'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _optimalHours.length,
                          itemBuilder: (ctx, idx) {
                            final item = _optimalHours[idx];
                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 16),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigoAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (item['category'] ?? '').toUpperCase(),
                                        style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item['optimal_time'] ?? '',
                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Text(
                                        item['explanation'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

