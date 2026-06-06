class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? telegramChatId;
  final String role;
  final bool isPremium;
  final int rewardPoints;
  final String quietHoursStart;
  final String quietHoursEnd;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.telegramChatId,
    required this.role,
    required this.isPremium,
    required this.rewardPoints,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      telegramChatId: json['telegram_chat_id'],
      role: json['role'] ?? 'user',
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
      rewardPoints: json['reward_points'] ?? 0,
      quietHoursStart: json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '06:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'telegram_chat_id': telegramChatId,
      'role': role,
      'is_premium': isPremium,
      'reward_points': rewardPoints,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }
}
