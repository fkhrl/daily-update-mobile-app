class Subtask {
  final int id;
  final int taskId;
  final String title;
  bool isCompleted;
  final int position;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.position,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      taskId: int.tryParse(json['task_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == '1' || json['is_completed'] == true,
      position: int.tryParse(json['position']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'position': position,
    };
  }
}

class Task {
  final int id;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final bool isInstant;
  final bool isNotified;
  final String priority;
  final String category;
  final String status;
  final String recurrence;
  final int recurrenceInterval;
  final List<DateTime> reminders;
  final int position;
  final int completionPercentage;
  final List<Subtask> subtasks;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.isInstant,
    required this.isNotified,
    required this.priority,
    required this.category,
    required this.status,
    required this.recurrence,
    required this.recurrenceInterval,
    required this.reminders,
    required this.position,
    required this.completionPercentage,
    required this.subtasks,
  });

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains(RegExp(r'-[0-9]{2}:[0-9]{2}$'))) {
      dateStr = dateStr.replaceAll(' ', 'T') + 'Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      scheduledAt: _parseDate(json['scheduled_at']?.toString()),
      isInstant: json['is_instant'] == 1 || json['is_instant'] == '1' || json['is_instant'] == true,
      isNotified: json['is_notified'] == 1 || json['is_notified'] == '1' || json['is_notified'] == true,
      priority: json['priority']?.toString() ?? 'medium',
      category: json['category']?.toString() ?? 'personal',
      status: json['status']?.toString() ?? 'pending',
      recurrence: json['recurrence']?.toString() ?? 'none',
      recurrenceInterval: int.tryParse(json['recurrence_interval']?.toString() ?? '1') ?? 1,
      reminders: json['reminders'] != null
          ? (json['reminders'] as List)
              .map((r) => _parseDate(r['remind_at']?.toString() ?? r['reminders']?.toString()))
              .toList()
          : [],
      position: int.tryParse(json['position']?.toString() ?? '0') ?? 0,
      completionPercentage: int.tryParse(json['completion_percentage']?.toString() ?? '0') ?? 0,
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List).map((s) => Subtask.fromJson(s)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_instant': isInstant,
      'is_notified': isNotified,
      'priority': priority,
      'category': category,
      'status': status,
      'recurrence': recurrence,
      'recurrence_interval': recurrenceInterval,
      'reminders': reminders.map((r) => r.toIso8601String()).toList(),
      'position': position,
      'completion_percentage': completionPercentage,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    };
  }
}
