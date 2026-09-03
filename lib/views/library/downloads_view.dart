import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/download_service.dart';
import '../../models/download_task_model.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../player/player_view.dart';
import '../shared/app_snackbar.dart';

/// Screen displaying offline downloaded videos with storage details and playback controls.
class DownloadsView extends StatelessWidget {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DownloadService.instance,
      builder: (context, _) {
        final downloads = DownloadService.instance.downloadedVideos;
        final totalBytes = downloads.fold<int>(
          0,
          (sum, d) => sum + d.fileSizeBytes,
        );
        final totalSizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

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
              'Downloads',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (downloads.isNotEmpty)
                IconButton(
                  tooltip: 'Storage Info',
                  icon: const Icon(Icons.info_outline, color: Colors.white70),
                  onPressed: () {
                    AppSnackBar.showInfo(
                      context,
                      'Total offline storage: $totalSizeMb MB (${downloads.length} videos)',
                      icon: Icons.storage_rounded,
                    );
                  },
                ),
            ],
          ),
          body: downloads.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    // Offline Header Banner
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_done_outlined,
                            color: Color(0xFF3EA6FF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${downloads.length} video${downloads.length > 1 ? 's' : ''} available offline ($totalSizeMb MB)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF3EA6FF),
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    // Downloaded Videos List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: downloads.length,
                        separatorBuilder: (_, index) =>
                            const Divider(color: Colors.white10, height: 16),
                        itemBuilder: (context, index) {
                          final item = downloads[index];
                          return _buildDownloadItem(context, item);
                        },
                      ),
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_for_offline_outlined,
                size: 44,
                color: Color(0xFFAAAAAA),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No downloaded videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Videos you download will appear here so you can watch them offline without an internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadItem(BuildContext context, DownloadedVideoModel item) {
    final video = item.video;

    return InkWell(
      onTap: () {
        context.read<PlayerViewModel>().playVideo(video);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerView(video: video)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with offline badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    width: 120,
                    height: 68,
                    fit: BoxFit.cover,
                    errorWidget: (_, url, error) => Container(
                      width: 120,
                      height: 68,
                      color: AppColors.surfaceElevated,
                      child: const Icon(
                        Icons.video_library,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
                // Duration pill
                if (video.durationFormatted.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
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
                // Offline icon overlay
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download_done,
                      color: Color(0xFF3EA6FF),
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Video info
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
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.author} • ${item.formattedSize}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF3EA6FF),
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Downloaded • Ready for offline',
                        style: TextStyle(
                          color: Color(0xFF3EA6FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // More Options (Delete)
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () {
                _showDownloadOptionsBottomSheet(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadOptionsBottomSheet(
    BuildContext context,
    DownloadedVideoModel item,
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
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                ),
                title: const Text(
                  'Play offline video',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<PlayerViewModel>().playVideo(item.video);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerView(video: item.video),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.youtubeRed,
                ),
                title: const Text(
                  'Delete download',
                  style: TextStyle(color: AppColors.youtubeRed, fontSize: 14),
                ),
                subtitle: Text(
                  'Frees up ${item.formattedSize} of storage',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await DownloadService.instance.deleteDownloadedVideo(
                    item.video.id,
                  );
                  if (context.mounted) {
                    AppSnackBar.showSuccess(
                      context,
                      'Download deleted (${item.formattedSize} freed)',
                      icon: Icons.delete_sweep_rounded,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
