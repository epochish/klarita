import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/breakdown_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/enhanced_task_card.dart';

class DayPlannerScreen extends StatelessWidget {
  const DayPlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final breakdownProvider = context.watch<BreakdownProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Day Plan'),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineLarge,
        actions: [
          if (breakdownProvider.currentSession != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: const Icon(Icons.save_alt_outlined),
                tooltip: 'Save as Memory',
                onPressed: () {
                  context.read<BreakdownProvider>().saveCurrentSessionAsMemory();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Plan saved as a memory for your AI to learn from!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                },
              ),
            ),
          if (breakdownProvider.currentSession != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: const Icon(Icons.star_rate_outlined),
                tooltip: 'Give Feedback',
                onPressed: () async {
                  final rating = await showDialog<int>(
                    context: context,
                    builder: (ctx) {
                      int tempRating = 3;
                      TextEditingController commentController = TextEditingController();
                      return AlertDialog(
                        title: const Text('Rate this Plan'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < tempRating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    tempRating = index + 1;
                                    (ctx as Element).markNeedsBuild();
                                  },
                                );
                              }),
                            ),
                            TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                labelText: 'Comments (optional)',
                              ),
                              maxLines: 2,
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
                              context.read<BreakdownProvider>().submitFeedback(
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
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  }
                },
              ),
            ),
          if (breakdownProvider.isSelecting)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Merge Selected',
              onPressed: breakdownProvider.selectedIds.length < 2
                  ? null
                  : () async {
                      await context.read<BreakdownProvider>().mergeSelected();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Tasks merged!')));
                    },
            ),
        ],
      ),
      body: Consumer<BreakdownProvider>(
        builder: (context, provider, child) {
          if (provider.currentSession == null || provider.currentSession!.tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Go to the AI Coach tab to create a new plan!',
                  style: textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final tasks = provider.currentSession!.tasks;
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) {
              context.read<BreakdownProvider>().reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              return EnhancedTaskCard(
                key: ValueKey(tasks[index].id),
                task: tasks[index],
                taskNumber: index + 1,
                listIndex: index,
              );
            },
          );
        },
      ),
      floatingActionButton: breakdownProvider.isSelecting
          ? FloatingActionButton.extended(
              onPressed: () => context.read<BreakdownProvider>().cancelSelecting(),
              label: const Text('Cancel'),
              icon: const Icon(Icons.close),
            )
          : null,
    );
  }
} 