import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/task.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator/web/desktop.
  // Change to your machine's IP address if testing on a physical mobile device.
  static const String baseUrl = 'https://dailyupdateapi.fkhrlit.com/api';
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, {String? referralCode}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(null),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      final token = data['data']['access_token'];
      await _saveToken(token);
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(null),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']['access_token'];
      await _saveToken(token);
    }
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: _headers(null),
      body: jsonEncode({
        'id_token': idToken,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']['access_token'];
      await _saveToken(token);
    }
    return data;
  }

  Future<Map<String, dynamic>> loginWithApple(String identityToken, String userId, {String? email, String? name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/apple'),
      headers: _headers(null),
      body: jsonEncode({
        'identity_token': identityToken,
        'user_id': userId,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']['access_token'];
      await _saveToken(token);
    }
    return data;
  }

  Future<Map<String, dynamic>> logout() async {
    final token = await getToken();
    if (token == null) return {'success': true};

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _headers(token),
    );

    await _clearToken();
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUser() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to fetch user data');
  }

  // Scoped by Workspace if workspaceId is provided, also handles pagination and tabs
  Future<Map<String, dynamic>> getTasks({int? workspaceId, String? tab, int page = 1, String? localDate}) async {
    final token = await getToken();
    String url = '$baseUrl/tasks?page=$page';
    if (workspaceId != null) {
      url += '&workspace_id=$workspaceId';
    }
    if (tab != null) {
      url += '&tab=$tab';
    }
    if (localDate != null) {
      url += '&local_date=$localDate';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final paginationData = data['data'];
        final List<dynamic> list = paginationData['data'] ?? paginationData;
        final tasks = list.map((item) => Task.fromJson(item)).toList();
        
        return {
          'tasks': tasks,
          'current_page': paginationData['current_page'] ?? 1,
          'last_page': paginationData['last_page'] ?? 1,
        };
      }
    }
    throw Exception('Failed to load tasks');
  }



  Future<Task> createTask(
    String title,
    String? description,
    DateTime scheduledAt,
    bool isInstant, {
    String priority = 'medium',
    String category = 'personal',
    String status = 'pending',
    String recurrence = 'none',
    int recurrenceInterval = 1,
    List<DateTime>? reminders,
    List<Map<String, dynamic>>? subtasks,
    int? workspaceId,
  }) async {
    final token = await getToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_instant': isInstant,
        'priority': priority,
        'category': category,
        'status': status,
        'recurrence': recurrence,
        'recurrence_interval': recurrenceInterval,
        'reminders': reminders?.map((r) => r.toIso8601String()).toList(),
        if (subtasks != null) 'subtasks': subtasks,
        if (workspaceId != null) 'workspace_id': workspaceId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return Task.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create task');
  }

  Future<Map<String, dynamic>> updateTask(
    int id,
    String title,
    String? description,
    DateTime scheduledAt,
    bool isInstant,
    bool isNotified, {
    String? priority,
    String? category,
    String? status,
    String? recurrence,
    int? recurrenceInterval,
    List<DateTime>? reminders,
    List<Map<String, dynamic>>? subtasks,
    int? workspaceId,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_instant': isInstant,
        'is_notified': isNotified,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        if (recurrence != null) 'recurrence': recurrence,
        if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
        if (reminders != null) 'reminders': reminders.map((r) => r.toIso8601String()).toList(),
        if (subtasks != null) 'subtasks': subtasks,
        'workspace_id': workspaceId, // Can be null to clear
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data; // Return full map containing newly_earned_badges
    }
    throw Exception(data['message'] ?? 'Failed to update task');
  }

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? {};
    }
    return {};
  }

  Future<void> deleteTask(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete task');
    }
  }

  Future<Map<String, dynamic>> triggerNotifications() async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/send-test-notifications'),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> saveFcmToken(String fcmToken) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/save-fcm-token'),
      headers: _headers(token),
      body: jsonEncode({
        'fcm_token': fcmToken,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> parseTaskWithAi(String text) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/parse-task'),
      headers: _headers(token),
      body: jsonEncode({
        'text': text,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to parse task with AI');
  }

  Future<Map<String, dynamic>> getReferralStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/referrals'),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to load referral stats');
  }

  Future<Map<String, dynamic>> submitFeedback(String title, String description, Map<String, dynamic> deviceInfo) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/feedback'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'device_info': deviceInfo,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to submit feedback');
  }

  Future<void> reorderTasks(List<int> taskIds) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/reorder'),
      headers: _headers(token),
      body: jsonEncode({
        'ids': taskIds,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to reorder tasks');
    }
  }

  // ==================== PHASE 2: HABITS & NOTES ====================

  Future<List<dynamic>> getHabits() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/habits'),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to load habits');
  }

  Future<Map<String, dynamic>> createHabit(String name, {String frequency = 'daily', String difficulty = 'medium', String timeOfDay = 'anytime', String? color, String? reminderTime}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/habits'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'frequency': frequency,
        'difficulty': difficulty,
        'time_of_day': timeOfDay,
        if (color != null) 'color': color,
        if (reminderTime != null) 'reminder_time': reminderTime,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to create habit');
  }

  Future<Map<String, dynamic>> toggleHabit(int id) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/habits/$id/toggle'),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to toggle habit');
  }

  Future<void> deleteHabit(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/habits/$id'),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete habit');
    }
  }

  Future<List<dynamic>> getNotes({int? taskId}) async {
    final token = await getToken();
    String url = '$baseUrl/notes';
    if (taskId != null) url += '?task_id=$taskId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to load notes');
  }

  Future<http.MultipartFile> _getMultipartFile(String field, String path) async {
    if (kIsWeb) {
      final response = await http.get(Uri.parse(path));
      return http.MultipartFile.fromBytes(field, response.bodyBytes, filename: 'upload_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      return await http.MultipartFile.fromPath(field, path);
    }
  }

  Future<Map<String, dynamic>> createNote(String content, {int? taskId, String? voicePath, List<String>? images, bool isMarkdown = false, List<String>? tags, String? color}) async {
    final token = await getToken();
    
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/notes'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    
    request.fields['content'] = content;
    request.fields['is_markdown'] = isMarkdown ? '1' : '0';
    if (color != null) {
      request.fields['color'] = color;
    }
    if (tags != null && tags.isNotEmpty) {
      for (int i = 0; i < tags.length; i++) {
        request.fields['tags[$i]'] = tags[i];
      }
    }

    if (taskId != null) {
      request.fields['task_id'] = taskId.toString();
    }

    if (voicePath != null) {
      request.files.add(await _getMultipartFile('voice_note', voicePath));
    }

    if (images != null) {
      for (var imgPath in images) {
        request.files.add(await _getMultipartFile('images[]', imgPath));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to create note');
  }

  Future<void> deleteNote(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/notes/$id'),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete note');
    }
  }

  // ==================== PHASE 3: AI PLANNERS ====================

  Future<List<dynamic>> getAiRecommendedToday() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/ai/recommend-today'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] is String ? jsonDecode(data['data']) : data['data'];
    }
    return [];
  }

  Future<List<dynamic>> getAiRecommendedHours() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/ai/recommend-hours'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] is String ? jsonDecode(data['data']) : data['data'];
    }
    return [];
  }

  Future<List<dynamic>> breakdownTaskWithAi(String title) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/breakdown-task'),
      headers: _headers(token),
      body: jsonEncode({'title': title}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] is String ? List<String>.from(jsonDecode(data['data'])) : List<String>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> getAiCoachingTips() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/ai/coaching-tips'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] is String ? jsonDecode(data['data']) : data['data'];
    }
    throw Exception('Failed to load coaching report');
  }

  // ==================== PHASE 4: COLLABORATION ====================

  Future<List<dynamic>> getWorkspaces() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/workspaces'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception('Failed to load workspaces');
  }

  Future<Map<String, dynamic>> createWorkspace(String name, {String? templateType}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        if (templateType != null) 'template_type': templateType,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to create workspace');
  }

  Future<Map<String, dynamic>> getWorkspaceDetails(int id) async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/workspaces/$id'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception('Failed to load workspace details');
  }

  Future<void> inviteWorkspaceMember(int id, String email, {String role = 'member'}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$id/invite'),
      headers: _headers(token),
      body: jsonEncode({'email': email, 'role': role}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Invitation failed');
    }
  }

  Future<void> leaveWorkspace(int id) async {
    final token = await getToken();
    final response = await http.post(Uri.parse('$baseUrl/workspaces/$id/leave'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to leave workspace');
    }
  }

  Future<List<dynamic>> getTaskComments(int taskId) async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/tasks/$taskId/comments'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    return [];
  }

  Future<Map<String, dynamic>> addTaskComment(int taskId, String content) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/comments'),
      headers: _headers(token),
      body: jsonEncode({'content': content}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to post comment');
  }

  Future<List<dynamic>> getWorkspaceActivity(int id) async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/workspaces/$id/activity'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    return [];
  }

  // ==================== PHASE 5: SECURITY & PREFERENCES ====================

  Future<List<dynamic>> getSessions() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/user/sessions'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    return [];
  }

  Future<void> revokeSession(int tokenId) async {
    final token = await getToken();
    final response = await http.delete(Uri.parse('$baseUrl/user/sessions/$tokenId'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to revoke token');
    }
  }

  Future<List<dynamic>> getLoginHistory() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/user/login-history'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    return [];
  }

  Future<void> updateQuietHours(String? start, String? end) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/user/quiet-hours');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'quiet_hours_enabled': start != null && end != null,
        'quiet_hours_start': start, 
        'quiet_hours_end': end
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update quiet hours');
    }
  }

  // ==================== PHASE 6: MONETIZATION ====================

  Future<User> upgradeToPremium() async {
    final token = await getToken();
    final response = await http.post(Uri.parse('$baseUrl/user/upgrade'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']);
    }
    throw Exception('Upgrade checkout failed');
  }

  Future<User> getProfile() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/user'), headers: _headers(token));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load user profile');
  }

  // ==================== PHASE 7: GAMIFICATION ====================

  Future<List<dynamic>> getBadges() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/badges'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    return [];
  }

  Future<List<dynamic>> getLeaderboard() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/leaderboard'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    return [];
  }

  Future<User> updateProfile(String name, String email, String? phone, String? telegram) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/user/update'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone_number': phone,
        'telegram_chat_id': telegram,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to update profile');
  }

  Future<Map<String, dynamic>> completeOnboarding(String role, String goal) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/user/onboarding'),
      headers: _headers(token),
      body: jsonEncode({
        'role': role,
        'goal': goal,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<void> resetPassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/user/reset-password'),
      headers: _headers(token),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Password reset failed');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: _headers(null),
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp(
      String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password-with-otp'),
      headers: _headers(null),
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': newPassword,
        'password_confirmation': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<void> reportCrash(String errorMessage, String? stackTrace) async {
    final token = await getToken();
    try {
      await http.post(
        Uri.parse('$baseUrl/crash-report'),
        headers: _headers(token),
        body: jsonEncode({
          'error_message': errorMessage,
          'stack_trace': stackTrace,
        }),
      );
    } catch (e) {
      // Ignore errors here to avoid loop
    }
  }

  // ==================== STUDY MODULE ====================

  Future<Map<String, dynamic>> getStudyDashboard() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/study/dashboard'), headers: _headers(token));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception('Failed to load study dashboard');
  }

  Future<void> createExam(String title, String subject, String date) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/study/exams'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'subject': subject,
        'exam_date': date,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create exam');
    }
  }

  Future<void> deleteExam(int id) async {
    final token = await getToken();
    await http.delete(Uri.parse('$baseUrl/study/exams/$id'), headers: _headers(token));
  }

  Future<void> createStudyTopic(String subject, String topic) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/study/topics'),
      headers: _headers(token),
      body: jsonEncode({
        'subject': subject,
        'topic_name': topic,
        'confidence_level': 'medium'
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create topic');
    }
  }

  Future<void> deleteStudyTopic(int id) async {
    final token = await getToken();
    await http.delete(Uri.parse('$baseUrl/study/topics/$id'), headers: _headers(token));
  }

  Future<void> reviseTopic(int id, {String? confidence}) async {
    final token = await getToken();
    final body = confidence != null ? jsonEncode({'confidence_level': confidence}) : null;
    final response = await http.post(
      Uri.parse('$baseUrl/study/topics/$id/revise'),
      headers: _headers(token),
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to revise topic');
    }
  }

  Future<void> createStudyRoutine(String dayOfWeek, String subject, String? startTime, int readingMin, int writingMin, int mcqMin) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/study/routines'),
      headers: _headers(token),
      body: jsonEncode({
        'day_of_week': dayOfWeek,
        'subject': subject,
        if (startTime != null) 'start_time': startTime,
        'reading_minutes': readingMin,
        'writing_minutes': writingMin,
        'mcq_minutes': mcqMin
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create routine');
    }
  }

  Future<void> updateStudyRoutine(int id, String dayOfWeek, String subject, String? startTime, int readingMin, int writingMin, int mcqMin) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/study/routines/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'day_of_week': dayOfWeek,
        'subject': subject,
        'start_time': startTime,
        'reading_minutes': readingMin,
        'writing_minutes': writingMin,
        'mcq_minutes': mcqMin
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update routine');
    }
  }

  Future<void> deleteStudyRoutine(int id) async {
    final token = await getToken();
    await http.delete(Uri.parse('$baseUrl/study/routines/$id'), headers: _headers(token));
  }
}
