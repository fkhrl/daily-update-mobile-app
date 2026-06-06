import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shake/shake.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'task_form_screen.dart';
import 'referral_screen.dart';
import 'feedback_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        _showFeedbackDialog();
      },
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (_) => const FeedbackDialog(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shakeDetector?.stopListening();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await ApiService().getTasks();
      setState(() {
        _tasks = tasks;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load tasks from API.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTask(int id) async {
    try {
      await ApiService().deleteTask(id);
      setState(() {
        _tasks.removeWhere((t) => t.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  Future<void> _triggerTestEmail() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Triggering email engine...')),
    );
    try {
      final res = await ApiService().triggerNotifications();
      _loadTasks(); // Reload to see updated notification status
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Email Trigger Status', style: TextStyle(color: Colors.white)),
          content: Text(res['message'] ?? 'Successfully executed.', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFF818CF8))),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error triggering notification: $e')),
      );
    }
  }

  List<Task> _filterTasks(int tabIndex) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((task) {
      final taskDate = DateTime(task.scheduledAt.year, task.scheduledAt.month, task.scheduledAt.day);
      if (tabIndex == 0) {
        return taskDate.isAtSameMomentAs(today);
      } else if (tabIndex == 1) {
        return taskDate.isAtSameMomentAs(tomorrow);
      } else {
        return taskDate.isAfter(tomorrow);
      }
    }).toList();
  }

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.amberAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return Colors.greenAccent;
      case 'in_progress':
        return Colors.blueAccent;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.amberAccent;
    }
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No tasks scheduled for this period.',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final Task item = tasks.removeAt(oldIndex);
          tasks.insert(newIndex, item);

          // Update positions in original _tasks list
          final Map<int, int> newPositions = {};
          for (int i = 0; i < tasks.length; i++) {
            newPositions[tasks[i].id] = i;
          }

          _tasks.sort((a, b) {
            final posA = newPositions[a.id];
            final posB = newPositions[b.id];
            if (posA != null && posB != null) {
              return posA.compareTo(posB);
            }
            if (posA != null) return -1;
            if (posB != null) return 1;
            return a.position.compareTo(b.position);
          });
        });

        final List<int> orderedIds = tasks.map((t) => t.id).toList();
        try {
          await ApiService().reorderTasks(orderedIds);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reorder: $e')),
          );
          _loadTasks();
        }
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        final priorityColor = _getPriorityColor(task.priority);
        final statusColor = _getStatusColor(task.status);
        final isOverdue = task.scheduledAt.isBefore(DateTime.now()) &&
            task.status != 'completed' &&
            task.status != 'cancelled';
        final cardBorder = isOverdue
            ? BorderSide(color: Colors.redAccent.withOpacity(0.8), width: 1.8)
            : BorderSide(color: priorityColor.withOpacity(0.3), width: 1);

        return Dismissible(
          key: Key(task.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _deleteTask(task.id),
          child: Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: cardBorder,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  // Category Label Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Priority Dot/Tag
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: priorityColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(task.description!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                  const SizedBox(height: 12),

                  // Metadata Badges Row (Recurrence, Reminders, Checklist)
                  Row(
                    children: [
                      if (task.recurrence != 'none') ...[
                        const Icon(Icons.repeat, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          task.recurrence.toUpperCase(),
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (task.reminders.isNotEmpty) ...[
                        const Icon(Icons.notifications_active_outlined, color: Color(0xFF818CF8), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${task.reminders.length} reminder(s)',
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (task.subtasks.isNotEmpty) ...[
                        const Icon(Icons.checklist, color: Colors.emeraldAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${task.completionPercentage}% checklist',
                          style: const TextStyle(color: Colors.emeraldAccent, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: task.completionPercentage / 100,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.emeraldAccent),
                        minHeight: 3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Time and Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy h:mm a').format(task.scheduledAt),
                            style: TextStyle(
                              color: isOverdue ? Colors.redAccent : const Color(0xFF818CF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                              ),
                              child: const Text(
                                'OVERDUE ⚠️',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (task.isInstant) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Instant',
                                style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                            ),
                            child: Text(
                              task.status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Notification Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.isNotified ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.isNotified ? 'Notified' : 'Pending',
                              style: TextStyle(
                                color: task.isNotified ? Colors.greenAccent : Colors.amberAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
                  );
                  if (result == true) _loadTasks();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAiAssistantDialog(BuildContext context) {
    final textController = TextEditingController();
    bool isParsing = false;
    String? dialogError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFF334155), width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF312E81),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.amberAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI & Voice Task Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Powered by Google Gemini',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Describe your task in natural language. You can type it or tap the microphone button on your keyboard to speak it.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "e.g., meeting with boss tomorrow at 10 AM priority high category work",
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: isParsing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, color: Colors.black),
                      label: Text(
                        isParsing ? 'AI is processing...' : 'Parse Task with AI',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF818CF8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isParsing
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.isEmpty) {
                                setModalState(() {
                                  dialogError = 'Please enter or dictate a task description.';
                                });
                                return;
                              }

                              setModalState(() {
                                isParsing = true;
                                dialogError = null;
                              });

                              try {
                                final data = await ApiService().parseTaskWithAi(text);
                                Navigator.pop(context); // Close sheet

                                // Create dummy Task object with id: 0
                                final parsedTask = Task(
                                  id: 0,
                                  title: data['title'] ?? 'New AI Task',
                                  description: data['description'] ?? '',
                                  scheduledAt: DateTime.tryParse(data['scheduled_at'] ?? '') ??
                                      DateTime.now().add(const Duration(minutes: 10)),
                                  isInstant: false,
                                  isNotified: false,
                                  priority: data['priority'] ?? 'medium',
                                  category: data['category'] ?? 'personal',
                                  status: 'pending',
                                  recurrence: 'none',
                                  recurrenceInterval: 1,
                                  reminders: [],
                                );

                                // Navigate to TaskFormScreen with prefilled task
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TaskFormScreen(task: parsedTask),
                                  ),
                                );
                                if (result == true) {
                                  _loadTasks();
                                }
                              } catch (e) {
                                setModalState(() {
                                  isParsing = false;
                                  dialogError = 'Error: $e';
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B4B),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: Color(0xFF818CF8),
                            size: 40,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TaskDigest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Colors.white70),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Colors.white70),
              title: const Text('Invite Friends', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                ).then((_) => _loadTasks());
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined, color: Colors.white70),
              title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showFeedbackDialog();
              },
            ),
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await ApiService().logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Color(0xFF818CF8),
                    size: 28,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'TaskDigest',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
        actions: [
          IconButton(
            icon: const Icon(Icons.email_outlined, color: Color(0xFF818CF8)),
            tooltip: 'Trigger Notification Mailer',
            onPressed: _triggerTestEmail,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Tomorrow'),
            Tab(text: 'Future'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTasks,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(_filterTasks(0)),
                    _buildTaskList(_filterTasks(1)),
                    _buildTaskList(_filterTasks(2)),
                  ],
                ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'ai_btn',
            backgroundColor: const Color(0xFF818CF8),
            tooltip: 'AI & Voice Assistant',
            child: const Icon(Icons.auto_awesome, color: Colors.white),
            onPressed: () => _showAiAssistantDialog(context),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'add_btn',
            backgroundColor: const Color(0xFF6366F1),
            tooltip: 'Add Task Manually',
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaskFormScreen()),
              );
              if (result == true) _loadTasks();
            },
          ),
        ],
      ),
    );
  }
}
