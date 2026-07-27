import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A self-contained circular countdown timer.
///
/// Sits idle at [durationSeconds] until the person taps it — it does
/// NOT start automatically when the widget appears. Tapping starts or
/// pauses the countdown; when it reaches zero it fires a haptic
/// vibration and calls [onComplete]. No external vibration package is
/// needed — `HapticFeedback` from `flutter/services` covers the
/// "alert when done" requirement with zero extra dependencies.
class CircularCountdown extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback? onComplete;

  const CircularCountdown({
    super.key,
    required this.durationSeconds,
    this.onComplete,
  });

  @override
  State<CircularCountdown> createState() => _CircularCountdownState();
}

class _CircularCountdownState extends State<CircularCountdown> {
  Timer? _timer;
  late int _secondsRemaining;

  // Idle: timer has not been started yet (or was just reset) and is
  // waiting for the person to tap it. This is the initial state — the
  // countdown never runs on its own just because the screen opened.
  bool _isIdle = true;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;
    // Intentionally NOT starting the timer here. The person must tap
    // the circle to begin the countdown.
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        _onFinished();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _onFinished() {
    // Haptic + system alert when the hold/execution window ends.
    HapticFeedback.vibrate();
    widget.onComplete?.call();
  }

  void _handleTap() {
    if (_secondsRemaining == 0) {
      // Finished — tapping again restarts from the top.
      _reset();
      return;
    }
    setState(() {
      _isIdle = false;
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = widget.durationSeconds;
      _isRunning = false;
      _isIdle = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData get _centerIcon {
    if (_secondsRemaining == 0) return Icons.replay;
    if (_isIdle) return Icons.play_arrow;
    return _isRunning ? Icons.pause : Icons.play_arrow;
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.durationSeconds == 0
        ? 0
        : _secondsRemaining / widget.durationSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: AppColors.slate100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _secondsRemaining == 0
                          ? AppColors.mutedBlue
                          : AppColors.calmTeal,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_secondsRemaining',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    Icon(_centerIcon, size: 16, color: AppColors.slate400),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isIdle
              ? 'Tap to start'
              : (_isRunning ? 'Tap to pause' : 'Tap to resume'),
          style: const TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh, size: 16, color: AppColors.slate700),
          label: const Text(
            'Restart',
            style: TextStyle(color: AppColors.slate700),
          ),
        ),
      ],
    );
  }
}
