/// Service layer for handling all API communication with the Klarita backend.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/task_models.dart';
import '../models/analytics_models.dart';

/// Thrown when the server returns HTTP 401. Allows callers to specifically
/// detect an authentication failure and react (e.g. force-logout).
class UnauthorizedException extends HttpException {
  UnauthorizedException(String message) : super(message);
}

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const _storage = FlutterSecureStorage();

  // Central place to wipe credentials when backend says 401.
  static Future<void> _handleUnauthorized(String body) async {
    await _storage.delete(key: 'access_token');
    throw UnauthorizedException(body);
  }

  // Helper method to get the authentication token
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Generic POST request helper with retry logic
  static Future<http.Response> _post(String endpoint, Map<String, dynamic> body, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final token = await _getToken();
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final response = await http.post(url, headers: headers, body: json.encode(body));
        if (response.statusCode == 401) {
          await _handleUnauthorized(response.body);
        }
        return response;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow; // Last attempt failed, throw the error
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw Exception('Request failed after $maxRetries attempts');
  }

  // Generic PATCH request helper with retry logic
  static Future<http.Response> _patch(String endpoint, Map<String, dynamic> body, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final token = await _getToken();
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final response = await http.patch(url, headers: headers, body: json.encode(body));
        if (response.statusCode == 401) {
          await _handleUnauthorized(response.body);
        }
        return response;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw Exception('Request failed after $maxRetries attempts');
  }

  // Generic GET request helper with retry logic
  static Future<http.Response> _get(String endpoint, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final token = await _getToken();
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final response = await http.get(url, headers: headers);
        if (response.statusCode == 401) {
          await _handleUnauthorized(response.body);
        }
        return response;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw Exception('Request failed after $maxRetries attempts');
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
    final response = await _get('/gamification/status');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserGamification.fromJson(data);
    }

    throw Exception('Failed to get gamification status: ${response.body}');
  }

  // Marks a task as completed and optionally sends the actual time spent.
  // Returns the raw response body so that callers (e.g. GamificationProvider)
  // can parse XP earned or other metadata if the backend chooses to return it.
  static Future<Map<String, dynamic>> completeTask(
    int taskId, {
    int? actualMinutes,
  }) async {
    // Build endpoint with optional query param so it matches FastAPI signature
    var endpoint = '/tasks/$taskId/complete';
    if (actualMinutes != null) {
      endpoint += '?actual_minutes=$actualMinutes';
    }

    final response = await _post(endpoint, {}); // body left empty; all params in query

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      // Fallback when backend returns 200 with empty body
      return {};
    } else {
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
    final response = await _patch('/tasks/$taskId', updates);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Task.fromJson(data);
    } else {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  static Future<void> reorderTasks({required int sessionId, required List<int> orderedIds}) async {
    final response = await _patch('/sessions/$sessionId/reorder', {
      'ordered_task_ids': orderedIds,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tasks: ${response.body}');
    }
  }

  static Future<Task> mergeTasks(List<int> taskIds) async {
    final response = await _post('/tasks/merge', {
      'task_ids': taskIds,
    });
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Task.fromJson(data);
    } else {
      throw Exception('Failed to merge tasks: ${response.body}');
    }
  }

  // ==================================
  // Analytics Endpoints
  // ==================================

  /// Get comprehensive analytics summary for the current user
  static Future<AnalyticsSummary> getAnalyticsSummary() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/analytics/summary');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AnalyticsSummary.fromJson(data);
    } else if (response.statusCode == 401) {
      await _handleUnauthorized(response.body);
    }

    throw Exception('Failed to get analytics summary: ${response.body}');
  }

  /// Get analytics trends for a specific period
  static Future<AnalyticsTrends> getAnalyticsTrends({String period = 'week'}) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/analytics/trends?period=$period');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AnalyticsTrends.fromJson(data);
    } else if (response.statusCode == 401) {
      await _handleUnauthorized(response.body);
    }

    throw Exception('Failed to get analytics trends: ${response.body}');
  }

  /// Get task completion statistics by category
  static Future<List<CategoryStats>> getCategoryAnalytics() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/analytics/categories');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => CategoryStats.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await _handleUnauthorized(response.body);
    }

    throw Exception('Failed to get category analytics: ${response.body}');
  }

  /// Get performance analytics including best times and patterns
  static Future<AnalyticsPerformance> getPerformanceAnalytics() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/analytics/performance');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AnalyticsPerformance.fromJson(data);
    } else if (response.statusCode == 401) {
      await _handleUnauthorized(response.body);
    }

    throw Exception('Failed to get performance analytics: ${response.body}');
  }

  /// Get personalized insights based on user behavior patterns
  static Future<List<PersonalizedInsight>> getPersonalizedInsights() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/analytics/insights');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => PersonalizedInsight.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await _handleUnauthorized(response.body);
    }

    throw Exception('Failed to get personalized insights: ${response.body}');
  }
} 