import 'package:flutter/material.dart';
import '../models/task_models.dart';
import '../theme/app_theme.dart';
import '../screens/focus_mode_screen.dart';
import 'package:provider/provider.dart';
import '../providers/breakdown_provider.dart'; // Added import for BreakdownProvider
import '../providers/gamification_provider.dart'; // Added import for GamificationProvider
import 'confetti_overlay.dart';

class EnhancedTaskCard extends StatelessWidget {
  final Task task;
  final int taskNumber;
  final int listIndex; // needed for drag handle

  const EnhancedTaskCard({
    Key? key,
    required this.task,
    required this.taskNumber,
    required this.listIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP $taskNumber: ${task.title}',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: textTheme.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                // Drag handle on the left
                ReorderableDragStartListener(
                  index: listIndex,
                  child: const Icon(Icons.drag_handle),
                ),

                // Checkbox overlay when selecting
                if (context.watch<BreakdownProvider>().isSelecting)
                  Checkbox(
                    value: context.watch<BreakdownProvider>().selectedIds.contains(task.id),
                    onChanged: (_) => context.read<BreakdownProvider>().toggleSelect(task.id),
                  ),

                // Estimated duration chip (tap to cycle priority)
                GestureDetector(
                  onTap: () => context.read<BreakdownProvider>().togglePriority(task),
                  child: Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 18, color: AppTheme.primary),
                    label: Text('${task.estimatedDuration} min'),
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    labelStyle: textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  ),
                ),

                // Start Focus button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FocusModeScreen(task: task),
                      ),
                    );
                  },
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                  label: const Text('Focus'),
                ),

                // Done button (base XP only)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                  onPressed: () async {
                    final result = await context.read<GamificationProvider>().completeTask(
                      task.id,
                      // No actualMinutes => base XP only
                    );

                    // Show toast/snackbar with XP earned
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

                    // If user leveled up, show confetti overlay + dialog
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
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showEditSheet(BuildContext context) {
    final titleController = TextEditingController(text: task.title);
    final durationController = TextEditingController(text: task.estimatedDuration?.toString() ?? '');
    TaskPriority tempPriority = task.priority;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    // Call provider
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