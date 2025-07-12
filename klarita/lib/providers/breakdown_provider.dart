import 'package:flutter/foundation.dart';
import '../models/task_models.dart';
import '../services/api_service.dart';

// This provider manages the state for the interactive task breakdown process.
class BreakdownProvider with ChangeNotifier {
  TaskSession? _currentSession;
  bool _isLoading = false;
  String? _error;

  // Getters
  TaskSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    notifyListeners();
  }

  // Save the current session as a memory for the RAG system
  Future<void> saveCurrentSessionAsMemory() async {
    if (_currentSession == null) return;

    try {
      await ApiService.saveSessionAsMemory(_currentSession!.id);
      // Optionally, provide feedback to the user
      print("Session saved as memory!");
    } catch (e) {
      // Handle or log the error as needed
      print("Error saving session as memory: ${e.toString()}");
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
      print('Feedback submitted!');
    } catch (e) {
      print('Error submitting feedback: ${e.toString()}');
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
      }
    } catch (e) {
      print('Error updating task: ${e.toString()}');
    }
  }
} 