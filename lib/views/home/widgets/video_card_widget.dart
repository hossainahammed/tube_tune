import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../player/player_view.dart';

/// Full-width YouTube style video card widget.
class VideoCardWidget extends StatelessWidget {
  final VideoModel video;

  const VideoCardWidget({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<PlayerViewModel>().playVideo(video);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerView(video: video),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Video Thumbnail with Duration Badge
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.surfaceLight),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.play_circle_outline, size: 48, color: AppColors.textMuted),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: video.isLive ? AppColors.youtubeRed : Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.durationFormatted,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Video Info Bar (Avatar, Title, Channel, Stats, 3-dots Menu)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: video.channelAvatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(video.channelAvatarUrl)
                      : null,
                  child: video.channelAvatarUrl.isEmpty
                      ? Text(
                          video.author.isNotEmpty ? video.author[0].toUpperCase() : 'Y',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Title & Subtitle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video.author} • ${video.viewCountFormatted} • ${video.uploadDate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3-Dots Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) {
                    if (value == 'watch_later') {
                      context.read<PlayerViewModel>().toggleWatchLater(video);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to Watch Later'),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'watch_later',
                      child: Row(
                        children: [
                          Icon(Icons.watch_later_outlined, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 10),
                          Text('Save to Watch Later', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 10),
                          Text('Share', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
