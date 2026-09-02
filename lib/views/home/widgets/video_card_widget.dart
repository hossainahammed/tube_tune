import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../player/player_view.dart';

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

                  // Duration Pill (Bottom Right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                          letterSpacing: 0.2,
                        ),
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceElevated,
                    backgroundImage: video.channelAvatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(video.channelAvatarUrl)
                        : null,
                    child: video.channelAvatarUrl.isEmpty
                        ? Text(
                            video.author.isNotEmpty ? video.author[0].toUpperCase() : 'Y',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          )
                        : null,
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
                          '${video.author} • ${video.viewCountFormatted} • ${video.uploadDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved to Watch Later'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text('Save to playlist', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved to playlist'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined, color: Colors.white),
                title: const Text('Download video', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading video (Ad-Free)...'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('https://youtu.be/${video.id} link copied!'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
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
