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
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      position: json['position'] ?? 0,
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

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      isInstant: json['is_instant'] == 1 || json['is_instant'] == true,
      isNotified: json['is_notified'] == 1 || json['is_notified'] == true,
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? 'personal',
      status: json['status'] ?? 'pending',
      recurrence: json['recurrence'] ?? 'none',
      recurrenceInterval: json['recurrence_interval'] ?? 1,
      reminders: json['reminders'] != null
          ? (json['reminders'] as List)
              .map((r) => DateTime.parse(r['remind_at'] ?? r['reminders'] ?? ''))
              .toList()
          : [],
      position: json['position'] ?? 0,
      completionPercentage: json['completion_percentage'] ?? 0,
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
