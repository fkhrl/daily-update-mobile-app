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
              .map((r) => DateTime.parse(r['remind_at']))
              .toList()
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
    };
  }
}
