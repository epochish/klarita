import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import '../theme/app_theme.dart';
import '../models/task_models.dart';
import '../widgets/confetti_overlay.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>()..initializeIfNeeded();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
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
        Text('Your Badges', style: textTheme.headlineMedium).animate().slideX(),
        const SizedBox(height: AppSpacing.md),
        _buildBadgesGrid(profile.badges).animate().slideY(delay: 400.ms, duration: 500.ms),
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