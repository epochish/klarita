import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';
import '../models/task_models.dart';
import '../models/analytics_models.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/klarita_logo.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>()..initializeIfNeeded();
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final textTheme = Theme.of(context).textTheme;

    // Auto-load analytics data when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analyticsProvider.autoRefreshIfNeeded();
    });

    return Scaffold(
      appBar: AppBar(
        title: const KlaritaLogo(),
        centerTitle: false,
        titleTextStyle: textTheme.headlineLarge,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<GamificationProvider>().fetchGamificationStatus(),
            context.read<AnalyticsProvider>().refresh(),
          ]);
        },
        child: _buildBody(context, gamificationProvider, analyticsProvider, textTheme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GamificationProvider provider, AnalyticsProvider analyticsProvider, TextTheme textTheme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    if (provider.gamification == null) {
      return const Center(child: Text('No progress data available. Complete a task to get started!'));
    }

    final profile = provider.gamification!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildStatsCard(context, profile.level, profile.points).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.lg),
        _buildStreakCard(context, profile).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: AppSpacing.lg),
        _buildAnalyticsSection(context, analyticsProvider).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: AppSpacing.lg),
        Text('Your Badges', style: textTheme.headlineMedium).animate().slideX(),
        const SizedBox(height: AppSpacing.md),
        _buildBadgesGrid(profile.badges).animate().slideY(delay: 800.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, int level, int points) {
    final textTheme = Theme.of(context).textTheme;
    final progress = (points / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(textTheme, Icons.star_outline, AppTheme.accent, 'Level', level.toString())
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 1.seconds),
                _buildStatItem(textTheme, Icons.whatshot_outlined, AppTheme.primary, 'Points', points.toString()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Level Progress', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      backgroundColor: AppTheme.border,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('$points / 100', style: textTheme.bodyMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, UserGamification profile) {
    final textTheme = Theme.of(context).textTheme;
    final currentStreak = profile.currentStreak;
    final longestStreak = profile.longestStreak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: AppTheme.warning, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text('Streak Stats', style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStreakStat(
                    context,
                    'Current',
                    currentStreak.toString(),
                    currentStreak > 0 ? AppTheme.success : AppTheme.textDisabled,
                    Icons.whatshot,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _buildStreakStat(
                    context,
                    'Longest',
                    longestStreak.toString(),
                    AppTheme.primary,
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildStreakCalendar(context, profile),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(BuildContext context, String label, String value, Color color, IconData icon) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: textTheme.headlineMedium?.copyWith(color: color)),
          Text(label, style: textTheme.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(BuildContext context, UserGamification profile) {
    final textTheme = Theme.of(context).textTheme;
    
    // Generate last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.05),
            AppTheme.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_fire_department, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Last 7 Days',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: last7Days.map((date) {
              // Simple heuristic: assume completed if within current streak
              final daysAgo = now.difference(date).inDays;
              final isCompleted = daysAgo < profile.currentStreak;
              
              return _buildDayIndicator(context, date, isCompleted);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(BuildContext context, DateTime date, bool isCompleted) {
    final isToday = date.day == DateTime.now().day;
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: isCompleted 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.success,
                      AppTheme.success.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isCompleted 
                ? null
                : isToday 
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isToday 
                  ? AppTheme.primary 
                  : isCompleted 
                      ? AppTheme.success.withOpacity(0.3)
                      : AppTheme.border,
              width: isToday ? 2 : 1,
            ),
            boxShadow: isCompleted ? [
              BoxShadow(
                color: AppTheme.success.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _getDayLabel(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isToday 
                ? AppTheme.primary 
                : isCompleted 
                    ? AppTheme.success
                    : AppTheme.textSecondary,
            fontWeight: isToday || isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day) return 'Today';
    if (date.day == now.subtract(const Duration(days: 1)).day) return 'Yesterday';
    return _getShortDayName(date.weekday);
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  Widget _buildStatItem(TextTheme textTheme, IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value, 
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label, 
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(List<Badge> badges) {
    if (badges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text('No badges earned yet. Keep completing tasks to unlock them!'),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Tooltip(
          message: badge.description,
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.accent.withOpacity(0.1),
                child: _buildBadgeIcon(badge),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(badge.name, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgeIcon(Badge badge) {
    // Attempt to load icon asset; if not found, fallback to shield icon.
    final assetPath = 'assets/icons/${badge.icon}';
    return Image.asset(
      assetPath,
      width: 40,
      height: 40,
      errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 40, color: AppTheme.accent),
        );
  }

  Widget _buildAnalyticsSection(BuildContext context, AnalyticsProvider analyticsProvider) {
    final textTheme = Theme.of(context).textTheme;
    
    if (analyticsProvider.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights & Analytics', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (analyticsProvider.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights & Analytics', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Unable to load analytics', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(analyticsProvider.error!, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => analyticsProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final categoryStats = analyticsProvider.categoryStats;
    final stuckStats = analyticsProvider.stuckStats;
    final insights = analyticsProvider.insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights & Analytics', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        
        // Show personalized insights first
        if (insights.isNotEmpty) ...[
          _buildInsightsCard(context, insights),
          const SizedBox(height: AppSpacing.md),
        ],
        
        // Category completion chart
        if (categoryStats.isNotEmpty) ...[
          _buildCategoryChart(context, categoryStats),
          const SizedBox(height: AppSpacing.md),
        ],
        
        // Stuck analysis chart
        if (stuckStats.isNotEmpty) ...[
          _buildStuckChart(context, stuckStats),
          const SizedBox(height: AppSpacing.md),
        ],
        
        // Quick stats card
        if (analyticsProvider.quickStats != null) ...[
          _buildQuickStatsCard(context, analyticsProvider.quickStats!),
        ],
      ],
    );
  }

  Widget _buildInsightsCard(BuildContext context, List<PersonalizedInsight> insights) {
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: AppTheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('AI Insights', style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...insights.take(3).map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getInsightIcon(insight.type), size: 16, color: AppTheme.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(child: Text(insight.title, style: textTheme.titleSmall)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text('${insight.confidencePercentage.round()}%', 
                                     style: textTheme.labelSmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(insight.description, style: textTheme.bodySmall),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, List<CategoryStats> categoryStats) {
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Completion by Category', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: categoryStats.map((e) => e.totalTasks).reduce((a, b) => a > b ? a : b).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < categoryStats.length) {
                            return Text(categoryStats[index].category);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: categoryStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat.completedTasks.toDouble(),
                          color: _getCategoryColor(index),
                          width: 18,
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Real-time data from your task completion history', 
                 style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStuckChart(BuildContext context, List<StuckStats> stuckStats) {
    final textTheme = Theme.of(context).textTheme;
    
    if (stuckStats.where((s) => s.stuckCount > 0).isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: AppTheme.success),
              const SizedBox(height: AppSpacing.sm),
              Text('Great News!', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('You haven\'t gotten stuck recently. Keep up the great work!', 
                   style: textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where You Get Stuck', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sections: stuckStats.where((s) => s.stuckCount > 0).map((stat) {
                    final color = _getCategoryColor(stuckStats.indexOf(stat));
                    return PieChartSectionData(
                      value: stat.stuckCount.toDouble(),
                      color: color,
                      title: stat.category,
                      radius: 32,
                      titleStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Categories where you\'ve used the "Feeling Stuck" coach', 
                 style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(BuildContext context, QuickStats quickStats) {
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Stats', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    'Completion Rate',
                    '${quickStats.overallCompletionRate.round()}%',
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                ),
                Expanded(
                  child: _buildQuickStatItem(
                    'Total Tasks',
                    '${quickStats.totalTasksCompleted}',
                    Icons.task_alt,
                    AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    'Current Level',
                    '${quickStats.currentLevel}',
                    Icons.military_tech,
                    AppTheme.warning,
                  ),
                ),
                Expanded(
                  child: _buildQuickStatItem(
                    'Total XP',
                    '${quickStats.totalXp}',
                    Icons.emoji_events,
                    AppTheme.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
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

  Color _getCategoryColor(int index) {
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.warning, AppTheme.accent, AppTheme.success];
    return colors[index % colors.length];
  }
}

class AnalyticsInsightsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights & Analytics', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        _InsightCard(
          title: 'Task Completion by Category',
          child: SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Work');
                          case 1:
                            return const Text('Life');
                          case 2:
                            return const Text('Health');
                          case 3:
                            return const Text('Other');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: AppTheme.primary, width: 18)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: AppTheme.secondary, width: 18)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3, color: AppTheme.warning, width: 18)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6, color: AppTheme.textSecondary, width: 18)]),
                ],
              ),
            ),
          ),
          description: 'See which types of tasks you complete most often. (Mock data)',
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightCard(
          title: 'Where You Get Stuck',
          child: SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 6, color: AppTheme.error, title: 'Work', radius: 32, titleStyle: textTheme.bodySmall?.copyWith(color: Colors.white)),
                  PieChartSectionData(value: 2, color: AppTheme.warning, title: 'Life', radius: 28, titleStyle: textTheme.bodySmall?.copyWith(color: Colors.white)),
                  PieChartSectionData(value: 1, color: AppTheme.primary, title: 'Health', radius: 24, titleStyle: textTheme.bodySmall?.copyWith(color: Colors.white)),
                  PieChartSectionData(value: 1, color: AppTheme.textSecondary, title: 'Other', radius: 20, titleStyle: textTheme.bodySmall?.copyWith(color: Colors.white)),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 24,
              ),
            ),
          ),
          description: 'Most common categories where you get stuck. (Mock data)',
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightCard(
          title: 'Completion Trends',
          child: SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 2),
                      FlSpot(1, 4),
                      FlSpot(2, 3),
                      FlSpot(3, 7),
                      FlSpot(4, 6),
                      FlSpot(5, 8),
                      FlSpot(6, 5),
                    ],
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Mon');
                          case 1:
                            return const Text('Tue');
                          case 2:
                            return const Text('Wed');
                          case 3:
                            return const Text('Thu');
                          case 4:
                            return const Text('Fri');
                          case 5:
                            return const Text('Sat');
                          case 6:
                            return const Text('Sun');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
          description: 'Your completion trend over the past week. (Mock data)',
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightCard(
          title: 'Quick Stats',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(label: 'Avg. Completion', value: '72%'),
              _StatTile(label: 'Avg. Time/Task', value: '18 min'),
              _StatTile(label: 'Most Productive', value: 'Morning'),
            ],
          ),
          description: 'A snapshot of your productivity. (Mock data)',
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String description;
  const _InsightCard({required this.title, required this.child, required this.description});
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            child,
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.headlineMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
} 