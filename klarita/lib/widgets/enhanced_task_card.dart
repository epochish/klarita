import 'package:flutter/material.dart';
import '../models/task_models.dart';
import '../theme/app_theme.dart';
import '../screens/focus_mode_screen.dart';
import 'package:provider/provider.dart';
import '../providers/breakdown_provider.dart';
import '../providers/gamification_provider.dart';
import 'confetti_overlay.dart';

class EnhancedTaskCard extends StatelessWidget {
  final Task task;
  final int taskNumber;
  final int listIndex;
  final Function(Task)? onTaskCompleted;

  const EnhancedTaskCard({
    Key? key,
    required this.task,
    required this.taskNumber,
    required this.listIndex,
    this.onTaskCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSelecting = context.watch<BreakdownProvider>().isSelecting;
    final isSelected = context.watch<BreakdownProvider>().selectedIds.contains(task.id);
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isSelected ? AppTheme.primary : AppTheme.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          final bp = context.read<BreakdownProvider>();
          if (bp.isSelecting) {
            bp.toggleSelect(task.id);
          } else {
            _showEditSheet(context);
          }
        },
        onLongPress: () {
          final bp = context.read<BreakdownProvider>();
          if (!bp.isSelecting) {
            bp.startSelecting(task.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$taskNumber',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      task.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: listIndex,
                    child: Icon(
                      Icons.drag_handle,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    task.description!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildInfoChip(
                          icon: Icons.timer_outlined,
                          label: '${task.estimatedDuration} min',
                          color: AppTheme.primary,
                        ),
                        _buildInfoChip(
                          icon: Icons.flag,
                          label: task.priority.toString().split('.').last.toUpperCase(),
                          color: _getPriorityColor(task.priority),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.center_focus_strong,
                          label: 'Focus',
                          color: AppTheme.primary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FocusModeScreen(task: task),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildActionButton(
                          context,
                          icon: Icons.check,
                          label: 'Done',
                          color: Colors.green.shade600,
                          onPressed: () async {
                            if (onTaskCompleted != null) {
                              onTaskCompleted!(task);
                            } else {
                              final result = await context.read<GamificationProvider>().completeTask(task.id);
                              if (result.xpEarned > 0) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.xpEarned > 0
                                            ? 'Task done! +${result.xpEarned} XP${result.levelUp ? '  🎉 Level Up!' : ''}'
                                            : 'Task completed!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              }
                              if (result.levelUp) {
                                showConfetti(context);
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                                    title: const Text('Level Up!'),
                                    content: const Text('Congratulations on reaching a new level!'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Awesome!'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppTheme.success;
      case TaskPriority.medium:
        return AppTheme.warning;
      case TaskPriority.high:
        return AppTheme.error;
    }
  }

  void _showEditSheet(BuildContext context) {
    final titleController = TextEditingController(text: task.title);
    final durationController = TextEditingController(text: task.estimatedDuration?.toString() ?? '');
    TaskPriority tempPriority = task.priority;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets.add(const EdgeInsets.all(AppSpacing.md)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estimated Duration (min)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButton<TaskPriority>(
                value: tempPriority,
                onChanged: (val) {
                  if (val != null) {
                    tempPriority = val;
                    (ctx as Element).markNeedsBuild();
                  }
                },
                items: TaskPriority.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString().split('.').last.toUpperCase()),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    final updates = {
                      'title': titleController.text,
                      'estimated_duration': int.tryParse(durationController.text),
                      'priority': tempPriority.toString().split('.').last,
                    }..removeWhere((key, value) => value == null);

                    Navigator.of(ctx).pop();
                    final provider = ctx.read<BreakdownProvider>();
                    provider.updateTask(task.id, updates);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 