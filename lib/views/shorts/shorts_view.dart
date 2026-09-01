import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/shorts_viewmodel.dart';
import '../settings/settings_view.dart';
import '../shared/timer_status_bar.dart';

/// Full-screen vertical swipeable Shorts/Reels view with strict 18+ and category filtration.
class ShortsView extends StatelessWidget {
  const ShortsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final shortsVm = context.watch<ShortsViewModel>();

    // 1. If Shorts toggle is disabled in Settings
    if (!settingsVm.enableShorts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reels & Shorts')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.youtubeRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_off_rounded, size: 64, color: AppColors.youtubeRed),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Shorts are Disabled',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Reels and Shorts have been disabled in your settings to protect against mindless doomscrolling and keep your screen time productive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. If no shorts match current category filters
    if (shortsVm.shorts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reels & Shorts')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 54, color: AppColors.islamicGreen),
              const SizedBox(height: 16),
              const Text(
                'No Shorts Match Active Safe Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                '18+ reels and out-of-category shorts are strictly blocked.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Vertical Shorts Feed
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: shortsVm.shorts.length,
            onPageChanged: shortsVm.setCurrentIndex,
            itemBuilder: (context, index) {
              final short = shortsVm.shorts[index];
              final isLiked = shortsVm.isLiked(short.id);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Video Background / Thumbnail
                  CachedNetworkImage(
                    imageUrl: short.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.surface),
                    errorWidget: (context, url, error) => Container(color: Colors.black),
                  ),

                  // Gradient Shade
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Center Play Icon Indicator
                  const Center(
                    child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white38),
                  ),

                  // Bottom Left Video Details
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.youtubeRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            short.categoryTag.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Channel Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.surfaceLight,
                              child: Text(
                                short.author.isNotEmpty ? short.author[0] : 'U',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              short.author,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          short.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Side Interaction Bar
                  Positioned(
                    bottom: 32,
                    right: 12,
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: isLiked ? AppColors.youtubeRed : Colors.white,
                            size: 28,
                          ),
                          onPressed: () => shortsVm.toggleLike(short.id),
                        ),
                        Text(
                          short.likeCountFormatted,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 28),
                          onPressed: () {},
                        ),
                        const Text('Comments', style: TextStyle(fontSize: 11, color: Colors.white)),
                        const SizedBox(height: 16),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 28),
                          onPressed: () {},
                        ),
                        const Text('Share', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Status Bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: TimerStatusBar()),
          ),
        ],
      ),
    );
  }
}
