import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/breakdown_provider.dart';
import '../theme/app_theme.dart';

class BreakdownScreen extends StatefulWidget {
  const BreakdownScreen({Key? key}) : super(key: key);

  @override
  State<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends State<BreakdownScreen> {
  final _goalController = TextEditingController();

  void _startBreakdown() {
    if (_goalController.text.isNotEmpty) {
      context.read<BreakdownProvider>().initiateBreakdown(_goalController.text);
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Task Coach'),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineLarge,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildGoalInput(),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildGoalInput() {
    return TextField(
      controller: _goalController,
      onSubmitted: (_) => _startBreakdown(),
      decoration: InputDecoration(
        hintText: 'What goal is on your mind?',
        suffixIcon: Consumer<BreakdownProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
                    )
                  : const Icon(Icons.auto_awesome, color: AppTheme.primary),
              onPressed: provider.isLoading ? null : _startBreakdown,
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Consumer<BreakdownProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.currentSession == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                provider.error!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (provider.currentSession == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Enter a goal above and I will break it down into small, manageable steps for you.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: provider.currentSession!.tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final task = provider.currentSession!.tasks[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                  ),
                ),
                title: Text(task.title),
                subtitle: task.description != null ? Text(task.description!, style: Theme.of(context).textTheme.bodyMedium) : null,
                trailing: Text(
                  '${task.estimatedDuration} min',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          },
        );
      },
    );
  }
} 