import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'downloads_view.dart';
import 'liked_videos_view.dart';
import 'watch_later_view.dart';
import '../notifications/notifications_view.dart';
import '../player/player_view.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';
import '../shared/app_snackbar.dart';
import '../shared/cast_bottom_sheet.dart';
import '../shared/google_signin_dialog.dart';
import '../shared/timer_status_bar.dart';

/// "You" Tab identical to official YouTube mobile including Profile, History, Playlists, Feedback/Contact, and Protection Summary.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _senderEmailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _senderEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();
    final user = authVm.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
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

                  // Downloads (Offline videos)
                  AnimatedBuilder(
                    animation: DownloadService.instance,
                    builder: (context, _) {
                      final count = DownloadService.instance.downloadedCount;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DownloadsView()),
                          );
                        },
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.download_for_offline_rounded,
                            color: Color(0xFF3EA6FF),
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Downloads',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '$count video${count == 1 ? '' : 's'} available offline',
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
                      );
                    },
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WatchLaterView(),
                        ),
                      );
                    },
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LikedVideosView(),
                        ),
                      );
                    },
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

                  const SizedBox(height: 20),

                  // 5. User Feedback & Recommendation Message Box Card
                  _buildFeedbackAndContactCard(context),

                  const SizedBox(height: 28),

                  // 6. Developer Branding & Copyright Footer
                  _buildFooterBranding(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Contact & Recommendation Box where users can send messages directly to developer
  Widget _buildFeedbackAndContactCard(BuildContext context) {
    const developerEmail = 'hossainahammed627@gmail.com';
    final authVm = context.watch<AuthViewModel>();

    return Container(
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3EA6FF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: Color(0xFF3EA6FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendations & Feedback',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Send your suggestions or feature ideas directly to developer',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Optional sender email field (pre-filled if logged in)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: TextField(
              controller: _senderEmailController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: authVm.isLoggedIn
                    ? 'Reply email: ${authVm.currentUser.email}'
                    : 'Your Email (Optional, if you want a reply)',
                hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                border: InputBorder.none,
                isDense: true,
                icon: const Icon(Icons.alternate_email_rounded, size: 14, color: Color(0xFF888888)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Message / Recommendation Input Box
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _feedbackController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Type your recommendation, feature request, or feedback here...',
                hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Send Message + Copy Email
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _sendRecommendation(developerEmail),
                  icon: _isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    _isSending ? 'Sending to Inbox...' : 'Send to Developer',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.youtubeRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy Email ($developerEmail)',
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: developerEmail));
                  AppSnackBar.showSuccess(
                    context,
                    'Copied developer email: $developerEmail',
                    icon: Icons.copy_rounded,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF3EA6FF)),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              IconButton(
                tooltip: 'Open in Gmail/Mail app',
                onPressed: () => _openMailClient(developerEmail),
                icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Colors.white70),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendRecommendation(String email) async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      AppSnackBar.showInfo(
        context,
        'Please enter your message or recommendation first',
        icon: Icons.edit_note_rounded,
      );
      return;
    }

    setState(() => _isSending = true);

    final authVm = context.read<AuthViewModel>();
    final senderName = authVm.isLoggedIn ? authVm.currentUser.name : 'TubeTune App User';
    final customEmail = _senderEmailController.text.trim();
    final senderEmail = customEmail.isNotEmpty
        ? customEmail
        : (authVm.isLoggedIn ? authVm.currentUser.email : null);

    try {
      // 1. Send directly via backend delivery service to developer inbox
      final isSuccess = await FeedbackService.sendFeedback(
        message: text,
        senderName: senderName,
        senderEmail: senderEmail,
        category: 'Feature Recommendation & User Feedback',
      );

      if (!mounted) return;

      if (isSuccess) {
        _feedbackController.clear();
        _senderEmailController.clear();
        AppSnackBar.showSuccess(
          context,
          'Your message was sent directly to developer ($email)!',
          icon: Icons.mark_email_read_rounded,
        );
      } else {
        // 2. Fallback to Mail Client / Clipboard
        await _openMailClient(email, customText: text);
      }
    } catch (_) {
      if (mounted) {
        await _openMailClient(email, customText: text);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _openMailClient(String email, {String? customText}) async {
    final text = customText ?? _feedbackController.text.trim();
    final Uri mailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('TubeTune Recommendation & Feedback')}&body=${Uri.encodeComponent(text)}',
    );

    try {
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text.isNotEmpty ? text : email));
        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            'Copied details to clipboard. Send to: $email',
            icon: Icons.copy_rounded,
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text.isNotEmpty ? text : email));
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Copied details to clipboard. Send to: $email',
          icon: Icons.copy_rounded,
        );
      }
    }
  }

  /// Official Developer Branding & Copyright Footer
  Widget _buildFooterBranding(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icons/app_icon.png', width: 22, height: 22),
              const SizedBox(width: 8),
              const Text(
                'TubeTune',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'All Rights Reserved © 2026 Hossain Ahammed',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'hossainahammed627@gmail.com',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF3EA6FF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Safe, Ad-Free & Distraction-Free Video Experience',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF666666),
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
