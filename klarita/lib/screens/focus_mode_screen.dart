import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../models/task_models.dart';
import '../providers/gamification_provider.dart';
import '../widgets/confetti_overlay.dart';
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
  int _elapsedSeconds = 0; // Tracks the actual seconds spent so far
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
            _elapsedSeconds++; // Increment elapsed time each tick
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
      _elapsedSeconds = 0;
    });
  }

  void _addMoreTime({int minutes = 5}) {
    setState(() {
      _remainingSeconds += minutes * 60;
    });
  }

  void _takeBreak() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Break time! Resume whenever you are ready.'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _onTimerFinish() async {
    await _audioPlayer.play(AssetSource('sounds/pomodoro_complete.mp3'));

    // Calculate actual minutes spent based on the tracked elapsed seconds
    final elapsedMinutes = (_elapsedSeconds / 60).ceil();

    final result = await context.read<GamificationProvider>().completeTask(
      widget.task.id,
      actualMinutes: elapsedMinutes,
    );

    if (!mounted) return;

    if (result.levelUp) {
      showConfetti(context);
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(result.levelUp ? 'Level Up! 🎉' : 'Focus Session Complete!'),
        content: Text(
          'Great job focusing on "${widget.task.title}". You earned +${result.xpEarned} XP${result.levelUp ? ' and reached a new level!' : '!'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(ctx).pop(); // Go back from focus screen
            },
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.lg,
              children: [
                IconButton(
                  tooltip: 'Reset',
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetTimer,
                  iconSize: 32,
                  color: AppTheme.textSecondary,
                ),
                IconButton(
                  tooltip: 'Need more time (+5m)',
                  icon: const Icon(Icons.alarm_add),
                  onPressed: () => _addMoreTime(minutes: 5),
                  iconSize: 32,
                  color: AppTheme.textSecondary,
                ),
                FloatingActionButton.large(
                  onPressed: _toggleTimer,
                  child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 60),
                ).animate().scale(delay: 200.ms),
                IconButton(
                  tooltip: 'Finish now',
                  icon: const Icon(Icons.skip_next),
                  onPressed: _onTimerFinish,
                  iconSize: 32,
                  color: AppTheme.textSecondary,
                ),
                IconButton(
                  tooltip: 'Take a break',
                  icon: const Icon(Icons.free_breakfast),
                  onPressed: _takeBreak,
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