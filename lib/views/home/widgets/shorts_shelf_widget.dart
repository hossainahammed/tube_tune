import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/video_model.dart';
import '../../../viewmodels/player_viewmodel.dart';
import '../../player/player_view.dart';

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
        // Shelf Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.youtubeRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Shorts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.islamicGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '18+ Filtered',
                  style: TextStyle(fontSize: 10, color: AppColors.islamicGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Horizontal List
        SizedBox(
          height: 240,
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
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: short.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.surfaceLight),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceLight,
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
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
}
