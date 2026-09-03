import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../models/app_notification_model.dart';
import '../../models/video_model.dart';
import '../player/player_view.dart';
import '../search/search_view.dart';
import '../shared/app_snackbar.dart';

/// Authentic YouTube Notifications Screen with All/Mentions filter, unread indicators, and 1-tap playback.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final NotificationService _notifService = NotificationService.instance;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Mark notifications as read upon opening the notifications screen like real YouTube
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifService.markAllAsRead();
    });
  }

  void _openVideo(AppNotificationModel notif) {
    final video = VideoModel(
      id: notif.videoId,
      title: notif.title.replaceAll('🔴', '').trim(),
      author: notif.channelName,
      channelId: 'channel_${notif.channelName.hashCode.abs()}',
      channelAvatarUrl: notif.channelAvatarUrl,
      duration: notif.isLive
          ? Duration.zero
          : const Duration(minutes: 15, seconds: 20),
      thumbnailUrl: notif.videoThumbnailUrl,
      viewCount: 142000,
      uploadDate: notif.timeAgo,
      isLive: notif.isLive,
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PlayerView(video: video)));
  }

  void _showNotificationOptions(AppNotificationModel notif) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.visibility_off_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Hide this notification',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _notifService.removeNotification(notif.id);
                AppSnackBar.showInfo(context, 'Notification hidden');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_off_outlined,
                color: Colors.white,
              ),
              title: Text(
                'Turn off all from ${notif.channelName}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _notifService.muteChannel(notif.channelName);
                AppSnackBar.showInfo(
                  context,
                  'Notifications turned off for ${notif.channelName}',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text(
                'Notification settings',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                AppSnackBar.showInfo(
                  context,
                  'Push notifications are active for subscribed channels.',
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_outlined,
              size: 23,
              color: Colors.white,
            ),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SearchView()));
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: Colors.white,
            ),
            tooltip: 'Options',
            onPressed: () {
              _notifService.markAllAsRead();
              AppSnackBar.showSuccess(
                context,
                'All notifications marked as read',
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _notifService,
        builder: (context, _) {
          final notifications = _notifService.notifications;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter chips (All | Mentions)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedFilter == 'all',
                      onSelected: (_) =>
                          setState(() => _selectedFilter = 'all'),
                      selectedColor: Colors.white,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'all'
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      showCheckmark: false,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Mentions'),
                      selected: _selectedFilter == 'mentions',
                      onSelected: (_) =>
                          setState(() => _selectedFilter = 'mentions'),
                      selectedColor: Colors.white,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'mentions'
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      showCheckmark: false,
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surfaceLight, height: 1),

              // Notification List
              Expanded(
                child: _selectedFilter == 'mentions'
                    ? _buildEmptyState(
                        icon: Icons.alternate_email_rounded,
                        title: 'No mentions yet',
                        subtitle: 'When other creators or viewers mention you in comments or videos, you will see it here.',
                      )
                    : notifications.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Your notifications live here',
                        subtitle: 'Subscribe to your favorite channels to get notified about their latest uploads and live streams.',
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (ctx, idx) => const Divider(
                          color: AppColors.surfaceLight,
                          height: 0.8,
                        ),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationTile(notif);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(AppNotificationModel notif) {
    return InkWell(
      onTap: () => _openVideo(notif),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notif.isRead
            ? Colors.transparent
            : AppColors.surfaceLight.withValues(alpha: 0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel Avatar with optional unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceElevated,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: notif.channelAvatarUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, error) => Text(
                        notif.channelName.isNotEmpty
                            ? notif.channelName[0]
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!notif.isRead)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3EA6FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: notif.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (notif.isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.youtubeRed,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        notif.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 16:9 Thumbnail preview on the right
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: notif.videoThumbnailUrl,
                width: 64,
                height: 38,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, error) => Container(
                  width: 64,
                  height: 38,
                  color: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // 3-dots option menu
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showNotificationOptions(notif),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
