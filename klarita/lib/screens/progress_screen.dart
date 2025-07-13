import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import '../theme/app_theme.dart';
import '../models/task_models.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/klarita_logo.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>()..initializeIfNeeded();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const KlaritaLogo(),
        centerTitle: false,
        titleTextStyle: textTheme.headlineLarge,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<GamificationProvider>().fetchGamificationStatus(),
        child: _buildBody(context, gamificationProvider, textTheme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GamificationProvider provider, TextTheme textTheme) {
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
        AnalyticsInsightsSection().animate().fadeIn(delay: 600.ms),
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
    final completedDates = profile.completedDates;
    
    // Generate last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 7 Days', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: last7Days.map((date) {
            final isCompleted = completedDates.any((completedDate) {
              final completed = DateTime.parse(completedDate);
              return completed.year == date.year &&
                     completed.month == date.month &&
                     completed.day == date.day;
            });
            
            return _buildDayIndicator(context, date, isCompleted);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDayIndicator(BuildContext context, DateTime date, bool isCompleted) {
    final isToday = date.day == DateTime.now().day;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppTheme.success 
                : isToday 
                    ? AppTheme.primary.withOpacity(0.3)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday ? AppTheme.primary : AppTheme.border,
              width: isToday ? 2 : 1,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _getDayLabel(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isToday ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: textTheme.bodyMedium),
      ],
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