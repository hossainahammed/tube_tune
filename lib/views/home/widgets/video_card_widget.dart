import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/download_service.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../player/player_view.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/channel_avatar_widget.dart';

/// Full-width video card widget matching official YouTube mobile interface.
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. YouTube 16:9 Thumbnail with Duration Pill
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.surfaceElevated),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.play_circle_outline, size: 48, color: AppColors.textMuted),
                    ),
                  ),

                  // Duration Pill / LIVE Badge (Bottom Right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (video.isLive || video.uploadDate.toLowerCase().contains('live'))
                            ? AppColors.youtubeRed
                            : Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (video.isLive || video.uploadDate.toLowerCase().contains('live')) ...[
                            const Icon(Icons.sensors_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            (video.isLive || video.uploadDate.toLowerCase().contains('live'))
                                ? 'LIVE'
                                : video.durationFormatted,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Video Metadata Row (Avatar, Title, Channel, Stats, 3-dots Menu)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel Avatar (36x36 circular)
                  ChannelAvatarWidget(
                    author: video.author,
                    avatarUrl: video.channelAvatarUrl,
                    radius: 18,
                  ),
                  const SizedBox(width: 12),

                  // Title & Channel Subtitle Info
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
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (video.isLive || video.uploadDate.toLowerCase().contains('live'))
                              ? '${video.author} • 🔴 ${video.viewCountFormatted} watching now'
                              : '${video.author} • ${video.viewCountFormatted} • ${video.uploadDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: (video.isLive || video.uploadDate.toLowerCase().contains('live'))
                                ? const Color(0xFFFF5252)
                                : const Color(0xFFAAAAAA),
                            fontWeight: (video.isLive || video.uploadDate.toLowerCase().contains('live'))
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3-Dots Action Menu (Opens authentic YouTube Bottom Sheet)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFFAAAAAA)),
                    onPressed: () => _showVideoOptionsBottomSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
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
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.watch_later_outlined, color: Colors.white),
                title: const Text('Save to Watch Later', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<PlayerViewModel>().toggleWatchLater(video);
                  AppSnackBar.showSuccess(
                    context,
                    'Saved to Watch Later',
                    icon: Icons.watch_later_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text('Save to playlist', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(
                    context,
                    'Saved to playlist',
                    icon: Icons.playlist_add_check_rounded,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  DownloadService.instance.isDownloaded(video.id)
                      ? Icons.download_done_rounded
                      : Icons.download_outlined,
                  color: DownloadService.instance.isDownloaded(video.id)
                      ? const Color(0xFF3EA6FF)
                      : Colors.white,
                ),
                title: Text(
                  DownloadService.instance.isDownloaded(video.id)
                      ? 'Downloaded (Offline)'
                      : 'Download video',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (DownloadService.instance.isDownloaded(video.id)) {
                    AppSnackBar.showInfo(
                      context,
                      'Video is already downloaded for offline mode',
                      icon: Icons.check_circle_rounded,
                    );
                    return;
                  }
                  AppSnackBar.showInfo(
                    context,
                    'Downloading "${video.title}"...',
                    icon: Icons.download_rounded,
                  );
                  final success = await DownloadService.instance.downloadVideo(video);
                  if (context.mounted) {
                    if (success) {
                      AppSnackBar.showSuccess(
                        context,
                        'Downloaded! Ready in Library > Downloads.',
                        icon: Icons.download_done_rounded,
                      );
                    } else {
                      AppSnackBar.showError(
                        context,
                        'Failed to download video. Please try again.',
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(
                    context,
                    'https://youtu.be/${video.id} link copied!',
                    icon: Icons.link_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.not_interested, color: Colors.white),
                title: const Text('Not interested', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
