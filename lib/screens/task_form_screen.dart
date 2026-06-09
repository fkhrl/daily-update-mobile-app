import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  bool _isInstant = false;
  bool _isLoading = false;
  String? _errorMessage;

  // New productivity state variables
  String _selectedPriority = 'medium';
  String _selectedCategory = 'personal';
  bool _isCustomCategory = false;
  late TextEditingController _customCategoryController;
  String _selectedStatus = 'pending';
  String _selectedRecurrence = 'none';
  int _recurrenceInterval = 1;

  // Reminders state variables
  bool _remind5Min = false;
  bool _remind30Min = false;
  bool _remind1Hour = false;
  final List<DateTime> _customReminders = [];

  final List<Subtask> _subtasks = [];
  final TextEditingController _subtaskTitleController = TextEditingController();

  // Advanced features state variables
  int? _selectedDependencyId;
  List<Task> _allTasks = [];
  final List<String> _attachmentPaths = [];
  String? _voiceNotePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingVoiceNote = false;

  final List<String> _predefinedCategories = [
    'personal',
    'work',
    'study',
    'shopping',
    'meeting',
    'health',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));
    _isInstant = widget.task?.isInstant ?? false;

    // Initialize new fields in edit mode
    if (widget.task != null) {
      _selectedPriority = widget.task!.priority;
      _selectedStatus = widget.task!.status;
      _selectedRecurrence = widget.task!.recurrence;
      _recurrenceInterval = widget.task!.recurrenceInterval;

      final cat = widget.task!.category.toLowerCase();
      if (_predefinedCategories.contains(cat)) {
        _selectedCategory = cat;
        _isCustomCategory = false;
      } else {
        _selectedCategory = 'custom';
        _isCustomCategory = true;
      }
      _customCategoryController = TextEditingController(text: widget.task!.category);

      // Parse existing reminders
      final taskTime = widget.task!.scheduledAt;
      for (var reminder in widget.task!.reminders) {
        final diff = taskTime.difference(reminder).inMinutes;
        if (diff == 5) {
          _remind5Min = true;
        } else if (diff == 30) {
          _remind30Min = true;
        } else if (diff == 60) {
          _remind1Hour = true;
        } else if (diff == 0) {
          // Default exact-time reminder, ignore for custom UI
        } else {
          _customReminders.add(reminder);
        }
      }
      _subtasks.addAll(widget.task!.subtasks);
      _selectedDependencyId = widget.task!.dependencyId;
      _voiceNotePath = widget.task!.voiceNotePath;
      // We don't automatically load existing attachment paths because they are remote URLs
      // In a real app we'd show them separately. For now, we just allow adding new ones.
    } else {
      _customCategoryController = TextEditingController();
    }
    _loadAllTasks();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingVoiceNote = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _loadAllTasks() async {
    try {
      final res = await ApiService().getTasks(tab: 'future'); // or get all tasks
      if (mounted) {
        setState(() {
          _allTasks = List<Task>.from(res['tasks']);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickAttachments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _attachmentPaths.addAll(result.paths.whereType<String>());
      });
    }
  }

  Future<void> _pickVoiceNote() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _voiceNotePath = result.paths.first;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _subtaskTitleController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (datePicked != null) {
      if (!context.mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF6366F1),
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (timePicked != null) {
        setState(() {
          _selectedDate = DateTime(
            datePicked.year,
            datePicked.month,
            datePicked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _addCustomReminder(BuildContext context) async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF818CF8),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (datePicked != null) {
      if (!context.mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF818CF8),
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (timePicked != null) {
        setState(() {
          _customReminders.add(DateTime(
            datePicked.year,
            datePicked.month,
            datePicked.day,
            timePicked.hour,
            timePicked.minute,
          ));
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Determine category
    final String category = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    if (category.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please specify a category';
      });
      return;
    }

    // Calculate absolute reminder times
    final List<DateTime> finalReminders = [];
    
    // Always include a reminder at the exact task time
    finalReminders.add(_selectedDate);
    if (_remind5Min) {
      finalReminders.add(_selectedDate.subtract(const Duration(minutes: 5)));
    }
    if (_remind30Min) {
      finalReminders.add(_selectedDate.subtract(const Duration(minutes: 30)));
    }
    if (_remind1Hour) {
      finalReminders.add(_selectedDate.subtract(const Duration(hours: 1)));
    }
    finalReminders.addAll(_customReminders);

    final List<Map<String, dynamic>> subtaskPayload = _subtasks.map((s) => {
      'title': s.title,
      'is_completed': s.isCompleted,
    }).toList();

    try {
      final String category = _isCustomCategory ? _customCategoryController.text.trim() : _selectedCategory;
      if (widget.task != null) {
        await ApiService().updateTask(
          widget.task!.id,
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedDate,
          _isInstant,
          widget.task!.isNotified,
          priority: _selectedPriority,
          category: category,
          status: _selectedStatus,
          recurrence: _selectedRecurrence,
          recurrenceInterval: _recurrenceInterval,
          reminders: finalReminders,
          subtasks: subtaskPayload,
          dependencyId: _selectedDependencyId,
          voiceNotePath: _voiceNotePath?.startsWith('http') == true ? null : _voiceNotePath,
          attachmentPaths: _attachmentPaths.isNotEmpty ? _attachmentPaths : null,
        );
      } else {
        await ApiService().createTask(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedDate,
          _isInstant,
          priority: _selectedPriority,
          category: category,
          status: 'pending',
          recurrence: _selectedRecurrence,
          recurrenceInterval: _recurrenceInterval,
          reminders: finalReminders,
          subtasks: subtaskPayload,
          dependencyId: _selectedDependencyId,
          voiceNotePath: _voiceNotePath,
          attachmentPaths: _attachmentPaths.isNotEmpty ? _attachmentPaths : null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save task: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String p) {
    switch (p) {
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                height: 24,
                width: 24,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Color(0xFF818CF8),
                    size: 20,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Edit Task' : 'New Task',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Task Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),

              // 2. Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Priority Selection (ChoiceChips)
              const Text('Priority', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['low', 'medium', 'high', 'urgent'].map((p) {
                  final color = _getPriorityColor(p);
                  final isSelected = _selectedPriority == p;
                  return ChoiceChip(
                    label: Text(
                      p.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? color : Colors.transparent),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPriority = p;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 4. Category & Status Selection (in Edit Mode)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _isCustomCategory ? 'custom' : _selectedCategory,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white),
                              items: [
                                ..._predefinedCategories.map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c[0].toUpperCase() + c.substring(1)),
                                    )),
                                const DropdownMenuItem(
                                  value: 'custom',
                                  child: Text('Custom...'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    if (val == 'custom') {
                                      _isCustomCategory = true;
                                    } else {
                                      _selectedCategory = val;
                                      _isCustomCategory = false;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (isEditing) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white),
                                items: ['pending', 'in_progress', 'completed', 'cancelled']
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.replaceAll('_', ' ').toUpperCase()),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedStatus = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Custom Category Input Field (if selected)
              if (_isCustomCategory) ...[
                TextFormField(
                  controller: _customCategoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Specify Custom Category',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) =>
                      _isCustomCategory && (value == null || value.isEmpty)
                          ? 'Enter a category name'
                          : null,
                ),
                const SizedBox(height: 20),
              ],

              // 5. Recurrence Dropdown
              const Text('Repeat / Recurrence', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRecurrence,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: ['none', 'daily', 'weekly', 'monthly']
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r == 'none' ? 'Do not repeat' : 'Repeat ${r[0].toUpperCase() + r.substring(1)}'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRecurrence = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dependency Task
              const Text('Task Dependency (Blocked By)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedDependencyId,
                    hint: const Text('No Dependency', style: TextStyle(color: Colors.white54)),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No Dependency'),
                      ),
                      ..._allTasks.where((t) => t.id != widget.task?.id).map((t) => DropdownMenuItem<int?>(
                        value: t.id,
                        child: Text(t.title, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedDependencyId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Attachments
              const Text('Attachments & Media', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                      icon: const Icon(Icons.attach_file, color: Colors.indigoAccent),
                      label: Text('Attach Files (${_attachmentPaths.length})', style: const TextStyle(color: Colors.white)),
                      onPressed: _pickAttachments,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                      icon: Icon(_voiceNotePath != null ? Icons.mic : Icons.mic_none, color: Colors.indigoAccent),
                      label: Text(_voiceNotePath != null ? 'Voice Note Added' : 'Add Voice Note', style: const TextStyle(color: Colors.white)),
                      onPressed: _pickVoiceNote,
                    ),
                  ),
                ],
              ),
              if (widget.task?.attachments != null && widget.task!.attachments!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Existing Attachments:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ...widget.task!.attachments!.map((path) {
                  String url = path;
                  if (!url.startsWith('http')) {
                    url = url.startsWith('/storage') ? 'https://dailyupdateapi.fkhrlit.com$url' : 'https://dailyupdateapi.fkhrlit.com/storage/$url';
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(url.split('/').last, style: const TextStyle(color: Colors.blueAccent, fontSize: 12))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (_voiceNotePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isPlayingVoiceNote ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.indigoAccent),
                        onPressed: () async {
                          if (_isPlayingVoiceNote) {
                            await _audioPlayer.pause();
                          } else {
                            if (_voiceNotePath == widget.task?.voiceNotePath) {
                              String url = _voiceNotePath!;
                              if (!url.startsWith('http')) {
                                url = url.startsWith('/storage') ? 'https://dailyupdateapi.fkhrlit.com$url' : 'https://dailyupdateapi.fkhrlit.com/storage/$url';
                              }
                              await _audioPlayer.play(UrlSource(url));
                            } else if (_voiceNotePath!.startsWith('http')) {
                              await _audioPlayer.play(UrlSource(_voiceNotePath!));
                            } else {
                              await _audioPlayer.play(DeviceFileSource(_voiceNotePath!));
                            }
                          }
                        },
                      ),
                      const Text('Preview Voice Note', style: TextStyle(color: Colors.white70)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => setState(() {
                          _voiceNotePath = null;
                          _audioPlayer.stop();
                        }),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // 6. Scheduled Date & Time
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: const Text('Scheduled Date & Time', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  subtitle: Text(
                    DateFormat('EEEE, MMMM d, yyyy h:mm a').format(_selectedDate),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.access_time, color: Color(0xFF818CF8)),
                  onTap: () => _selectDateTime(context),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Smart Reminders Card Group
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Smart Reminders', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('5 minutes before', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        value: _remind5Min,
                        activeColor: const Color(0xFF6366F1),
                        checkColor: Colors.black,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _remind5Min = val ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('30 minutes before', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        value: _remind30Min,
                        activeColor: const Color(0xFF6366F1),
                        checkColor: Colors.black,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _remind30Min = val ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('1 hour before', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        value: _remind1Hour,
                        activeColor: const Color(0xFF6366F1),
                        checkColor: Colors.black,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _remind1Hour = val ?? false;
                          });
                        },
                      ),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      const Text('Custom Reminders', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._customReminders.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final reminder = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy h:mm a').format(reminder),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _customReminders.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _addCustomReminder(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF818CF8),
                          side: const BorderSide(color: Color(0xFF818CF8)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Custom Reminder Time'),
                      ),
                    ],
                  ),
                ),
              ),
              // Subtasks / Checklist UI
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subtasks / Checklist',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_subtasks.isEmpty) ...[
                        const Text('No subtasks added yet.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                      ] else ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _subtasks.length,
                          itemBuilder: (context, index) {
                            final subtask = _subtasks[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Checkbox(
                                value: subtask.isCompleted,
                                activeColor: const Color(0xFF6366F1),
                                checkColor: Colors.black,
                                onChanged: (val) {
                                  setState(() {
                                    subtask.isCompleted = val ?? false;
                                  });
                                },
                              ),
                              title: Text(
                                subtask.title,
                                style: TextStyle(
                                  color: subtask.isCompleted ? Colors.white38 : Colors.white,
                                  decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _subtasks.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskTitleController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Add new checklist item...',
                                hintStyle: TextStyle(color: Colors.white30),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final text = _subtaskTitleController.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  _subtasks.add(Subtask(
                                    id: 0,
                                    taskId: widget.task?.id ?? 0,
                                    title: text,
                                    isCompleted: false,
                                    position: _subtasks.length,
                                  ));
                                  _subtaskTitleController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Removed Instant Notification Switch
              const SizedBox(height: 32),

              // 9. Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Task',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

