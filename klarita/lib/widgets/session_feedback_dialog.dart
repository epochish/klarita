import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionFeedbackDialog extends StatefulWidget {
  final String sessionGoal;
  final int completedTasks;
  final int totalTasks;
  final Function(int rating, String? comments) onSubmitFeedback;

  const SessionFeedbackDialog({
    Key? key,
    required this.sessionGoal,
    required this.completedTasks,
    required this.totalTasks,
    required this.onSubmitFeedback,
  }) : super(key: key);

  @override
  State<SessionFeedbackDialog> createState() => _SessionFeedbackDialogState();
}

class _SessionFeedbackDialogState extends State<SessionFeedbackDialog> {
  int _rating = 0;
  final _commentsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final completionPercentage = (widget.completedTasks / widget.totalTasks * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session Feedback', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text('Help your AI learn from this session', style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Session summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session Summary', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Goal: ${widget.sessionGoal}', style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text('${widget.completedTasks}/${widget.totalTasks} tasks completed ($completionPercentage%)', 
                           style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Rating section
            Text('How effective was this breakdown for you?', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Your feedback helps the AI learn your preferences and improve future task breakdowns.',
                 style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: AppSpacing.md),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _rating >= starValue ? Icons.star : Icons.star_border,
                      color: _rating >= starValue ? AppTheme.warning : AppTheme.textSecondary,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Rating labels
            if (_rating > 0) ...[
              Center(
                child: Text(
                  _getRatingLabel(_rating),
                  style: textTheme.titleSmall?.copyWith(
                    color: _getRatingColor(_rating),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Comments section
            const SizedBox(height: AppSpacing.md),
            Text('Additional Comments (Optional)', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _commentsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What worked well? What could be improved? Any specific feedback?',
                hintStyle: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_rating == 0 || _isSubmitting) ? null : _submitFeedback,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.psychology, size: 16),
                              const SizedBox(width: AppSpacing.xs),
                              const Text('Train AI'),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            // RL Learning info
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Your feedback trains your personal AI to provide better task breakdowns over time.',
                      style: textTheme.bodySmall?.copyWith(color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      final comments = _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim();
      await widget.onSubmitFeedback(_rating, comments);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.psychology, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                const Text('Thank you! Your AI is learning from this feedback.'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Not Helpful';
      case 2:
        return 'Somewhat Helpful';
      case 3:
        return 'Moderately Helpful';
      case 4:
        return 'Very Helpful';
      case 5:
        return 'Extremely Helpful';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return AppTheme.error;
    if (rating == 3) return AppTheme.warning;
    return AppTheme.success;
  }
}

/// Helper function to show the feedback dialog
Future<void> showSessionFeedbackDialog({
  required BuildContext context,
  required String sessionGoal,
  required int completedTasks,
  required int totalTasks,
  required Function(int rating, String? comments) onSubmitFeedback,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SessionFeedbackDialog(
      sessionGoal: sessionGoal,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      onSubmitFeedback: onSubmitFeedback,
    ),
  );
} 