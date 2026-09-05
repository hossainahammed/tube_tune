import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../player/player_view.dart';

/// Horizontal recommendation shelf showing personalized videos based on user watch and search history.
class SuggestedShelfWidget extends StatelessWidget {
  final List<VideoModel> suggestedVideos;

  const SuggestedShelfWidget({super.key, required this.suggestedVideos});

  @override
  Widget build(BuildContext context) {
    if (suggestedVideos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelf Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.youtubeRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.youtubeRed,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested for you',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Based on your watch & search activity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ),

        // Horizontal video list
        SizedBox(
          height: 195,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: suggestedVideos.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final video = suggestedVideos[index];
              return _buildSuggestedCard(context, video);
            },
          ),
        ),

        const SizedBox(height: 12),
        const Divider(color: AppColors.surfaceLight, height: 1),
      ],
    );
  }

  Widget _buildSuggestedCard(BuildContext context, VideoModel video) {
    return InkWell(
      onTap: () {
        context.read<PlayerViewModel>().playVideo(video);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerView(video: video)),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Duration
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    width: 170,
                    height: 98,
                    fit: BoxFit.cover,
                    errorWidget: (_, url, error) => Container(
                      width: 170,
                      height: 98,
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.video_library, color: Colors.white30),
                    ),
                  ),
                ),
                // Recommendation badge
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF3EA6FF), size: 10),
                        SizedBox(width: 3),
                        Text(
                          'Suggested',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Duration Pill
                if (video.durationFormatted.isNotEmpty)
                  Positioned(
                    bottom: 5,
                    right: 5,
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
            const SizedBox(height: 6),

            // Video Title
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),

            // Channel name
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
  }
}
