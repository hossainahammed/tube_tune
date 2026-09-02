import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';
import 'google_signin_dialog.dart';

/// Top YouTube App Bar with official YouTube logo styling, Cast, Notifications, Search, and Profile Avatar.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final isFocusActive = settingsVm.selectedFocusMode != 'all' && settingsVm.selectedFocusMode.isNotEmpty;

    return AppBar(
      titleSpacing: 16,
      elevation: 0,
      backgroundColor: AppColors.background,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // YouTube Red Play Icon Badge
          Container(
            width: 28,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.youtubeRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 5),

          // "YouTube" Brand Text (Official Style)
          const Text(
            'YouTube',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),

          // Subtle Filter/Focus Indicator if active
          if (isFocusActive) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Text(
                settingsVm.selectedFocusMode == 'islamic_waz'
                    ? '🕌 Islamic'
                    : settingsVm.selectedFocusMode == 'kids_cartoons'
                        ? '👶 Kids'
                        : settingsVm.selectedFocusMode == 'news'
                            ? '📺 BD TV'
                            : '⚡ Filtered',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Cast Icon (Authentic YouTube)
        IconButton(
          icon: const Icon(Icons.cast_outlined, size: 22, color: Colors.white),
          tooltip: 'Cast to TV',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Searching for cast devices...'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),

        // Notifications Bell (Authentic YouTube)
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, size: 23, color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new notifications'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),

        // Search Icon (Authentic YouTube)
        IconButton(
          icon: const Icon(Icons.search_outlined, size: 24, color: Colors.white),
          tooltip: 'Search',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchView()),
            );
          },
        ),

        // User Profile Avatar (Tapping opens Account & TubeTune Settings)
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
            padding: const EdgeInsets.only(left: 4, right: 14),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: authVm.isLoggedIn ? const Color(0xFF4285F4) : AppColors.surfaceElevated,
              backgroundImage: authVm.isLoggedIn && user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: !authVm.isLoggedIn
                  ? const Icon(Icons.account_circle, size: 22, color: AppColors.textSecondary)
                  : (user.avatarUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0] : 'U',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null),
            ),
          ),
        ),
      ],
    );
  }
}
