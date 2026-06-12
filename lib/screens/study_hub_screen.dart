import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/toast_util.dart';
import 'focus_mode_screen.dart';
import 'routine_timer_screen.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _exams = [];
  List<dynamic> _topics = [];
  List<dynamic> _routines = [];

  final _examTitleCtrl = TextEditingController();
  final _examSubjectCtrl = TextEditingController();
  final _examDateCtrl = TextEditingController();

  final _topicSubjectCtrl = TextEditingController();
  final _topicNameCtrl = TextEditingController();
  
  // Routine controllers
  String _routineDay = 'Monday';
  TimeOfDay? _routineTime;
  int? _editingRoutineId;
  final _routineSubjectCtrl = TextEditingController();
  final _routineReadCtrl = TextEditingController(text: '0');
  final _routineWriteCtrl = TextEditingController(text: '0');
  final _routineMcqCtrl = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getStudyDashboard();
      setState(() {
        _exams = data['exams'];
        _topics = data['topics'];
        _routines = data['routines'] ?? [];
      });
    } catch (e) {
      if (mounted) ToastUtil.showError(context, 'Failed to load study hub: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addExam() async {
    if (_examTitleCtrl.text.isEmpty || _examSubjectCtrl.text.isEmpty || _examDateCtrl.text.isEmpty) return;
    Navigator.pop(context); // Close modal immediately
    try {
      await _apiService.createExam(_examTitleCtrl.text, _examSubjectCtrl.text, _examDateCtrl.text);
      _examTitleCtrl.clear();
      _examSubjectCtrl.clear();
      _examDateCtrl.clear();
      if (!mounted) return;
      _loadDashboard();
      ToastUtil.showSuccess(context, 'Exam added!');
    } catch (e) {
      if (mounted) ToastUtil.showError(context, e.toString());
    }
  }

  Future<void> _addTopic() async {
    if (_topicSubjectCtrl.text.isEmpty || _topicNameCtrl.text.isEmpty) return;
    Navigator.pop(context); // Close modal immediately
    try {
      await _apiService.createStudyTopic(_topicSubjectCtrl.text, _topicNameCtrl.text);
      _topicSubjectCtrl.clear();
      _topicNameCtrl.clear();
      if (!mounted) return;
      _loadDashboard();
      ToastUtil.showSuccess(context, 'Topic added to planner!');
    } catch (e) {
      if (mounted) ToastUtil.showError(context, e.toString());
    }
  }

  Future<void> _addRoutine() async {
    if (_routineSubjectCtrl.text.isEmpty) return;
    Navigator.pop(context); // Close modal immediately
    try {
      final timeStr = _routineTime != null 
          ? '${_routineTime!.hour.toString().padLeft(2, '0')}:${_routineTime!.minute.toString().padLeft(2, '0')}' 
          : null;

      if (_editingRoutineId != null) {
        final updatedRoutine = await _apiService.updateStudyRoutine(
          _editingRoutineId!,
          _routineDay, 
          _routineSubjectCtrl.text, 
          timeStr,
          int.tryParse(_routineReadCtrl.text) ?? 0, 
          int.tryParse(_routineWriteCtrl.text) ?? 0, 
          int.tryParse(_routineMcqCtrl.text) ?? 0
        );
        
        if (_routineTime != null && updatedRoutine != null) {
          await NotificationService().scheduleWeeklyRoutineReminder(
            updatedRoutine['id'], 
            _routineDay, 
            _routineTime!.hour, 
            _routineTime!.minute, 
            _routineSubjectCtrl.text
          );
        } else if (_routineTime == null) {
          await NotificationService().cancelRoutineReminder(_editingRoutineId!);
        }

        if (!mounted) return;
        ToastUtil.showSuccess(context, 'Weekly routine updated!');
      } else {
        final newRoutine = await _apiService.createStudyRoutine(
          _routineDay, 
          _routineSubjectCtrl.text, 
          timeStr,
          int.tryParse(_routineReadCtrl.text) ?? 0, 
          int.tryParse(_routineWriteCtrl.text) ?? 0, 
          int.tryParse(_routineMcqCtrl.text) ?? 0
        );

        if (_routineTime != null && newRoutine != null) {
          await NotificationService().scheduleWeeklyRoutineReminder(
            newRoutine['id'], 
            _routineDay, 
            _routineTime!.hour, 
            _routineTime!.minute, 
            _routineSubjectCtrl.text
          );
        }

        if (!mounted) return;
        ToastUtil.showSuccess(context, 'Weekly routine added!');
      }
      
      _routineSubjectCtrl.clear();
      _routineTime = null;
      _editingRoutineId = null;
      
      if (!mounted) return;
      _loadDashboard();
    } catch (e) {
      if (mounted) ToastUtil.showError(context, e.toString());
    }
  }

  Future<void> _deleteRoutine(int id) async {
    try {
      await _apiService.deleteStudyRoutine(id);
      await NotificationService().cancelRoutineReminder(id);
      if (!mounted) return;
      ToastUtil.showSuccess(context, 'Routine deleted!');
      _loadDashboard();
    } catch (e) {
      if (mounted) ToastUtil.showError(context, e.toString());
    }
  }

  Future<void> _reviseTopic(int id) async {
    try {
      await _apiService.reviseTopic(id);
      if (!mounted) return;
      ToastUtil.showSuccess(context, 'Revision logged! Next revision scheduled.');
      _loadDashboard();
    } catch (e) {
      if (mounted) ToastUtil.showError(context, e.toString());
    }
  }

  void _showAddExamModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Exam Countdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _examTitleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Exam Title (e.g. Finals)', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: _examSubjectCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Subject (e.g. Math)', labelStyle: TextStyle(color: Colors.white70))),
            TextField(
              controller: _examDateCtrl, 
              style: const TextStyle(color: Colors.white), 
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Exam Date', labelStyle: TextStyle(color: Colors.white70)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (date != null) {
                  _examDateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _addExam, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent), child: const Text('Add Exam')),
            const SizedBox(height: 16),
          ],
        ),
      )
    );
  }

  void _showAddRoutineModal([dynamic existingRoutine]) {
    if (existingRoutine != null) {
      _editingRoutineId = existingRoutine['id'];
      _routineDay = existingRoutine['day_of_week'];
      _routineSubjectCtrl.text = existingRoutine['subject'];
      _routineReadCtrl.text = existingRoutine['reading_minutes'].toString();
      _routineWriteCtrl.text = existingRoutine['writing_minutes'].toString();
      _routineMcqCtrl.text = existingRoutine['mcq_minutes'].toString();
      if (existingRoutine['start_time'] != null) {
        final parts = existingRoutine['start_time'].split(':');
        _routineTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _routineTime = null;
      }
    } else {
      _editingRoutineId = null;
      _routineDay = 'Monday';
      _routineSubjectCtrl.clear();
      _routineReadCtrl.text = '0';
      _routineWriteCtrl.text = '0';
      _routineMcqCtrl.text = '10';
      _routineTime = null;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editingRoutineId == null ? 'Add Weekly Routine' : 'Edit Routine', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _routineDay,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                    .map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => _routineDay = val);
                },
              ),
              TextField(controller: _routineSubjectCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Subject (e.g. Biology)', labelStyle: TextStyle(color: Colors.white70))),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _routineTime == null ? 'Select Start Time' : 'Start Time: ${_routineTime!.format(context)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.indigoAccent),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setModalState(() => _routineTime = time);
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _routineReadCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Reading (min)', labelStyle: TextStyle(color: Colors.white70)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _routineWriteCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Writing (min)', labelStyle: TextStyle(color: Colors.white70)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _routineMcqCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'MCQ (min)', labelStyle: TextStyle(color: Colors.white70)))),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _addRoutine, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent), child: const Text('Save Routine')),
              const SizedBox(height: 16),
            ],
          ),
        )
      )
    );
  }

  void _showAddTopicModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Topic to Study Planner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _topicSubjectCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: _topicNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Topic Name', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _addTopic, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent), child: const Text('Add Topic')),
            const SizedBox(height: 16),
          ],
        ),
      )
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final DateTime examDate = DateTime.parse(exam['exam_date']);
    final int daysLeft = examDate.difference(DateTime.now()).inDays;
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: daysLeft <= 3 ? [Colors.redAccent, Colors.orangeAccent] : [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exam['subject'], style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(exam['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(daysLeft < 0 ? 'Passed' : '$daysLeft', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(daysLeft == 1 ? 'day left' : 'days left', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group routines by day
    final Map<String, List<dynamic>> groupedRoutines = {};
    for (var routine in _routines) {
      groupedRoutines.putIfAbsent(routine['day_of_week'], () => []).add(routine);
    }
    final daysOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final sortedDays = groupedRoutines.keys.toList()..sort((a, b) => daysOrder.indexOf(a).compareTo(daysOrder.indexOf(b)));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exams Countdown Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Exams', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: _showAddExamModal, icon: const Icon(Icons.add_circle, color: Colors.indigoAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_exams.isEmpty)
                    const Text('No upcoming exams scheduled.', style: TextStyle(color: Colors.white54))
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _exams.length,
                        itemBuilder: (context, index) => _buildExamCard(_exams[index]),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Focus Timer Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusModeScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.indigoAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.timer, color: Colors.indigoAccent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Focus Session', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Start a pomodoro timer to study', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Weekly Study Routines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Weekly Study Routine', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => _showAddRoutineModal(), icon: const Icon(Icons.add_circle, color: Colors.indigoAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (sortedDays.isEmpty)
                    const Text('No routines scheduled. Add one!', style: TextStyle(color: Colors.white54))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedDays.length,
                      itemBuilder: (context, dayIndex) {
                        final day = sortedDays[dayIndex];
                        final dayRoutines = groupedRoutines[day]!;
                        final isToday = DateFormat('EEEE').format(DateTime.now()) == day;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isToday ? Colors.indigoAccent.withValues(alpha: 0.1) : const Color(0xFF1E293B).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isToday ? Colors.indigoAccent.withValues(alpha: 0.5) : Colors.transparent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day, style: TextStyle(color: isToday ? Colors.indigoAccent : Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ...dayRoutines.map((routine) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineTimerScreen(routine: routine)));
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(routine['subject'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                                  if (routine['start_time'] != null) ...[
                                                    const SizedBox(width: 8),
                                                    Builder(
                                                      builder: (context) {
                                                        String formattedTime = routine['start_time'];
                                                        try {
                                                          final parts = formattedTime.split(':');
                                                          final now = DateTime.now();
                                                          final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
                                                          formattedTime = DateFormat('h:mm a').format(dt);
                                                        } catch (_) {}
                                                        return Text('• $formattedTime', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold));
                                                      }
                                                    ),
                                                  ]
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'R: ${routine['reading_minutes']}m • W: ${routine['writing_minutes']}m • M: ${routine['mcq_minutes']}m', 
                                                style: const TextStyle(color: Colors.white70, fontSize: 12)
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                                              color: const Color(0xFF1E293B),
                                              onSelected: (val) {
                                                if (val == 'edit') {
                                                  _showAddRoutineModal(routine);
                                                } else if (val == 'delete') {
                                                  _deleteRoutine(routine['id']);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.play_circle_fill, color: Colors.indigoAccent, size: 32),
                                              onPressed: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineTimerScreen(routine: routine)));
                                              },
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Revision Tracker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Spaced Repetition Tracker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: _showAddTopicModal, icon: const Icon(Icons.add_circle, color: Colors.indigoAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_topics.isEmpty)
                    const Text('No topics added to your study planner yet.', style: TextStyle(color: Colors.white54))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topics.length,
                      itemBuilder: (context, index) {
                        final topic = _topics[index];
                        final nextRev = topic['next_revision_at'] != null ? DateTime.parse(topic['next_revision_at']) : null;
                        final isDue = nextRev != null && nextRev.isBefore(DateTime.now().add(const Duration(days: 1)));
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDue ? Colors.orangeAccent.withValues(alpha: 0.1) : const Color(0xFF1E293B).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDue ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(topic['subject'], style: const TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(topic['topic_name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextRev == null ? 'Not revised yet' : (isDue ? 'Due for revision!' : 'Next revision: ${DateFormat('MMM dd').format(nextRev)}'), 
                                      style: TextStyle(color: isDue ? Colors.orangeAccent : Colors.white54, fontSize: 12, fontWeight: isDue ? FontWeight.bold : FontWeight.normal)
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _reviseTopic(topic['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDue ? Colors.orangeAccent : const Color(0xFF334155),
                                  foregroundColor: isDue ? Colors.white : Colors.white70,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Mark Revised'),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }
}
