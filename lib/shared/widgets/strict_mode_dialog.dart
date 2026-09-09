import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/app_settings.dart';

class StrictModeDialog extends StatefulWidget {
  final String featureKey;
  final String featureName;
  final AppSettings settings;
  final Future<void> Function() onStartCountdown;
  final VoidCallback onDisableConfirmed;
  final VoidCallback onCancelCountdown;

  const StrictModeDialog({
    super.key,
    required this.featureKey,
    required this.featureName,
    required this.settings,
    required this.onStartCountdown,
    required this.onDisableConfirmed,
    required this.onCancelCountdown,
  });

  @override
  State<StrictModeDialog> createState() => _StrictModeDialogState();
}

class _StrictModeDialogState extends State<StrictModeDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.settings.isStrictModeDelayActive && widget.settings.targetFeatureToDisable == widget.featureKey) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.settings.isStrictModeDelayActive && widget.settings.targetFeatureToDisable == widget.featureKey) {
      widget.onCancelCountdown();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final isTarget = settings.targetFeatureToDisable == widget.featureKey;
    final isCompleted = settings.isStrictModeDelayCompleted;
    final isActive = settings.isStrictModeDelayActive;

    if (isTarget && (isActive || isCompleted)) {
      if (isCompleted) {
        return AlertDialog(
          title: Text('Disable ${widget.featureName}'),
          content: const Text('The delay timer has completed. You can now disable this feature.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDisableConfirmed();
              },
              child: const Text('Disable', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      }
      final remaining = settings.strictModeDelayRemaining;
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      return AlertDialog(
        title: const Text('Strict Mode Active'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You must wait until the delay timer completes to disable ${widget.featureName}.'),
            const SizedBox(height: 16),
            Text(timeStr, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      );
    } else if ((isActive || isCompleted) && !isTarget) {
      return AlertDialog(
        title: const Text('Another Timer Active'),
        content: const Text('A delay timer is already running for another feature. You can only disable one feature at a time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      );
    } else {
      return AlertDialog(
        title: const Text('Start Delay Timer?'),
        content: Text('Strict Mode is active. To disable ${widget.featureName}, you must start a ${settings.strictModeDelayMinutes}-minute timer. The option cannot be disabled until the timer ends.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await widget.onStartCountdown();
              _startTimer();
              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Start Timer'),
          ),
        ],
      );
    }
  }
}
