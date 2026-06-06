import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _habits = [];
  bool _isLoading = true;
  final TextEditingController _habitNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getHabits();
      setState(() => _habits = data);
    } catch (e) {
      _showSnackbar('Error loading habits: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHabit(int habitId) async {
    try {
      final updatedHabit = await _apiService.toggleHabit(habitId);
      setState(() {
        final index = _habits.indexWhere((h) => h['id'] == habitId);
        if (index != -1) {
          _habits[index] = updatedHabit;
        }
      });
      _showSnackbar('Habit progress updated!');
    } catch (e) {
      _showSnackbar('Failed to update habit: $e');
    }
  }

  Future<void> _deleteHabit(int habitId) async {
    try {
      await _apiService.deleteHabit(habitId);
      setState(() {
        _habits.removeWhere((h) => h['id'] == habitId);
      });
      _showSnackbar('Habit deleted.');
    } catch (e) {
      _showSnackbar('Failed to delete habit: $e');
    }
  }

  Future<void> _createHabit() async {
    final name = _habitNameController.text.trim();
    if (name.isEmpty) return;

    try {
      final newHabit = await _apiService.createHabit(name);
      setState(() {
        _habits.add(newHabit);
      });
      _habitNameController.clear();
      Navigator.pop(context);
      _showSnackbar('Habit created successfully!');
    } catch (e) {
      _showSnackbar('Failed to create habit: $e');
    }
  }

  void _showAddHabitDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Start New Habit 🪴',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _habitNameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Drink 3L Water, Study, Read books',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Start Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
        title: Text('Habit Tracker', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddHabitDialog,
            icon: const Icon(Icons.add_circle, color: Colors.indigoAccent, size: 28),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No habits tracked yet 🪴',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: _showAddHabitDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Habit'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (ctx, idx) {
                    final habit = _habits[idx];
                    final bool completedToday = habit['is_completed_today'] ?? false;
                    final int streak = habit['streak_count'] ?? 0;

                    return Card(
                      color: const Color(0xFF1E293B).withOpacity(0.6),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: completedToday
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Checkbox toggle
                            InkWell(
                              onTap: () => _toggleHabit(habit['id']),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: completedToday
                                      ? const Color(0xFF10B981).withOpacity(0.2)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: completedToday ? const Color(0xFF10B981) : const Color(0xFF475569),
                                    width: 2,
                                  ),
                                ),
                                child: completedToday
                                    ? const Icon(Icons.check, size: 18, color: Color(0xFF10B981))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),

                            // Habit Name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit['name'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      decoration: completedToday ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Frequency: ${habit['frequency'] ?? 'daily'}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Streak Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: streak > 0 ? Colors.orange.withOpacity(0.15) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: streak > 0 ? Colors.orangeAccent : const Color(0xFF475569),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
                                    style: TextStyle(
                                      color: streak > 0 ? Colors.orangeAccent : const Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Delete button
                            IconButton(
                              onPressed: () => _deleteHabit(habit['id']),
                              icon: const Icon(Icons.delete_outline, color: Color(0xFF475569), size: 20),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
