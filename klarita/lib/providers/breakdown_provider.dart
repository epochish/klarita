import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/task_models.dart';
import '../services/api_service.dart';

// This provider manages the state for the interactive task breakdown process.
class BreakdownProvider with ChangeNotifier {
  TaskSession? _currentSession;
  bool _isLoading = false;
  String? _error;
  bool _isSelecting = false;
  final Set<int> _selected = {};

  BreakdownProvider() {
    _loadCachedSession();
  }

  Future<void> _loadCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_session');
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr);
        _currentSession = TaskSession.fromJson(map);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _persistSession() async {
    if (_currentSession == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_session', json.encode(_currentSession!.toJson()));
  }

  // Getters
  TaskSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSelecting => _isSelecting;
  Set<int> get selectedIds => _selected;

  // Initiates a new task breakdown session.
  Future<void> initiateBreakdown(String goal) async {
    if (goal.trim().isEmpty) {
      _error = "Goal cannot be empty.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Call the API to get the initial breakdown
      _currentSession = await ApiService.initiateBreakdown(goal: goal);
      _persistSession();
    } catch (e) {
      _error = "Failed to get task breakdown. Please try again. \nError: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clears the current session and resets the state.
  void clearSession() {
    _currentSession = null;
    _error = null;
    _isLoading = false;
    _isSelecting = false;
    _selected.clear();
    notifyListeners();
    _persistSession();
  }

  // Selection helpers
  void startSelecting(int taskId) {
    _isSelecting = true;
    _selected.add(taskId);
    notifyListeners();
  }

  void toggleSelect(int taskId) {
    if (!_isSelecting) return;
    if (_selected.contains(taskId)) {
      _selected.remove(taskId);
      if (_selected.isEmpty) _isSelecting = false;
    } else {
      _selected.add(taskId);
    }
    notifyListeners();
  }

  void cancelSelecting() {
    _isSelecting = false;
    _selected.clear();
    notifyListeners();
  }

  Future<void> mergeSelected() async {
    if (_currentSession == null || _selected.length < 2) return;
    final ids = _selected.toList();
    try {
      final merged = await ApiService.mergeTasks(ids);
      // Remove old tasks and insert new
      _currentSession!.tasks.removeWhere((t) => _selected.contains(t.id));
      _currentSession!.tasks.insert(0, merged); // simplistic prepend
      _isSelecting = false;
      _selected.clear();
      notifyListeners();
      _persistSession();
    } catch (e) {
      print('Error merging tasks: $e');
    }
  }

  // Save the current session as a memory for the RAG system
  Future<void> saveCurrentSessionAsMemory() async {
    if (_currentSession == null) {
      throw Exception("No session available to save");
    }

    try {
      await ApiService.saveSessionAsMemory(_currentSession!.id);
      print("Session saved as memory!");
    } catch (e) {
      print("Error saving session as memory: ${e.toString()}");
      rethrow; // Re-throw the error so UI can handle it
    }
  }

  // Submit feedback at the end of a session (rating 1-5, optional comment)
  Future<void> submitFeedback({required int rating, String? comments}) async {
    if (_currentSession == null) return;
    try {
      await ApiService.submitSessionFeedback(
        sessionId: _currentSession!.id,
        rating: rating,
        comments: comments,
      );
      print('Enhanced RL feedback submitted!');
    } catch (e) {
      print('Error submitting feedback: ${e.toString()}');
      rethrow; // Re-throw for UI error handling
    }
  }

  // Check if session is completed and ready for feedback
  bool get isSessionReadyForFeedback {
    if (_currentSession == null) return false;
    final completedTasks = _currentSession!.tasks.where((task) => task.completed).length;
    final totalTasks = _currentSession!.tasks.length;
    // Consider session ready for feedback if 50% or more tasks are completed
    return totalTasks > 0 && (completedTasks / totalTasks) >= 0.5;
  }

  // Get session completion stats
  SessionCompletionStats get sessionStats {
    if (_currentSession == null) {
      return SessionCompletionStats(completedTasks: 0, totalTasks: 0, completionRate: 0.0);
    }
    final completedTasks = _currentSession!.tasks.where((task) => task.completed).length;
    final totalTasks = _currentSession!.tasks.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    
    return SessionCompletionStats(
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      completionRate: completionRate,
    );
  }

  // Mark a task as completed and check for session completion
  void markTaskCompleted(int taskId) {
    if (_currentSession == null) return;
    
    final taskIndex = _currentSession!.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _currentSession!.tasks[taskIndex] = Task(
        id: _currentSession!.tasks[taskIndex].id,
        title: _currentSession!.tasks[taskIndex].title,
        description: _currentSession!.tasks[taskIndex].description,
        estimatedDuration: _currentSession!.tasks[taskIndex].estimatedDuration,
        position: _currentSession!.tasks[taskIndex].position,
        priority: _currentSession!.tasks[taskIndex].priority,
        status: "completed",
      );
      notifyListeners();
      _persistSession();
    }
  }

  // Update a single task and refresh local state
  Future<void> updateTask(int taskId, Map<String, dynamic> updates) async {
    if (_currentSession == null) return;
    try {
      final updated = await ApiService.updateTask(taskId: taskId, updates: updates);
      final idx = _currentSession!.tasks.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        _currentSession!.tasks[idx] = updated;
        notifyListeners();
        _persistSession();
      }
    } catch (e) {
      print('Error updating task: ${e.toString()}');
    }
  }

  // Reorder tasks locally and sync to backend
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (_currentSession == null) return;
    final tasks = _currentSession!.tasks;
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, moved);
    notifyListeners();
    _persistSession();

    // Send order to backend
    try {
      await ApiService.reorderTasks(
        sessionId: _currentSession!.id,
        orderedIds: tasks.map((t) => t.id).toList(),
      );
    } catch (e) {
      print('Error reordering tasks: $e');
    }
  }

  // Cycle priority locally then patch
  void togglePriority(Task task) {
    final next = TaskPriority.values[(task.priority.index + 1) % TaskPriority.values.length];
    updateTask(task.id, {'priority': next.toString().split('.').last});
  }
} 