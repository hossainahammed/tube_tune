import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/settings_viewmodel.dart';

/// Top bar indicator that only appears when a session timer is in its final warning minutes.
class TimerStatusBar extends StatelessWidget {
  const TimerStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final timerState = settingsVm.timerService.state;

    // Only show if user has enabled a session timer and less than 2 minutes remain before auto-lock
    if (!timerState.isTimerEnabled || timerState.sessionRemainingSeconds > 120) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.error,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'App Auto-Locks in ${timerState.sessionRemainingFormatted}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
