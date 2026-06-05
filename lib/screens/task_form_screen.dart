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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.scheduledAt ?? DateTime.now();
    _isInstant = widget.task?.isInstant ?? false;
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.task == null) {
        // Create new task
        await ApiService().createTask(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedDate,
          _isInstant,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
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
