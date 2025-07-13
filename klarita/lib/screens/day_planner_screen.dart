import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/breakdown_provider.dart';
import '../providers/gamification_provider.dart';
import '../theme/app_theme.dart';
import '../services/toast_service.dart';
import '../models/task_models.dart';
import '../widgets/enhanced_task_card.dart';
import '../widgets/klarita_logo.dart';
import '../widgets/session_feedback_dialog.dart';

class DayPlannerScreen extends StatelessWidget {
  const DayPlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for session completion and show feedback dialog if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionCompletionAndShowFeedback(context);
    });
    final breakdownProvider = context.watch<BreakdownProvider>();
    final gamificationProvider = context.watch<GamificationProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const KlaritaLogo(),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineLarge,
        actions: [
          if (breakdownProvider.currentSession != null) ...[
            IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              tooltip: 'Save as Memory',
              onPressed: () async {
                try {
                  await breakdownProvider.saveCurrentSessionAsMemory();
                  ToastService.showSuccess(context, 'Plan saved as memory for AI learning!');
                } catch (e) {
                  ToastService.showError(context, 'Failed to save plan: ${e.toString()}');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.star_rate_outlined),
              tooltip: 'Give Feedback',
              onPressed: () => _showFeedbackDialog(context, breakdownProvider),
            ),
          ],
          if (breakdownProvider.isSelecting)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Merge Selected',
              onPressed: breakdownProvider.selectedIds.length < 2
                  ? null
                  : () async {
                      await breakdownProvider.mergeSelected();
                      ToastService.showSuccess(context, 'Tasks merged successfully!');
                    },
            ),
        ],
      ),
      body: Consumer<BreakdownProvider>(
        builder: (context, provider, child) {
          if (provider.currentSession == null || provider.currentSession!.tasks.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildTaskList(context, provider, gamificationProvider);
        },
      ),
      floatingActionButton: breakdownProvider.isSelecting
          ? FloatingActionButton.extended(
              onPressed: () => breakdownProvider.cancelSelecting(),
              label: const Text('Cancel'),
              icon: const Icon(Icons.close),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No tasks planned yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Go to the Breakdown tab to create a new plan and start your productive day!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.tips_and_updates, color: AppTheme.secondary, size: 32),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Getting Started',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '1. Go to Breakdown tab\n2. Enter your goal\n3. Review and customize tasks\n4. Come back here to execute!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildTaskList(BuildContext context, BreakdownProvider breakdownProvider, GamificationProvider gamificationProvider) {
    final session = breakdownProvider.currentSession!;
    final tasks = session.tasks;
    final completedTasks = tasks.where((task) => task.completed).length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Column(
      children: [
        // Progress header
        Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.success.withOpacity(0.1),
                AppTheme.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppTheme.success, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Today\'s Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completedTasks/$totalTasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Task list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) {
              breakdownProvider.reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              return KeyedSubtree(
                key: ValueKey(tasks[index].id),
                child: EnhancedTaskCard(
                  task: tasks[index],
                  taskNumber: index + 1,
                  listIndex: index,
                  onTaskCompleted: (task) async {
                    final result = await gamificationProvider.completeTask(task.id);
                    
                    if (result.xpEarned > 0) {
                      ToastService.showSuccess(
                        context, 
                        'Task completed! + ${result.xpEarned} XP${result.levelUp ? ' �� Level Up!' : ''}'
                      );
                    }

                    if (result.levelUp) {
                      _showLevelUpDialog(context);
                    }
                  },
                ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3, duration: 300.ms),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context, BreakdownProvider provider) async {
    final rating = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int tempRating = 3;
        TextEditingController commentController = TextEditingController();
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star_rate, color: AppTheme.warning, size: 24),
              const SizedBox(width: AppSpacing.sm),
              const Text('Rate this Plan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How helpful was this breakdown?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < tempRating ? Icons.star : Icons.star_border,
                      color: AppTheme.warning,
                      size: 32,
                    ),
                    onPressed: () {
                      tempRating = index + 1;
                      (ctx as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comments (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(tempRating);
                provider.submitFeedback(
                  rating: tempRating,
                  comments: commentController.text,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    
    if (rating != null) {
      ToastService.showSuccess(context, 'Thank you for your feedback!');
    }
  }

  void _showLevelUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.accent, size: 24),
            const SizedBox(width: AppSpacing.sm),
            const Text('Level Up!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: AppTheme.accent,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Congratulations on reaching a new level!'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Keep up the great work!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _checkSessionCompletionAndShowFeedback(BuildContext context) {
    final breakdownProvider = context.read<BreakdownProvider>();
    
    // Only check if we haven't already shown feedback for this session
    if (breakdownProvider.currentSession != null && breakdownProvider.isSessionReadyForFeedback) {
      final session = breakdownProvider.currentSession!;
      final stats = breakdownProvider.sessionStats;
      
      // Show feedback dialog if session is sufficiently complete and we haven't shown it yet
      if (stats.completionRate >= 0.8) { // 80% completion threshold
        showSessionFeedbackDialog(
          context: context,
          sessionGoal: session.originalGoal,
          completedTasks: stats.completedTasks,
          totalTasks: stats.totalTasks,
          onSubmitFeedback: (rating, comments) async {
            await breakdownProvider.submitFeedback(
              rating: rating,
              comments: comments,
            );
          },
        );
      }
    }
  }
} 