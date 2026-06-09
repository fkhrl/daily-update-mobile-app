import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  
  bool _isLoading = true;
  
  // Habits Data
  List<dynamic> _habits = [];
  final TextEditingController _habitNameController = TextEditingController();
  final String _selectedDifficulty = 'medium';
  final String _selectedTimeOfDay = 'anytime';

  // Health Data
  int _waterGlasses = 0;
  double _sleepHours = 0.0;

  // Medicine Data
  List<dynamic> _medicines = [];
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _medDurationController = TextEditingController();
  TimeOfDay? _morningTime;
  TimeOfDay? _afternoonTime;
  TimeOfDay? _nightTime;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final habitsData = await _apiService.getHabits();
      final healthData = await _apiService.getHealthToday();
      final medData = await _apiService.getMedicines();
      
      setState(() {
        _habits = habitsData;
        _waterGlasses = int.tryParse(healthData['water_glasses']?.toString() ?? '0') ?? 0;
        _sleepHours = double.tryParse(healthData['sleep_hours']?.toString() ?? '0') ?? 0.0;
        _medicines = medData;
      });
    } catch (e) {
      _showSnackbar('Error loading data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================
  // HEALTH METRICS (WATER & SLEEP)
  // ============================
  Future<void> _updateWater(int delta) async {
    int newValue = _waterGlasses + delta;
    if (newValue < 0) return;
    setState(() => _waterGlasses = newValue);
    try {
      await _apiService.updateWater(newValue);
    } catch (e) {
      setState(() => _waterGlasses = newValue - delta);
      _showSnackbar('Failed to update water', isError: true);
    }
  }

  Future<void> _promptSleepUpdate() async {
    final TextEditingController sleepCtrl = TextEditingController(text: _sleepHours.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Log Sleep (Hours)', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: sleepCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. 7.5',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              double? hours = double.tryParse(sleepCtrl.text);
              if (hours != null) {
                Navigator.pop(ctx);
                setState(() => _sleepHours = hours);
                try {
                  await _apiService.updateSleep(hours);
                } catch (e) {
                  _showSnackbar('Failed to update sleep', isError: true);
                }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // ============================
  // MEDICINES
  // ============================
  Future<void> _addMedicine() async {
    if (_medNameController.text.trim().isEmpty) return;
    try {
      String formatTime(TimeOfDay? t) {
        if (t == null) return '';
        final h = t.hour.toString().padLeft(2, '0');
        final m = t.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }

      String? m = _morningTime != null ? formatTime(_morningTime) : null;
      String? a = _afternoonTime != null ? formatTime(_afternoonTime) : null;
      String? n = _nightTime != null ? formatTime(_nightTime) : null;
      
      int? durationDays = int.tryParse(_medDurationController.text.trim());

      final newMed = await _apiService.addMedicine(_medNameController.text.trim(), m, a, n, durationDays: durationDays);
      setState(() {
        newMed['log'] = {'taken_morning': false, 'taken_afternoon': false, 'taken_night': false};
        _medicines.add(newMed);
      });
      _medNameController.clear();
      _medDurationController.clear();
      _morningTime = null;
      _afternoonTime = null;
      _nightTime = null;
      
      // Schedule local notifications for this medicine
      // Schedule local notifications for this medicine
      if (_morningTime != null && !kIsWeb) {
        // Notification logic here
      }

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackbar('Medicine added successfully!');
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorDialog(context, 'Creation Failed', e);
    }
  }

  Future<void> _deleteMedicine(int id) async {
    try {
      await _apiService.deleteMedicine(id);
      setState(() => _medicines.removeWhere((m) => m['id'] == id));
      _showSnackbar('Medicine deleted');
    } catch (e) {
      _showSnackbar('Failed to delete medicine', isError: true);
    }
  }

  Future<void> _toggleMedicine(int id, String period) async {
    try {
      final log = await _apiService.toggleMedicineLog(id, period);
      setState(() {
        final idx = _medicines.indexWhere((m) => m['id'] == id);
        if (idx != -1) {
          _medicines[idx]['log'] = log;
        }
      });
    } catch (e) {
      _showSnackbar('Failed to toggle medicine log', isError: true);
    }
  }

  // ============================
  // HABITS
  // ============================
  Future<void> _toggleHabit(int habitId) async {
    try {
      final updatedHabit = await _apiService.toggleHabit(habitId);
      setState(() {
        final index = _habits.indexWhere((h) => h['id'] == habitId);
        if (index != -1) {
          _habits[index] = updatedHabit;
        }
      });
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
    } catch (e) {
      // ignore
    }
  }

  Future<void> _createHabit() async {
    final name = _habitNameController.text.trim();
    if (name.isEmpty) return;
    try {
      final newHabit = await _apiService.createHabit(name, difficulty: _selectedDifficulty, timeOfDay: _selectedTimeOfDay);
      setState(() => _habits.add(newHabit));
      _habitNameController.clear();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorDialog(context, 'Creation Failed', e);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      ToastUtil.showError(context, msg);
    } else {
      ToastUtil.showSuccess(context, msg);
    }
  }

  // ============================
  // UI WIDGETS
  // ============================
  Widget _buildHealthDashboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Water
          Column(
            children: [
              const Text('Water', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(onPressed: () => _updateWater(-1), icon: const Icon(Icons.remove_circle_outline, color: Colors.blueAccent)),
                  Text('$_waterGlasses/8', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => _updateWater(1), icon: const Icon(Icons.add_circle, color: Colors.blueAccent)),
                ],
              ),
              const Text('Glasses', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Container(width: 1, height: 60, color: Colors.white24),
          // Sleep
          InkWell(
            onTap: _promptSleepUpdate,
            child: Column(
              children: [
                const Text('Sleep', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.nights_stay, color: Colors.indigoAccent),
                    const SizedBox(width: 8),
                    Text('$_sleepHours', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Hours (Tap to edit)', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medicines & Supplements', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _showAddMedicineDialog, icon: const Icon(Icons.add, color: Colors.indigoAccent)),
            ],
          ),
        ),
        if (_medicines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No medicines added yet.', style: TextStyle(color: Colors.white54)),
          ),
        ..._medicines.map((med) {
          final log = med['log'] ?? {};
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(med['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => _deleteMedicine(med['id']), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (med['morning_time'] != null)
                        _buildMedCheckbox(med['id'], 'morning', log['taken_morning'] == 1 || log['taken_morning'] == true, 'Morning'),
                      if (med['afternoon_time'] != null)
                        _buildMedCheckbox(med['id'], 'afternoon', log['taken_afternoon'] == 1 || log['taken_afternoon'] == true, 'Afternoon'),
                      if (med['night_time'] != null)
                        _buildMedCheckbox(med['id'], 'night', log['taken_night'] == 1 || log['taken_night'] == true, 'Night'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMedCheckbox(int id, String period, bool isTaken, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Checkbox(
            value: isTaken,
            onChanged: (val) => _toggleMedicine(id, period),
            checkColor: Colors.white,
            activeColor: Colors.indigoAccent,
            side: const BorderSide(color: Colors.white54),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  void _showAddMedicineDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Medicine', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 15),
              TextField(
                controller: _medNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Medicine Name',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _medDurationController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Duration (Days) - Optional',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                title: const Text('Morning Time', style: TextStyle(color: Colors.white)),
                trailing: Text(_morningTime?.format(context) ?? 'Not Set', style: const TextStyle(color: Colors.indigoAccent)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                  if (t != null) setModalState(() => _morningTime = t);
                },
              ),
              ListTile(
                title: const Text('Afternoon Time', style: TextStyle(color: Colors.white)),
                trailing: Text(_afternoonTime?.format(context) ?? 'Not Set', style: const TextStyle(color: Colors.indigoAccent)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
                  if (t != null) setModalState(() => _afternoonTime = t);
                },
              ),
              ListTile(
                title: const Text('Night Time', style: TextStyle(color: Colors.white)),
                trailing: Text(_nightTime?.format(context) ?? 'Not Set', style: const TextStyle(color: Colors.indigoAccent)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
                  if (t != null) setModalState(() => _nightTime = t);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addMedicine,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, minimumSize: const Size(double.infinity, 50)),
                child: const Text('Add Medicine'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  // Habits UI is mostly the same as before
  Widget _buildHabitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Habits & Gym', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _showAddHabitDialog, icon: const Icon(Icons.add, color: Colors.indigoAccent)),
            ],
          ),
        ),
        if (_habits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No habits added yet.', style: TextStyle(color: Colors.white54)),
          ),
        ..._habits.map((habit) {
          final bool completedToday = habit['is_completed_today'] == true || habit['is_completed_today'] == 1 || habit['is_completed_today'] == '1';
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Checkbox(
                value: completedToday,
                onChanged: (val) => _toggleHabit(habit['id']),
                checkColor: Colors.white,
                activeColor: Colors.indigoAccent,
                side: const BorderSide(color: Colors.white54),
              ),
              title: Text(habit['name'], style: TextStyle(color: Colors.white, decoration: completedToday ? TextDecoration.lineThrough : null)),
              subtitle: Text('Streak: ${habit['streak_count'] ?? 0} 🔥', style: const TextStyle(color: Colors.orangeAccent)),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteHabit(habit['id'])),
            ),
          );
        }),
      ],
    );
  }

  void _showAddHabitDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Habit', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 15),
              TextField(
                controller: _habitNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Gym, Read Book',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createHabit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, minimumSize: const Size(double.infinity, 50)),
                child: const Text('Add Habit'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Health & Habits', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHealthDashboard(),
                  _buildMedicineSection(),
                  _buildHabitsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
