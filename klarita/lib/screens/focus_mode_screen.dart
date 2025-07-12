import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../models/task_models.dart';
import '../providers/gamification_provider.dart';
import '../theme/app_theme.dart';

class FocusModeScreen extends StatefulWidget {
  final Task task;
  const FocusModeScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with TickerProviderStateMixin {
  Timer? _timer;
  late int _remainingSeconds;
  bool _isTimerRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.task.estimatedDuration ?? 25) * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          _onTimerFinish();
        }
      });
    }
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = (widget.task.estimatedDuration ?? 25) * 60;
    });
  }

  void _onTimerFinish() async {
    await _audioPlayer.play(AssetSource('sounds/pomodoro_complete.mp3'));
    context.read<GamificationProvider>().completeTask(widget.task.id);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Text('Focus Session Complete! 🎉'),
          content: Text('Great job focusing on "${widget.task.title}". You\'ve earned points!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back from focus screen
              },
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.task.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_remainingSeconds),
              style: textTheme.displayLarge?.copyWith(fontSize: 80, color: AppTheme.textPrimary),
            ).animate(target: _isTimerRunning ? 1 : 0).scale(duration: 300.ms, curve: Curves.easeInOut),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetTimer,
                  iconSize: 32,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppSpacing.lg),
                FloatingActionButton.large(
                  onPressed: _toggleTimer,
                  child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 60),
                ).animate().scale(delay: 200.ms),
                const SizedBox(width: AppSpacing.lg),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: _onTimerFinish,
                  iconSize: 32,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 