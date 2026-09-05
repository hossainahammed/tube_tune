import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../../viewmodels/shorts_viewmodel.dart';
import '../../player/player_view.dart';
import '../../shared/app_snackbar.dart';

/// Horizontal carousel for YouTube Shorts / Reels (only visible if Shorts switch is ON).
class ShortsShelfWidget extends StatelessWidget {
  final List<VideoModel> shorts;

  const ShortsShelfWidget({super.key, required this.shorts});

  @override
  Widget build(BuildContext context) {
    if (shorts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelf Header (Official YouTube Shorts)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.youtubeRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Shorts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFFAAAAAA)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shorts shelf can be toggled in Settings'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Horizontal Shorts List
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shorts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final short = shorts[index];
              return InkWell(
                onTap: () {
                  context.read<PlayerViewModel>().playVideo(short);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlayerView(video: short)),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 145,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical 9:16 Thumbnail
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: short.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.surfaceElevated),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Icon(Icons.play_arrow, color: Colors.white),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showShortOptionsBottomSheet(context, short),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.more_vert, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Text(
                                  short.viewCountFormatted,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        short.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.surfaceElevated, thickness: 4),
      ],
    );
  }

  void _showShortOptionsBottomSheet(BuildContext context, VideoModel short) {
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
                leading: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 24),
                title: const Text('Play next in queue', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<PlayerViewModel>().playNextInQueue(short);
                  AppSnackBar.showSuccess(
                    context,
                    'Added to queue',
                    icon: Icons.playlist_play_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.watch_later_outlined, color: Colors.white, size: 22),
                title: const Text('Save to Watch Later', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<PlayerViewModel>().toggleWatchLater(short);
                  AppSnackBar.showSuccess(
                    context,
                    'Saved to Watch Later',
                    icon: Icons.watch_later_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 24),
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
                leading: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(
                    context,
                    'https://youtu.be/${short.id} link copied!',
                    icon: Icons.link_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.do_not_disturb_on_outlined, color: Colors.white, size: 22),
                title: const Text('Not interested', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<HomeViewModel>().markVideoNotInterested(short);
                  context.read<ShortsViewModel>().markShortNotInterested(short);
                  AppSnackBar.showSuccess(
                    context,
                    'Short removed. We won\'t recommend it again.',
                    icon: Icons.check_circle_outline_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white, size: 22),
                title: Text(
                  'Don\'t recommend channel',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  short.author,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<HomeViewModel>().blockChannel(short.author, channelId: short.channelId);
                  context.read<ShortsViewModel>().blockChannel(short.author, channelId: short.channelId);
                  AppSnackBar.showSuccess(
                    context,
                    'We won\'t recommend videos from "${short.author}" again.',
                    icon: Icons.block_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white, size: 22),
                title: const Text('Report', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showInfo(
                    context,
                    'Thank you for reporting. Our team will review.',
                    icon: Icons.flag_rounded,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
