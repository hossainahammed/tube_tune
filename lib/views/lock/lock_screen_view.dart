import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../shared/pin_dialog.dart';

/// Full-screen Auto-Lock Break Overlay with live auto-unlock countdown, Multiple Schedule Locks, and PIN unlock override.
class LockScreenView extends StatelessWidget {
  const LockScreenView({super.key});

  void _handleEmergencyUnlock(BuildContext context, SettingsViewModel settingsVm) async {
    final timerState = settingsVm.timerService.state;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PinDialog(
        title: 'Emergency Unlock',
        description: 'Enter your 4-digit security PIN to override the lock.',
        expectedPin: timerState.pinCode.isNotEmpty ? timerState.pinCode : null,
      ),
    );

    if (result == true) {
      settingsVm.unlockWithPin(timerState.pinCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final timerState = settingsVm.timerService.state;
    final isScheduleLocked = timerState.isScheduleLocked;

    return PopScope(
      canPop: false, // Prevent back navigation while locked
      child: Scaffold(
        backgroundColor: const Color(0xFF090A0F),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                (isScheduleLocked ? const Color(0xFF1A237E) : AppColors.youtubeRedDark).withValues(alpha: 0.25),
                const Color(0xFF07080C),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Glowing Shield / Lock Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isScheduleLocked ? AppColors.accentCyan : AppColors.youtubeRed).withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isScheduleLocked ? AppColors.accentCyan : AppColors.youtubeRed).withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isScheduleLocked ? Icons.bedtime_rounded : Icons.lock_clock_rounded,
                  size: 72,
                  color: isScheduleLocked ? AppColors.accentCyan : AppColors.youtubeRedLight,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                isScheduleLocked ? 'Scheduled Bedtime Lock Active' : 'Screen Time Limit Reached',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Friendly Digital Wellbeing Message
              Text(
                isScheduleLocked
                    ? 'TubeTune is currently locked based on your daily usage schedule to maintain healthy habits.'
                    : 'Great job taking a break! TubeTune is currently locked to help you rest your eyes and stay balanced.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              if (isScheduleLocked) ...[
                // Multiple Schedule Windows Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ALLOWED WATCH WINDOWS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentCyan,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...timerState.scheduleWindows.where((w) => w.isEnabled).map((win) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accentCyan),
                              const SizedBox(width: 8),
                              Text(
                                '${win.name}: ${win.timeFormatted}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      const Text(
                        'The app will automatically unlock during your scheduled allowed windows.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Auto-Unlock Live Countdown Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'AUTOMATIC UNLOCK IN',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.islamicGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timerState.breakRemainingFormatted,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The app will automatically unlock when this timer reaches 00:00.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Emergency PIN Override Button
              OutlinedButton.icon(
                onPressed: () => _handleEmergencyUnlock(context, settingsVm),
                icon: const Icon(Icons.pin_outlined, size: 18),
                label: const Text('Unlock with PIN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceElevated),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
