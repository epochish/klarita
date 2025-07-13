import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/analytics_models.dart';

class AnalyticsProvider with ChangeNotifier {
  // State variables
  AnalyticsSummary? _analyticsSummary;
  List<PersonalizedInsight> _insights = [];
  List<CategoryStats> _categoryStats = [];
  AnalyticsPerformance? _performance;
  AnalyticsTrends? _trends;
  
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  AnalyticsSummary? get analyticsSummary => _analyticsSummary;
  List<PersonalizedInsight> get insights => _insights;
  List<CategoryStats> get categoryStats => _categoryStats;
  AnalyticsPerformance? get performance => _performance;
  AnalyticsTrends? get trends => _trends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  // Computed getters for UI convenience
  QuickStats? get quickStats => _analyticsSummary?.quickStats;
  List<TimeOfDayStats> get timeOfDayStats => _analyticsSummary?.timeOfDayStats ?? [];
  List<StuckStats> get stuckStats => _analyticsSummary?.stuckStats ?? [];
  List<CompletionTrend> get completionTrends => _analyticsSummary?.completionTrends ?? [];

  /// Load all analytics data
  Future<void> loadAnalytics() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _setLoading(true);
    _clearError();

    try {
      // Load analytics summary (contains most data)
      _analyticsSummary = await ApiService.getAnalyticsSummary();
      
      // Load additional data
      await Future.wait([
        _loadInsights(),
        _loadCategoryStats(),
        _loadPerformance(),
        _loadTrends(),
      ]);

      _lastUpdated = DateTime.now();
      _setLoading(false);
      
    } catch (e) {
      _setError('Failed to load analytics: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load personalized insights
  Future<void> _loadInsights() async {
    try {
      _insights = await ApiService.getPersonalizedInsights();
    } catch (e) {
      debugPrint('Failed to load insights: $e');
      _insights = [];
    }
  }

  /// Load category statistics
  Future<void> _loadCategoryStats() async {
    try {
      _categoryStats = await ApiService.getCategoryAnalytics();
    } catch (e) {
      debugPrint('Failed to load category stats: $e');
      _categoryStats = [];
    }
  }

  /// Load performance analytics
  Future<void> _loadPerformance() async {
    try {
      _performance = await ApiService.getPerformanceAnalytics();
    } catch (e) {
      debugPrint('Failed to load performance analytics: $e');
      _performance = null;
    }
  }

  /// Load trends data
  Future<void> _loadTrends({String period = 'week'}) async {
    try {
      _trends = await ApiService.getAnalyticsTrends(period: period);
    } catch (e) {
      debugPrint('Failed to load trends: $e');
      _trends = null;
    }
  }

  /// Refresh all analytics data
  Future<void> refresh() async {
    await loadAnalytics();
  }

  /// Load analytics for a specific period
  Future<void> loadTrendsForPeriod(String period) async {
    _setLoading(true);
    try {
      await _loadTrends(period: period);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load trends: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Check if data needs refresh (older than 5 minutes)
  bool get needsRefresh {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!).inMinutes > 5;
  }

  /// Automatically refresh if needed
  Future<void> autoRefreshIfNeeded() async {
    if (needsRefresh) {
      await loadAnalytics();
    }
  }

  // Helper methods for chart data
  
  /// Get category completion data for charts
  List<ChartData> getCategoryChartData() {
    return _categoryStats.map((stat) => ChartData(
      label: stat.category,
      value: stat.completedTasks.toDouble(),
      total: stat.totalTasks.toDouble(),
      percentage: stat.completionRate,
    )).toList();
  }

  /// Get stuck data for pie chart
  List<ChartData> getStuckChartData() {
    return stuckStats.map((stat) => ChartData(
      label: stat.category,
      value: stat.stuckCount.toDouble(),
      total: stat.totalSessions.toDouble(),
      percentage: stat.stuckPercentage,
    )).toList();
  }

  /// Get completion trend data for line chart
  List<ChartData> getCompletionTrendData() {
    return completionTrends.map((trend) => ChartData(
      label: trend.date,
      value: trend.completedTasks.toDouble(),
      total: trend.totalTasks.toDouble(),
      percentage: trend.completionRate,
    )).toList();
  }

  /// Get time of day performance data
  List<ChartData> getTimeOfDayChartData() {
    return timeOfDayStats.map((stat) => ChartData(
      label: '${stat.hour.toString().padLeft(2, '0')}:00',
      value: stat.completedTasks.toDouble(),
      total: stat.totalTasks.toDouble(),
      percentage: stat.completionRate,
    )).toList();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data (useful for logout)
  void clear() {
    _analyticsSummary = null;
    _insights = [];
    _categoryStats = [];
    _performance = null;
    _trends = null;
    _isLoading = false;
    _error = null;
    _lastUpdated = null;
    notifyListeners();
  }
}

/// Helper class for chart data
class ChartData {
  final String label;
  final double value;
  final double total;
  final double percentage;

  ChartData({
    required this.label,
    required this.value,
    required this.total,
    required this.percentage,
  });
} 