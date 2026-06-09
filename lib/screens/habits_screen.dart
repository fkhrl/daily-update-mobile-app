import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _habits = [];
  bool _isLoading = true;
  final TextEditingController _habitNameController = TextEditingController();
  String _selectedDifficulty = 'medium';
  String _selectedTimeOfDay = 'anytime';

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
      _showSnackbar('Error loading habits: $e', isError: true);
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
      _showSnackbar('Failed to update habit: $e', isError: true);
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
      _showSnackbar('Failed to delete habit: $e', isError: true);
    }
  }

  Future<void> _createHabit() async {
    final name = _habitNameController.text.trim();
    if (name.isEmpty) return;

    try {
      final newHabit = await _apiService.createHabit(
        name,
        difficulty: _selectedDifficulty,
        timeOfDay: _selectedTimeOfDay,
      );
      setState(() {
        _habits.add(newHabit);
      });
      _habitNameController.clear();
      _selectedDifficulty = 'medium';
      _selectedTimeOfDay = 'anytime';
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackbar('Habit created successfully!');
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorDialog(context, 'Creation Failed', e);
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
            const SizedBox(height: 15),
            Text('Difficulty', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (c, setLocalState) {
              return Wrap(
                spacing: 8,
                children: ['easy', 'medium', 'hard'].map((level) {
                  return ChoiceChip(
                    label: Text(level.toUpperCase()),
                    selected: _selectedDifficulty == level,
                    onSelected: (val) {
                      if (val) {
                        setLocalState(() => _selectedDifficulty = level);
                        _selectedDifficulty = level; // update outer state
                      }
                    },
                    selectedColor: Colors.indigoAccent,
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: _selectedDifficulty == level ? Colors.white : Colors.white54, fontSize: 11),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 15),
            Text('Time of Day', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (c, setLocalState) {
              return Wrap(
                spacing: 8,
                children: ['morning', 'afternoon', 'evening', 'anytime'].map((time) {
                  return ChoiceChip(
                    label: Text(time.toUpperCase()),
                    selected: _selectedTimeOfDay == time,
                    onSelected: (val) {
                      if (val) {
                        setLocalState(() => _selectedTimeOfDay = time);
                        _selectedTimeOfDay = time;
                      }
                    },
                    selectedColor: Colors.indigoAccent,
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: _selectedTimeOfDay == time ? Colors.white : Colors.white54, fontSize: 11),
                  );
                }).toList(),
              );
            }),
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
              child: const Text('Start Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      ToastUtil.showError(context, msg);
    } else {
      ToastUtil.showSuccess(context, msg);
    }
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
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: _showAddHabitDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Create Habit', style: TextStyle(color: Colors.white)),
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
                    final bool completedToday = habit['is_completed_today'] == true || 
                                                habit['is_completed_today'] == 1 || 
                                                habit['is_completed_today'] == '1';
                    final int streak = int.tryParse(habit['streak_count']?.toString() ?? '0') ?? 0;
                    final int habitId = int.tryParse(habit['id']?.toString() ?? '0') ?? 0;

                    return Card(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: completedToday
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Checkbox toggle
                            InkWell(
                              onTap: () => _toggleHabit(habitId),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: completedToday
                                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
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
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Text(
                                        'Freq: ${habit['frequency'] ?? 'daily'}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                      Text(
                                        'Diff: ${habit['difficulty'] ?? 'medium'}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                      Text(
                                        'Time: ${habit['time_of_day'] ?? 'anytime'}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Streak Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: streak > 0 ? Colors.orange.withValues(alpha: 0.15) : const Color(0xFF1E293B),
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
                              onPressed: () => _deleteHabit(habitId),
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

