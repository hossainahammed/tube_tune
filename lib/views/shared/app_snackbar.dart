import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Centralized Top-positioned Notification Banner & SnackBar.
/// All notifications and toast messages slide down smoothly from the top of the app.
class AppSnackBar {
  AppSnackBar._();

  /// Displays a floating notification banner at the top of the app.
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color backgroundColor = AppColors.surfaceElevated,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    // Position floating snackbar comfortably above keyboard when typing,
    // or above the bottom navigation bar and mini-player like official YouTube
    final bottomMargin = bottomInset > 0 ? bottomInset + 12 : 76.0;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: EdgeInsets.only(bottom: bottomMargin, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder, width: 0.8),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Green success banner from the top
  static void showSuccess(
    BuildContext context,
    String message, {
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      icon: icon ?? Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF1B2E22),
      textColor: Colors.white,
      iconColor: AppColors.accentGreen,
    );
  }

  /// Red error banner from the top
  static void showError(
    BuildContext context,
    String message, {
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      icon: icon ?? Icons.error_outline_rounded,
      backgroundColor: const Color(0xFF331618),
      textColor: Colors.white,
      iconColor: AppColors.youtubeRed,
    );
  }

  /// Amber / Orange warning banner from the top
  static void showWarning(
    BuildContext context,
    String message, {
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      icon: icon ?? Icons.warning_amber_rounded,
      backgroundColor: const Color(0xFF332612),
      textColor: Colors.white,
      iconColor: AppColors.accentAmber,
    );
  }

  /// Neutral / Blue information banner from the top
  static void showInfo(BuildContext context, String message, {IconData? icon}) {
    show(
      context,
      message: message,
      icon: icon ?? Icons.info_outline_rounded,
      backgroundColor: AppColors.surfaceElevated,
      textColor: Colors.white,
      iconColor: AppColors.accentCyan,
    );
  }
}
