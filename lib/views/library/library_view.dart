import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../notifications/notifications_view.dart';
import '../player/player_view.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';
import '../shared/cast_bottom_sheet.dart';
import '../shared/google_signin_dialog.dart';
import '../shared/timer_status_bar.dart';

/// "You" Tab identical to official YouTube mobile including Profile, History, Playlists, and Protection Summary.
class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'You',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Cast Icon
          AnimatedBuilder(
            animation: CastService.instance,
            builder: (context, _) {
              final isConnected = CastService.instance.isConnected;
              return IconButton(
                icon: Icon(
                  isConnected ? Icons.cast_connected_rounded : Icons.cast_outlined,
                  color: isConnected ? const Color(0xFF4285F4) : Colors.white,
                  size: 22,
                ),
                tooltip: isConnected ? 'Casting to TV' : 'Connect to a device',
                onPressed: () => CastBottomSheet.show(context),
              );
            },
          ),

          // Notifications Bell
          AnimatedBuilder(
            animation: NotificationService.instance,
            builder: (context, _) {
              final unreadCount = NotificationService.instance.unreadCount;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsView()),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 23),
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
          IconButton(
            icon: const Icon(
              Icons.search_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SearchView()));
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 23,
            ),
            tooltip: 'Settings & Filter Control',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const TimerStatusBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.youtubeRed,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // 1. YouTube Profile Header Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: authVm.isLoggedIn
                            ? const Color(0xFF4285F4)
                            : AppColors.surfaceElevated,
                        backgroundImage:
                            authVm.isLoggedIn && user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: !authVm.isLoggedIn
                            ? const Icon(
                                Icons.account_circle,
                                size: 42,
                                color: AppColors.textSecondary,
                              )
                            : (user.avatarUrl.isEmpty
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0] : 'U',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authVm.isLoggedIn ? user.name : 'Guest User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authVm.isLoggedIn
                                  ? user.email
                                  : '@tubetune • Sign in to sync',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (!authVm.isLoggedIn) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            const GoogleSignInDialog(),
                                      );
                                    } else {
                                      authVm.signOut();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          authVm.isLoggedIn
                                              ? Icons.logout
                                              : Icons.login,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          authVm.isLoggedIn
                                              ? 'Sign Out'
                                              : 'Sign In',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsView(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Filters & Time',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. History Header with "View All"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (playerVm.watchHistory.isNotEmpty)
                        InkWell(
                          onTap: () => playerVm.clearHistory(),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.youtubeRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Watch History Carousel (Identical to YouTube "You" page)
                  if (playerVm.watchHistory.isNotEmpty)
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: playerVm.watchHistory.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final video = playerVm.watchHistory[index];
                          return InkWell(
                            onTap: () {
                              context.read<PlayerViewModel>().playVideo(video);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlayerView(video: video),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 150,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: video.thumbnailUrl,
                                          width: 150,
                                          height: 85,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color:
                                                    AppColors.surfaceElevated,
                                              ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              video.durationFormatted,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // YouTube Red progress bar
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 3,
                                            color: AppColors.youtubeRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    video.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    video.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFAAAAAA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'This list has no videos yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 3. Playlists & Shortcuts (YouTube style)
                  const Text(
                    'Playlists',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.watch_later_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Watch Later',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${playerVm.watchLater.length} videos',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.thumb_up_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Liked videos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${playerVm.likedVideoIds.length} videos',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. TubeTune Protection Status Summary Card (Ad-Block, 18+ Filter & Time Schedule)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.accentGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Active Protection & Controls',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsView(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Configure',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: AppColors.surfaceLight,
                          height: 20,
                        ),
                        _buildStatusRow(
                          Icons.block,
                          'Ad-Blocker',
                          settingsVm.enableAdBlock ? 'ACTIVE' : 'Disabled',
                          AppColors.accentGreen,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          Icons.shield_rounded,
                          '18+ & Content Mode',
                          settingsVm.allow18Plus ? 'UNRESTRICTED' : 'Safe Mode',
                          settingsVm.allow18Plus
                              ? AppColors.youtubeRed
                              : AppColors.accentGreen,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          Icons.bolt,
                          'Reels / Shorts',
                          settingsVm.enableShorts ? 'Enabled' : 'BLOCKED',
                          settingsVm.enableShorts
                              ? Colors.white
                              : AppColors.youtubeRed,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          Icons.timer,
                          'Daily Auto-Lock',
                          settingsVm.timerService.isScheduleEnabled
                              ? 'Active'
                              : 'Off',
                          AppColors.accentAmber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    IconData icon,
    String label,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
