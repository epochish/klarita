import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Helper to fire a quick confetti celebration without needing to manage
/// a ConfettiController everywhere.
///
/// Usage:
///   showConfetti(context);
void showConfetti(BuildContext context) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  final controller = ConfettiController(duration: const Duration(seconds: 2));
  final entry = OverlayEntry(
    builder: (_) => _ConfettiWidget(controller: controller),
  );

  overlay.insert(entry);
  controller.play();

  // Remove overlay after animation completes
  Future.delayed(const Duration(seconds: 3), () {
    controller.dispose();
    entry.remove();
  });
}

class _ConfettiWidget extends StatelessWidget {
  final ConfettiController controller;
  const _ConfettiWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: ConfettiWidget(
          confettiController: controller,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.08,
          numberOfParticles: 30,
          maxBlastForce: 20,
          minBlastForce: 8,
          gravity: 0.3,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
          ],
        ),
      ),
    );
  }
} 