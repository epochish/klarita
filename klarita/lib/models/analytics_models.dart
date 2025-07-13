/// Analytics data models for the Klarita application
/// These models correspond to the backend analytics schemas

class CategoryStats {
  final String category;
  final int completedTasks;
  final int totalTasks;
  final double completionRate;
  final double? averageDuration;

  CategoryStats({
    required this.category,
    required this.completedTasks,
    required this.totalTasks,
    required this.completionRate,
    this.averageDuration,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'] ?? '',
      completedTasks: json['completed_tasks'] ?? 0,
      totalTasks: json['total_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
      averageDuration: json['average_duration']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'completed_tasks': completedTasks,
        'total_tasks': totalTasks,
        'completion_rate': completionRate,
        'average_duration': averageDuration,
      };
}

class TimeOfDayStats {
  final int hour;
  final int completedTasks;
  final int totalTasks;
  final double completionRate;
  final double? averageDuration;

  TimeOfDayStats({
    required this.hour,
    required this.completedTasks,
    required this.totalTasks,
    required this.completionRate,
    this.averageDuration,
  });

  factory TimeOfDayStats.fromJson(Map<String, dynamic> json) {
    return TimeOfDayStats(
      hour: json['hour'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      totalTasks: json['total_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
      averageDuration: json['average_duration']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'completed_tasks': completedTasks,
        'total_tasks': totalTasks,
        'completion_rate': completionRate,
        'average_duration': averageDuration,
      };
}

class CompletionTrend {
  final String date;
  final int completedTasks;
  final int totalTasks;
  final double completionRate;

  CompletionTrend({
    required this.date,
    required this.completedTasks,
    required this.totalTasks,
    required this.completionRate,
  });

  factory CompletionTrend.fromJson(Map<String, dynamic> json) {
    return CompletionTrend(
      date: json['date'] ?? '',
      completedTasks: json['completed_tasks'] ?? 0,
      totalTasks: json['total_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'completed_tasks': completedTasks,
        'total_tasks': totalTasks,
        'completion_rate': completionRate,
      };
}

class StuckStats {
  final String category;
  final int stuckCount;
  final int totalSessions;
  final double stuckPercentage;

  StuckStats({
    required this.category,
    required this.stuckCount,
    required this.totalSessions,
    required this.stuckPercentage,
  });

  factory StuckStats.fromJson(Map<String, dynamic> json) {
    return StuckStats(
      category: json['category'] ?? '',
      stuckCount: json['stuck_count'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      stuckPercentage: (json['stuck_percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'stuck_count': stuckCount,
        'total_sessions': totalSessions,
        'stuck_percentage': stuckPercentage,
      };
}

class QuickStats {
  final int totalTasksCompleted;
  final int totalTasksCreated;
  final double overallCompletionRate;
  final double? averageTaskDuration;
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final int currentLevel;

  QuickStats({
    required this.totalTasksCompleted,
    required this.totalTasksCreated,
    required this.overallCompletionRate,
    this.averageTaskDuration,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.currentLevel,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      totalTasksCompleted: json['total_tasks_completed'] ?? 0,
      totalTasksCreated: json['total_tasks_created'] ?? 0,
      overallCompletionRate: (json['overall_completion_rate'] ?? 0.0).toDouble(),
      averageTaskDuration: json['average_task_duration']?.toDouble(),
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalXp: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_tasks_completed': totalTasksCompleted,
        'total_tasks_created': totalTasksCreated,
        'overall_completion_rate': overallCompletionRate,
        'average_task_duration': averageTaskDuration,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'total_xp': totalXp,
        'current_level': currentLevel,
      };
}

class PersonalizedInsight {
  final String type; // "productivity_tip", "pattern_recognition", "recommendation"
  final String title;
  final String description;
  final double confidence; // 0.0 to 1.0
  final String? category;

  PersonalizedInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    this.category,
  });

  factory PersonalizedInsight.fromJson(Map<String, dynamic> json) {
    return PersonalizedInsight(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'description': description,
        'confidence': confidence,
        'category': category,
      };

  // Helper method to get icon based on type
  String get iconName {
    switch (type) {
      case 'productivity_tip':
        return 'lightbulb';
      case 'pattern_recognition':
        return 'analytics';
      case 'recommendation':
        return 'thumb_up';
      case 'ai_learning':
        return 'psychology';
      default:
        return 'info';
    }
  }

  // Helper method to get color based on confidence
  double get confidencePercentage => confidence * 100;
}

class AnalyticsSummary {
  final QuickStats quickStats;
  final List<CategoryStats> categoryStats;
  final List<TimeOfDayStats> timeOfDayStats;
  final List<StuckStats> stuckStats;
  final List<CompletionTrend> completionTrends;
  final List<PersonalizedInsight> personalizedInsights;

  AnalyticsSummary({
    required this.quickStats,
    required this.categoryStats,
    required this.timeOfDayStats,
    required this.stuckStats,
    required this.completionTrends,
    required this.personalizedInsights,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      quickStats: QuickStats.fromJson(json['quick_stats'] ?? {}),
      categoryStats: (json['category_stats'] as List?)
          ?.map((item) => CategoryStats.fromJson(item))
          .toList() ?? [],
      timeOfDayStats: (json['time_of_day_stats'] as List?)
          ?.map((item) => TimeOfDayStats.fromJson(item))
          .toList() ?? [],
      stuckStats: (json['stuck_stats'] as List?)
          ?.map((item) => StuckStats.fromJson(item))
          .toList() ?? [],
      completionTrends: (json['completion_trends'] as List?)
          ?.map((item) => CompletionTrend.fromJson(item))
          .toList() ?? [],
      personalizedInsights: (json['personalized_insights'] as List?)
          ?.map((item) => PersonalizedInsight.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'quick_stats': quickStats.toJson(),
        'category_stats': categoryStats.map((item) => item.toJson()).toList(),
        'time_of_day_stats': timeOfDayStats.map((item) => item.toJson()).toList(),
        'stuck_stats': stuckStats.map((item) => item.toJson()).toList(),
        'completion_trends': completionTrends.map((item) => item.toJson()).toList(),
        'personalized_insights': personalizedInsights.map((item) => item.toJson()).toList(),
      };
}

class AnalyticsTrends {
  final String period; // "week", "month", "quarter"
  final List<CompletionTrend> trends;
  final List<Map<String, dynamic>> streakHistory;

  AnalyticsTrends({
    required this.period,
    required this.trends,
    required this.streakHistory,
  });

  factory AnalyticsTrends.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrends(
      period: json['period'] ?? 'week',
      trends: (json['trends'] as List?)
          ?.map((item) => CompletionTrend.fromJson(item))
          .toList() ?? [],
      streakHistory: (json['streak_history'] as List?)
          ?.map((item) => Map<String, dynamic>.from(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'trends': trends.map((item) => item.toJson()).toList(),
        'streak_history': streakHistory,
      };
}

class AnalyticsPerformance {
  final String bestDayOfWeek;
  final int bestTimeOfDay;
  final int mostProductiveDuration;
  final String preferredTaskSize; // "small", "medium", "large"
  final Map<String, dynamic> focusPatterns;

  AnalyticsPerformance({
    required this.bestDayOfWeek,
    required this.bestTimeOfDay,
    required this.mostProductiveDuration,
    required this.preferredTaskSize,
    required this.focusPatterns,
  });

  factory AnalyticsPerformance.fromJson(Map<String, dynamic> json) {
    return AnalyticsPerformance(
      bestDayOfWeek: json['best_day_of_week'] ?? 'Monday',
      bestTimeOfDay: json['best_time_of_day'] ?? 9,
      mostProductiveDuration: json['most_productive_duration'] ?? 25,
      preferredTaskSize: json['preferred_task_size'] ?? 'medium',
      focusPatterns: Map<String, dynamic>.from(json['focus_patterns'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'best_day_of_week': bestDayOfWeek,
        'best_time_of_day': bestTimeOfDay,
        'most_productive_duration': mostProductiveDuration,
        'preferred_task_size': preferredTaskSize,
        'focus_patterns': focusPatterns,
      };

  // Helper methods for UI display
  String get bestTimeOfDayFormatted => '${bestTimeOfDay.toString().padLeft(2, '0')}:00';
  
  String get preferredTaskSizeDescription {
    switch (preferredTaskSize) {
      case 'small':
        return 'Short tasks (< 20 min)';
      case 'medium':
        return 'Medium tasks (20-45 min)';
      case 'large':
        return 'Long tasks (> 45 min)';
      default:
        return 'Mixed task sizes';
    }
  }
} 