import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';
import 'google_signin_dialog.dart';

/// Top YouTube style App Bar with brand logo, search trigger, focus mode badge, and Google user avatar.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final focusMode = settingsVm.selectedFocusMode;
    final user = authVm.currentUser;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.youtubeRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Tube',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Tune',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.youtubeRedLight,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (focusMode != 'all' && focusMode.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.islamicGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.islamicGreen, width: 0.8),
              ),
              child: Text(
                focusMode == 'islamic_waz'
                    ? '🕌 Islamic'
                    : focusMode == 'kids_cartoons'
                        ? '👶 Kids'
                        : focusMode == 'news'
                            ? '📰 News'
                            : '⚡ Filtered',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.islamicGreen,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 24),
          tooltip: 'Safe Search',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchView()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22),
          tooltip: 'Filters & Settings',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsView()),
            );
          },
        ),
        InkWell(
          onTap: () {
            if (!authVm.isLoggedIn) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const GoogleSignInDialog(),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: authVm.isLoggedIn ? const Color(0xFF4285F4) : AppColors.surfaceLight,
              backgroundImage: authVm.isLoggedIn && user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: !authVm.isLoggedIn
                  ? const Icon(Icons.account_circle, size: 20, color: AppColors.textSecondary)
                  : (user.avatarUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0] : 'U',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
