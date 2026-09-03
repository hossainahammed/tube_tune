import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/video_model.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../player/player_view.dart';

/// Screen displaying the user's liked videos.
class LikedVideosView extends StatelessWidget {
  const LikedVideosView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final likedIds = playerVm.likedVideoIds;

    // Resolve liked videos from history, watch later, or curated videos
    final allKnown = [
      ...playerVm.watchHistory,
      ...playerVm.watchLater,
      ...playerVm.relatedVideos,
      if (playerVm.currentVideo != null) playerVm.currentVideo!,
    ];

    final Map<String, VideoModel> dedup = {};
    for (final v in allKnown) {
      if (likedIds.contains(v.id)) {
        dedup[v.id] = v;
      }
    }
    final likedVideos = dedup.values.toList();

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
          'Liked videos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: likedVideos.isEmpty
          ? Center(
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
                        Icons.thumb_up_outlined,
                        size: 44,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Liked Videos Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the thumbs up button on any video to add it to your liked playlist.',
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
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: likedVideos.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10, height: 16),
              itemBuilder: (context, index) {
                final video = likedVideos[index];
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
                      const SizedBox(width: 12),
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
                    ],
                  ),
                );
              },
            ),
    );
  }
}
