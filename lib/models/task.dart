class Task {
  final int id;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final bool isNotified;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledDate,
    required this.isNotified,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      isNotified: json['is_notified'] == 1 || json['is_notified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduled_date': "${scheduledDate.year.toString().padLeft(4, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}",
      'is_notified': isNotified,
    };
  }
}
