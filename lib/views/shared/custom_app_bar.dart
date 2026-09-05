import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../notifications/notifications_view.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';
import 'cast_bottom_sheet.dart';
import 'google_signin_dialog.dart';

/// Top YouTube App Bar with official YouTube logo styling, Cast, Notifications, Search, and Profile Avatar.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 700;
    final searchWidth = (screenWidth * 0.38).clamp(320.0, 560.0);

    return AppBar(
      titleSpacing: isWide ? 16 : 12,
      elevation: 0,
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          // Left: Hamburger Menu Icon on desktop + TubeTune Logo & Brand Name
          if (isWide) ...[
            const Icon(Icons.menu, color: Colors.white, size: 24),
            const SizedBox(width: 16),
          ],
          SizedBox(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                const Text(
                  'TubeTune',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Colors.white,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),

          // YouTube Web Center Search Bar (on wide screens)
          if (isWide) ...[
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchView()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: searchWidth,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF303030), width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Search videos, waz, news, kids...',
                        style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF222222),
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                      ),
                      child: const Icon(Icons.search, size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
      actions: [
        // Cast Icon (Authentic YouTube Connect to a Device)
        AnimatedBuilder(
          animation: CastService.instance,
          builder: (context, _) {
            final isConnected = CastService.instance.isConnected;
            return IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              icon: Icon(
                isConnected ? Icons.cast_connected_rounded : Icons.cast_outlined,
                size: 20,
                color: isConnected ? const Color(0xFF4285F4) : Colors.white,
              ),
              tooltip: isConnected ? 'Casting to TV' : 'Connect to a device',
              onPressed: () => CastBottomSheet.show(context),
            );
          },
        ),

        // Notifications Bell (Authentic YouTube with live unread counter badge)
        AnimatedBuilder(
          animation: NotificationService.instance,
          builder: (context, _) {
            final unreadCount = NotificationService.instance.unreadCount;
            return IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsView()),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined, size: 21, color: Colors.white),
                  if (unreadCount > 0)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: AppColors.youtubeRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Search Icon (on mobile screens)
        if (!isWide)
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            icon: const Icon(Icons.search_outlined, size: 22, color: Colors.white),
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
            padding: const EdgeInsets.only(left: 4, right: 10),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: authVm.isLoggedIn ? const Color(0xFF4285F4) : AppColors.surfaceElevated,
              backgroundImage: authVm.isLoggedIn && user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: !authVm.isLoggedIn
                  ? const Icon(Icons.account_circle, size: 20, color: AppColors.textSecondary)
                  : (user.avatarUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0] : 'U',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null),
            ),
          ),
        ),
      ],
    );
  }
}
