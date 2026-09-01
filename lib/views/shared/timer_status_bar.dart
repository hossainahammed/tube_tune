import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/settings_viewmodel.dart';

/// Top bar indicator showing active screen time limit countdown and safe-filter status.
class TimerStatusBar extends StatelessWidget {
  const TimerStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final timerState = settingsVm.timerService.state;

    if (!timerState.isTimerEnabled && !settingsVm.strictCategoryMode) {
      return const SizedBox.shrink();
    }

    final isTimeRunningLow = timerState.sessionRemainingSeconds < 300; // < 5 mins

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isTimeRunningLow && timerState.isTimerEnabled
            ? AppColors.error.withValues(alpha: 0.9)
            : AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(
            color: isTimeRunningLow && timerState.isTimerEnabled
                ? AppColors.error
                : AppColors.cardBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            timerState.isTimerEnabled ? Icons.timer_outlined : Icons.shield_outlined,
            size: 15,
            color: isTimeRunningLow && timerState.isTimerEnabled
                ? Colors.white
                : AppColors.accentGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timerState.isTimerEnabled
                  ? 'Session Timer: ${timerState.sessionRemainingFormatted} remaining'
                  : 'Safe Mode & Category Isolation Active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isTimeRunningLow && timerState.isTimerEnabled
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (settingsVm.block18Plus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.islamicGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.islamicGreen.withValues(alpha: 0.5), width: 0.5),
              ),
              child: const Text(
                '18+ Blocked',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.islamicGreen),
              ),
            ),
          if (settingsVm.enableAdBlock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.youtubeRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.youtubeRed.withValues(alpha: 0.5), width: 0.5),
              ),
              child: const Text(
                'Ad-Free',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.youtubeRedLight),
              ),
            ),
        ],
      ),
    );
  }
}
