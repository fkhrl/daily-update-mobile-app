class Task {
  final int id;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final bool isInstant;
  final bool isNotified;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.isInstant,
    required this.isNotified,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      isInstant: json['is_instant'] == 1 || json['is_instant'] == true,
      isNotified: json['is_notified'] == 1 || json['is_notified'] == true,
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
    };
  }
}
