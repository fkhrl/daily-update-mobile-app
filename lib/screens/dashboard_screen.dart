import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  int _activeTab = 0; // 0: Today, 1: Upcoming, 2: Completed

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasksData = await ApiService().getTasks();
      setState(() {
        _tasks = tasksData['tasks'] as List<Task>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    try {
      await ApiService().updateTask(
        task.id,
        task.title,
        task.description,
        task.scheduledAt,
        task.isInstant,
        task.isNotified,
        status: newStatus,
      );
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  List<Task> get _filteredTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_activeTab == 0) { // Today
      return _tasks.where((t) {
        final tDate = DateTime(t.scheduledAt.year, t.scheduledAt.month, t.scheduledAt.day);
        return tDate.isAtSameMomentAs(todayStart) && t.status != 'completed';
      }).toList();
    } else if (_activeTab == 1) { // Upcoming
      return _tasks.where((t) {
        final tDate = DateTime(t.scheduledAt.year, t.scheduledAt.month, t.scheduledAt.day);
        return tDate.isAfter(todayStart) && t.status != 'completed';
      }).toList();
    } else { // Completed
      return _tasks.where((t) => t.status == 'completed').toList();
    }
  }

  int get _dueTodayCount {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      final tDate = DateTime(t.scheduledAt.year, t.scheduledAt.month, t.scheduledAt.day);
      return tDate.isAtSameMomentAs(todayStart) && t.status != 'completed';
    }).length;
  }

  int get _overdueCount {
    final now = DateTime.now();
    return _tasks.where((t) {
      return t.scheduledAt.isBefore(now) && t.status != 'completed';
    }).length;
  }

  double get _completionPercentage {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTasks = _tasks.where((t) {
      final tDate = DateTime(t.scheduledAt.year, t.scheduledAt.month, t.scheduledAt.day);
      return tDate.isAtSameMomentAs(todayStart);
    }).toList();

    if (todayTasks.isEmpty) return 0.0;
    final completed = todayTasks.where((t) => t.status == 'completed').length;
    return completed / todayTasks.length;
  }

  Task? get _todaysFocus {
    final dueToday = _tasks.where((t) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tDate = DateTime(t.scheduledAt.year, t.scheduledAt.month, t.scheduledAt.day);
      return tDate.isAtSameMomentAs(todayStart) && t.status != 'completed';
    }).toList();

    if (dueToday.isEmpty) return null;
    
    // Sort to find highest priority or earliest
    dueToday.sort((a, b) {
      if (a.priority == 'high' && b.priority != 'high') return -1;
      if (b.priority == 'high' && a.priority != 'high') return 1;
      return a.scheduledAt.compareTo(b.scheduledAt);
    });
    return dueToday.first;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // padding bottom for floating nav
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildSmartOverview(),
                  const SizedBox(height: 30),
                  if (_todaysFocus != null) _buildTodaysFocus(_todaysFocus!),
                  if (_todaysFocus != null) const SizedBox(height: 30),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildTaskList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Task', style: TextStyle(color: Color(0xFF818CF8))),
              TextSpan(text: 'Digest', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F172A), width: 2),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildSmartOverview() {
    final completionPct = _completionPercentage;
    final todayTasks = _tasks.where((t) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tDate = DateTime(t.scheduledAt.year, t.scheduledAt.month, t.scheduledAt.day);
      return tDate.isAtSameMomentAs(todayStart);
    }).toList();
    final completedCount = todayTasks.where((t) => t.status == 'completed').length;
    final totalCount = todayTasks.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Smart Overview', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Good Morning, Alex!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Dynamic greeting! We\'ll a task management | key stats.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Colors.tealAccent, size: 14),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'Tasks Due Today',
                                  style: TextStyle(color: Colors.white70, fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('$_dueTodayCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.tealAccent, size: 14),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'Overdue',
                                  style: TextStyle(color: Colors.white70, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('$_overdueCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const Text('Daily Progress', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: CircularPercentIndicator(
                  radius: 60.0,
                  lineWidth: 8.0,
                  animation: true,
                  percent: completionPct.clamp(0.0, 1.0),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(completionPct * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Completed',
                        style: TextStyle(fontSize: 10.0, color: Colors.white70),
                      ),
                      Text(
                        '$completedCount of $totalCount tasks done',
                        style: const TextStyle(fontSize: 8.0, color: Colors.white54),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.white10,
                  linearGradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF6366F1), Color(0xFFC084FC)],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Keep it up!', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTodaysFocus(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Focus', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.track_changes, color: Colors.tealAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upcoming Tasks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildTabItem(0, 'Today'),
              _buildTabItem(1, 'Upcoming'),
              _buildTabItem(2, 'Completed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent': return Colors.redAccent;
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.white54;
    }
  }

  Widget _buildTaskList() {
    final tasks = _filteredTasks;
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No tasks found.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isCompleted = task.status == 'completed';
        final priorityColor = _getPriorityColor(task.priority);

        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _toggleTaskStatus(task),
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1), width: 2),
                    color: isCompleted ? const Color(0xFF6366F1) : Colors.transparent,
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          DateFormat('h:mm a').format(task.scheduledAt),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                          task.category.capitalize(),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            task.priority.capitalize(),
                            style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Assignee placeholder avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF475569),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              )
            ],
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
