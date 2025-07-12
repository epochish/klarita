import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task_models.dart';

class GamificationProvider with ChangeNotifier {
  UserGamification? _gamification;
  bool _isLoading = false;
  String? _error;

  UserGamification? get gamification => _gamification;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GamificationProvider() {
    fetchGamificationStatus();
  }

  Future<void> fetchGamificationStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gamification = await ApiService.getGamificationStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeTask(int taskId) async {
    try {
      await ApiService.completeTask(taskId);
      // After completing a task, refresh the status to get updated points/level
      await fetchGamificationStatus();
    } catch (e) {
      // Handle or log error if needed
      print('Error completing task in provider: $e');
    }
  }
} 