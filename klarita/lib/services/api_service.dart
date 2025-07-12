/// Service layer for handling all API communication with the Klarita backend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task_models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const _storage = FlutterSecureStorage();

  // Helper method to get the authentication token
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Generic POST request helper
  static Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    return http.post(url, headers: headers, body: json.encode(body));
  }

  // ==================================
  // Authentication
  // ==================================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'access_token', value: data['access_token']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  static Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // ==================================
  // AI Task Breakdown
  // ==================================

  static Future<TaskSession> initiateBreakdown({required String goal}) async {
    final response = await _post('/breakdown/initiate', {'goal': goal});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // The response from this endpoint is a BreakdownResponse, which has the same
      // structure as our TaskSession model, so we can parse it directly.
      return TaskSession.fromJson(data);
    } else {
      throw Exception('Failed to initiate task breakdown: ${response.body}');
    }
  }

  // ==================================
  // Gamification
  // ==================================

  static Future<UserGamification> getGamificationStatus() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/gamification/status');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserGamification.fromJson(data);
    } else {
      throw Exception('Failed to get gamification status: ${response.body}');
    }
  }

  static Future<void> completeTask(int taskId) async {
    final response = await _post('/tasks/$taskId/complete', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to complete task: ${response.body}');
    }
  }

  static Future<void> saveSessionAsMemory(int sessionId) async {
    final response = await _post('/sessions/$sessionId/save_as_memory', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to save session as memory: ${response.body}');
    }
  }

  // ==================================
  // "Feeling Stuck" AI Coach
  // ==================================

  static Future<String> getStuckCoachResponse(String message) async {
    final response = await _post('/stuck_coach', {'message': message});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['ai_response'];
    } else {
      throw Exception('Failed to get response from AI coach: ${response.body}');
    }
  }

  static Future<void> submitSessionFeedback({required int sessionId, required int rating, String? comments}) async {
    final payload = {
      'rating': rating,
      if (comments != null && comments.trim().isNotEmpty) 'comments': comments,
    };
    final response = await _post('/sessions/$sessionId/feedback', payload);

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback: ${response.body}');
    }
  }

  static Future<Task> updateTask({required int taskId, required Map<String, dynamic> updates}) async {
    final response = await _post('/tasks/$taskId', updates);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Task.fromJson(data);
    } else {
      throw Exception('Failed to update task: ${response.body}');
    }
  }
} 