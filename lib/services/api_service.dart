import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<List<Task>> getTasks() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> list = data['data'];
        return list.map((item) => Task.fromJson(item)).toList();
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
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return Task.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create task');
  }

  Future<Task> updateTask(
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
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Task.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to update task');
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
}
