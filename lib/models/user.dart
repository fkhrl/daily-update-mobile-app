class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? telegramChatId;
  final String role;
  final String? goal;
  final bool onboardingCompleted;
  final bool isPremium;
  final int rewardPoints;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.telegramChatId,
    required this.role,
    this.goal,
    this.onboardingCompleted = false,
    required this.isPremium,
    required this.rewardPoints,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      telegramChatId: json['telegram_chat_id'],
      role: json['role'] ?? 'user',
      goal: json['goal'],
      onboardingCompleted: json['onboarding_completed'] == 1 || json['onboarding_completed'] == true,
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
      rewardPoints: json['reward_points'] ?? 0,
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      avatar: json['avatar'],
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
      'goal': goal,
      'onboarding_completed': onboardingCompleted,
      'is_premium': isPremium,
      'reward_points': rewardPoints,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'avatar': avatar,
    };
  }
}
