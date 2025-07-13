import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../models/analytics_models.dart';
import '../theme/app_theme.dart';

class RealtimeInsightsWidget extends StatefulWidget {
  final bool autoRefresh;
  final Duration refreshInterval;

  const RealtimeInsightsWidget({
    Key? key,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(minutes: 2),
  }) : super(key: key);

  @override
  State<RealtimeInsightsWidget> createState() => _RealtimeInsightsWidgetState();
}

class _RealtimeInsightsWidgetState extends State<RealtimeInsightsWidget> 
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    if (widget.autoRefresh) {
      _startAutoRefresh();
    }
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      if (mounted) {
        context.read<AnalyticsProvider>().loadAnalytics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        if (analyticsProvider.insights.isEmpty && !analyticsProvider.isLoading) {
          return _buildEmptyState();
        }

        if (analyticsProvider.isLoading) {
          return _buildLoadingState();
        }

        return _buildInsightsList(analyticsProvider.insights);
      },
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, size: 48, color: AppTheme.accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AI is Learning',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete more tasks and provide feedback to get personalized insights!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Generating fresh insights...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(List<PersonalizedInsight> insights) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.md),
          ...insights.take(3).map((insight) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutCubic,
            )),
            child: _buildInsightCard(insight),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final provider = context.read<AnalyticsProvider>();
    final lastUpdated = provider.lastUpdated;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.psychology, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (lastUpdated != null)
                Text(
                  'Updated ${_getTimeAgo(lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.primary),
          onPressed: () {
            _slideController.reset();
            context.read<AnalyticsProvider>().refresh();
            _slideController.forward();
          },
          tooltip: 'Refresh insights',
        ),
      ],
    );
  }

  Widget _buildInsightCard(PersonalizedInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _getInsightTypeColor(insight.type).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _getInsightTypeColor(insight.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getInsightIcon(insight.type),
                  size: 16,
                  color: _getInsightTypeColor(insight.type),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildConfidenceBadge(insight.confidence),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getInsightTypeColor(insight.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _getInsightTypeLabel(insight.type),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getInsightTypeColor(insight.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                size: 16,
                color: AppTheme.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Learning',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percentage = (confidence * 100).round();
    final color = confidence >= 0.8 
        ? AppTheme.success 
        : confidence >= 0.6 
            ? AppTheme.warning 
            : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$percentage%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'productivity_tip':
        return Icons.lightbulb;
      case 'pattern_recognition':
        return Icons.analytics;
      case 'recommendation':
        return Icons.thumb_up;
      case 'ai_learning':
        return Icons.psychology;
      default:
        return Icons.info;
    }
  }

  Color _getInsightTypeColor(String type) {
    switch (type) {
      case 'productivity_tip':
        return AppTheme.warning;
      case 'pattern_recognition':
        return AppTheme.primary;
      case 'recommendation':
        return AppTheme.success;
      case 'ai_learning':
        return AppTheme.accent;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getInsightTypeLabel(String type) {
    switch (type) {
      case 'productivity_tip':
        return 'Productivity Tip';
      case 'pattern_recognition':
        return 'Pattern Analysis';
      case 'recommendation':
        return 'Recommendation';
      case 'ai_learning':
        return 'AI Learning';
      default:
        return 'Insight';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
} 