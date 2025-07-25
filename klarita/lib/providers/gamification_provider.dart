import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task_models.dart';

// Holds the outcome of a task completion for easy UI access
class TaskCompletionResult {
  final int xpEarned;
  final bool levelUp;

  TaskCompletionResult({required this.xpEarned, required this.levelUp});
}

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

  /// Completes a task and returns information about XP earned & whether the user leveled up.
  /// [actualMinutes] can be provided to allow backend bonus-XP logic.
  Future<TaskCompletionResult> completeTask(
    int taskId, {
    int? actualMinutes,
  }) async {
    try {
      // Capture old values before the API call so we can compute deltas afterwards.
      final oldPoints = _gamification?.points ?? 0;
      final oldLevel = _gamification?.level ?? 0;

      // Backend may optionally return XP in its response, but we still rely on
      // the refreshed status for single source of truth.
      await ApiService.completeTask(taskId, actualMinutes: actualMinutes);

      // Refresh gamification status to reflect new points/level.
      await fetchGamificationStatus();

      final newPoints = _gamification?.points ?? oldPoints;
      final newLevel = _gamification?.level ?? oldLevel;

      final xpEarned = newPoints - oldPoints;
      final levelUp = newLevel > oldLevel;

      return TaskCompletionResult(xpEarned: xpEarned, levelUp: levelUp);
    } catch (e) {
      print('Error completing task in provider: $e');
      // On error, return 0/false so UI can choose how to respond.
      return TaskCompletionResult(xpEarned: 0, levelUp: false);
    }
  }
} 