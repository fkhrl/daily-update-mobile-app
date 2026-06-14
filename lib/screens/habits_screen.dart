import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/toast_util.dart';
import '../widgets/add_medicine_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/alarm_service.dart';
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

  Future<void> _addMedicines(List<Map<String, dynamic>> medicinesData) async {
    Navigator.pop(context); // Close modal immediately
    try {
      final newMeds = await _apiService.addMedicines(medicinesData);
      if (!mounted) return;
      setState(() {
        for (var med in newMeds) {
          med['log'] = {'taken_morning': false, 'taken_afternoon': false, 'taken_night': false};
          _medicines.add(med);
        }
      });
      
      // Schedule local notifications for this medicine
      if (!kIsWeb) {
        // Must use newMeds because they contain the database ID
        await AlarmService.scheduleMedicineAlarms(newMeds.cast<Map<String, dynamic>>());
      }

      _showSnackbar('Medicines added successfully!');
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
    Navigator.pop(context); // Close modal immediately
    try {
      final newHabit = await _apiService.createHabit(name, difficulty: _selectedDifficulty, timeOfDay: _selectedTimeOfDay);
      if (!mounted) return;
      setState(() => _habits.add(newHabit));
      _habitNameController.clear();
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
                      Expanded(child: Text(med['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () => _showEditMedicineDialog(med), icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20)),
                          IconButton(onPressed: () => _deleteMedicine(med['id']), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 0,
                    runSpacing: -8, // slight negative runSpacing to avoid too much vertical gap
                    children: [
                      if (med['morning_time'] != null)
                        _buildMedCheckbox(med['id'], 'morning', log['taken_morning'] == 1 || log['taken_morning'] == true, 'Morning', med['morning_time']),
                      if (med['afternoon_time'] != null)
                        _buildMedCheckbox(med['id'], 'afternoon', log['taken_afternoon'] == 1 || log['taken_afternoon'] == true, 'Afternoon', med['afternoon_time']),
                      if (med['night_time'] != null)
                        _buildMedCheckbox(med['id'], 'night', log['taken_night'] == 1 || log['taken_night'] == true, 'Night', med['night_time']),
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

  String _formatTimeStr(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      String ampm = h >= 12 ? 'PM' : 'AM';
      if (h == 0) h = 12;
      else if (h > 12) h -= 12;
      String hStr = h.toString().padLeft(2, '0');
      String mStr = m.toString().padLeft(2, '0');
      return '$hStr:$mStr $ampm';
    } catch (_) {
      return t;
    }
  }

  Widget _buildMedCheckbox(int id, String period, bool isTaken, String label, String? timeStr) {
    String displayLabel = label;
    if (timeStr != null) {
      displayLabel += ' (${_formatTimeStr(timeStr)})';
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isTaken,
            onChanged: (val) => _toggleMedicine(id, period),
            checkColor: Colors.white,
            activeColor: Colors.indigoAccent,
            side: const BorderSide(color: Colors.white54),
          ),
          Text(displayLabel, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Future<void> _updateMedicine(int id, Map<String, dynamic> data) async {
    try {
      await ApiService().updateMedicine(id, data);
      Navigator.pop(context);
      _showSnackbar('Medicine updated successfully!');

      data['id'] = id;
      if (!kIsWeb) {
        await AlarmService.scheduleMedicineAlarms([data]);
      }

      _loadAllData();
    } catch (e) {
      _showSnackbar('Failed to update medicine: $e', isError: true);
    }
  }

  void _showEditMedicineDialog(Map<String, dynamic> med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => AddMedicineDialog(
        onAddMedicines: _addMedicines,
        editingMedicine: med,
        onEditMedicine: _updateMedicine,
      ),
    );
  }

  void _showAddMedicineDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => AddMedicineDialog(
        onAddMedicines: _addMedicines,
      ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHealthDashboard(),
                  _buildMedicineSection(),
                  _buildHabitsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}
