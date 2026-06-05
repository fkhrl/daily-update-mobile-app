import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'task_form_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                task.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(task.description!, style: const TextStyle(color: Colors.white70)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy h:mm a').format(task.scheduledAt),
                        style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600),
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
                                fontSize: 11,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('My Daily Updates', style: TextStyle(fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          if (result == true) _loadTasks();
        },
      ),
    );
  }
}
