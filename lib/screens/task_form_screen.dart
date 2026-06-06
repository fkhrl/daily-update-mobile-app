import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({Key? key, this.task}) : super(key: key);

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
        } else {
          _customReminders.add(reminder);
        }
      }
    } else {
      _customCategoryController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
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
      if (!mounted) return;
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
      if (!mounted) return;
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

    try {
      if (widget.task == null) {
        // Create new task
        await ApiService().createTask(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedDate,
          _isInstant,
          priority: _selectedPriority,
          category: category,
          status: _selectedStatus,
          recurrence: _selectedRecurrence,
          recurrenceInterval: _recurrenceInterval,
          reminders: finalReminders,
        );
      } else {
        // Update existing task
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
        );
      }
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
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
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
                      }).toList(),
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
              const SizedBox(height: 20),

              // 8. Instant Notification Switch
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Instant Notification', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Send email and push notification immediately', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  value: _isInstant,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (bool value) {
                    setState(() {
                      _isInstant = value;
                    });
                  },
                ),
              ),
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
