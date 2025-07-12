import 'package:flutter/material.dart';
import '../models/task_models.dart';
import '../theme/app_theme.dart';
import '../screens/focus_mode_screen.dart';
import 'package:provider/provider.dart';
import '../providers/breakdown_provider.dart'; // Added import for BreakdownProvider

class EnhancedTaskCard extends StatelessWidget {
  final Task task;
  final int taskNumber;

  const EnhancedTaskCard({
    Key? key,
    required this.task,
    required this.taskNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onLongPress: () {
          _showEditSheet(context);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18, color: AppTheme.primary),
                  label: Text('${task.estimatedDuration} min'),
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  labelStyle: textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
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
                  label: const Text('Start Focus'),
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