import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/download_service.dart';
import '../../models/video_model.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../player/player_view.dart';
import '../shared/app_snackbar.dart';

/// Screen displaying the user's saved "Watch Later" videos playlist.
class WatchLaterView extends StatelessWidget {
  const WatchLaterView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final videos = playerVm.watchLater;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Watch Later',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (videos.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF282828),
              onSelected: (value) {
                if (value == 'play_all') {
                  _playAll(context, videos);
                } else if (value == 'clear') {
                  _confirmClearAll(context, playerVm);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'play_all',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Play all', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: AppColors.youtubeRed, size: 20),
                      SizedBox(width: 12),
                      Text('Clear Watch Later', style: TextStyle(color: AppColors.youtubeRed)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: videos.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Playlist Banner Card (YouTube style)
                _buildPlaylistHeader(context, videos),

                const Divider(color: Colors.white10, height: 1),

                // Video List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: videos.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10, height: 16),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return _buildVideoItem(context, playerVm, video, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlaylistHeader(BuildContext context, List<VideoModel> videos) {
    final firstVideo = videos.first;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: firstVideo.thumbnailUrl,
                  width: 110,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 110,
                    height: 64,
                    color: AppColors.surface,
                    child: const Icon(Icons.watch_later, color: Colors.white30),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Watch Later',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${videos.length} video${videos.length == 1 ? '' : 's'} • Private playlist',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _playAll(context, videos),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                  label: const Text(
                    'Play all',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shufflePlay(context, videos),
                  icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Shuffle',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    PlayerViewModel playerVm,
    VideoModel video,
    int index,
  ) {
    return InkWell(
      onTap: () {
        playerVm.playVideo(video);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerView(video: video)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with Duration
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 120,
                    height: 68,
                    color: AppColors.surfaceElevated,
                    child: const Icon(Icons.video_library, color: Colors.white30),
                  ),
                ),
              ),
              if (video.durationFormatted.isNotEmpty)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      video.durationFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${video.author} • ${video.viewCountFormatted}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 3-Dots Menu (Remove, Download, Share)
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              _showVideoOptionsBottomSheet(context, playerVm, video);
            },
          ),
        ],
      ),
    );
  }

  void _showVideoOptionsBottomSheet(
    BuildContext context,
    PlayerViewModel playerVm,
    VideoModel video,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline, color: Colors.white),
                title: const Text('Play video', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  playerVm.playVideo(video);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerView(video: video)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.youtubeRed),
                title: const Text(
                  'Remove from Watch Later',
                  style: TextStyle(color: AppColors.youtubeRed, fontSize: 14),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await playerVm.toggleWatchLater(video);
                  if (context.mounted) {
                    AppSnackBar.showSuccess(
                      context,
                      'Removed from Watch Later',
                      icon: Icons.delete_outline,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined, color: Colors.white),
                title: const Text('Download video', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (kIsWeb) {
                    AppSnackBar.showInfo(
                      context,
                      'Offline video downloads are available on mobile app',
                      icon: Icons.smartphone_rounded,
                    );
                    return;
                  }
                  AppSnackBar.showInfo(
                    context,
                    'Downloading "${video.title}"...',
                    icon: Icons.downloading_rounded,
                  );
                  await DownloadService.instance.downloadVideo(video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(
                    context,
                    'Link copied: https://youtu.be/${video.id}',
                    icon: Icons.link_rounded,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.watch_later_outlined,
                size: 46,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Videos in Watch Later',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save videos you want to watch later by tapping the bookmark icon or the 3-dots menu on any video card.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Explore Videos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playAll(BuildContext context, List<VideoModel> videos) {
    if (videos.isEmpty) return;
    final playerVm = context.read<PlayerViewModel>();
    playerVm.playVideo(videos.first);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerView(video: videos.first)),
    );
  }

  void _shufflePlay(BuildContext context, List<VideoModel> videos) {
    if (videos.isEmpty) return;
    final randomIndex = Random().nextInt(videos.length);
    final targetVideo = videos[randomIndex];
    final playerVm = context.read<PlayerViewModel>();
    playerVm.playVideo(targetVideo);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerView(video: targetVideo)),
    );
  }

  void _confirmClearAll(BuildContext context, PlayerViewModel playerVm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Clear Watch Later?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'This will remove all saved videos from your Watch Later playlist.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              for (final v in List<VideoModel>.from(playerVm.watchLater)) {
                await playerVm.toggleWatchLater(v);
              }
              if (context.mounted) {
                AppSnackBar.showSuccess(
                  context,
                  'Watch Later cleared',
                  icon: Icons.delete_sweep_rounded,
                );
              }
            },
            child: const Text('Clear all', style: TextStyle(color: AppColors.youtubeRed)),
          ),
        ],
      ),
    );
  }
}
