import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../player/player_view.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/channel_avatar_widget.dart';

/// Horizontal carousel for Live News & 24/7 Broadcasts identical to official YouTube mobile.
class BreakingNewsShelfWidget extends StatelessWidget {
  final List<VideoModel> liveStreams;

  const BreakingNewsShelfWidget({super.key, required this.liveStreams});

  @override
  Widget build(BuildContext context) {
    if (liveStreams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelf Header (Official YouTube Live News styling)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.youtubeRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live News & Broadcasts',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFFAAAAAA)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showShelfOptionsBottomSheet(context),
              ),
            ],
          ),
        ),

        // Horizontal Live Cards Carousel
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: liveStreams.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final video = liveStreams[index];
              return InkWell(
                onTap: () {
                  context.read<PlayerViewModel>().playVideo(video);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlayerView(video: video)),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 16:9 Thumbnail with LIVE Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: video.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppColors.surfaceElevated),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Icon(
                                    Icons.live_tv_rounded,
                                    size: 36,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.youtubeRed,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sensors_rounded,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Metadata Row (Avatar + Title + Channel info)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChannelAvatarWidget(
                            author: video.author,
                            avatarUrl: video.channelAvatarUrl,
                            radius: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${video.author} • 🔴 ${video.viewCountFormatted} watching',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFFF5252),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFFAAAAAA)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showLiveCardOptionsBottomSheet(context, video),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.surfaceLight, height: 1, thickness: 1),
      ],
    );
  }

  void _showShelfOptionsBottomSheet(BuildContext context) {
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
                leading: const Icon(Icons.refresh_rounded, color: Colors.white),
                title: const Text('Refresh live broadcasts', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<HomeViewModel>().loadFeed(isRefresh: true);
                  AppSnackBar.showSuccess(
                    context,
                    'Refreshing live broadcasts...',
                    icon: Icons.refresh_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.sensors_off_rounded, color: Colors.white),
                title: const Text('Not interested in live broadcasts', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showInfo(
                    context,
                    'Section feedback saved',
                    icon: Icons.check_circle_outline,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined, color: Colors.white),
                title: const Text('Send feedback', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showInfo(
                    context,
                    'Thank you for your feedback',
                    icon: Icons.thumb_up_alt_outlined,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLiveCardOptionsBottomSheet(BuildContext context, VideoModel video) {
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
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share live broadcast', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showSuccess(
                    context,
                    'Link copied: https://youtu.be/${video.id}',
                    icon: Icons.link_rounded,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.white),
                title: Text("Don't recommend ${video.author}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showInfo(
                    context,
                    "We won't recommend this live channel again",
                    icon: Icons.check_circle_outline,
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
