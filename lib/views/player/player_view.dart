import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/constants/app_colors.dart';
import '../../models/video_model.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/timer_status_bar.dart';

/// Full Video Player Screen featuring ad-free playback, channel info, comments, and filtered recommendations.
class PlayerView extends StatefulWidget {
  final VideoModel video;

  const PlayerView({super.key, required this.video});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late YoutubePlayerController _controller;
  bool _isDescriptionExpanded = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final isLiked = playerVm.isLiked(widget.video.id);
    final isSaved = playerVm.isWatchLater(widget.video.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TimerStatusBar(),

            // 1. YouTube Video Player Frame
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  YoutubePlayer(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                  ),
                  if (playerVm.isAdBlocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accentGreen, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 12, color: AppColors.accentGreen),
                            SizedBox(width: 4),
                            Text('Ad-Blocked', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Video Details & Feed
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Views & Upload Time
                    Text(
                      '${widget.video.viewCountFormatted} • ${widget.video.uploadDate}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Actions Bar (Like, Dislike, Share, Save)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionButton(
                            icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            label: widget.video.likeCountFormatted,
                            color: isLiked ? AppColors.youtubeRed : null,
                            onTap: () => playerVm.toggleLike(widget.video.id),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.thumb_down_outlined,
                            label: 'Dislike',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                            label: isSaved ? 'Saved' : 'Save',
                            color: isSaved ? AppColors.accentGreen : null,
                            onTap: () => playerVm.toggleWatchLater(widget.video),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.surfaceElevated, thickness: 0.8),

                    // Channel Bar
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceLight,
                          child: Text(
                            widget.video.author.isNotEmpty ? widget.video.author[0] : 'C',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.video.author,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Verified Creator',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isSubscribed = !_isSubscribed);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubscribed ? AppColors.surfaceLight : AppColors.youtubeRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: Text(_isSubscribed ? 'Subscribed' : 'Subscribe'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Expandable Description Box
                    InkWell(
                      onTap: () {
                        setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.description.isNotEmpty
                                  ? widget.video.description
                                  : 'No additional description provided for this video.',
                              maxLines: _isDescriptionExpanded ? 10 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDescriptionExpanded ? 'Show less' : '...more',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Comments Section Preview
                    _buildCommentsSection(playerVm),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.surfaceElevated, thickness: 1),

                    // Related / Up-Next Filtered Videos
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Up Next (Filtered & Safe)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.shield_outlined, size: 16, color: AppColors.islamicGreen),
                        ],
                      ),
                    ),

                    if (playerVm.relatedVideos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No further related videos match active category filters.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...playerVm.relatedVideos.map((v) => VideoCardWidget(video: v)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(PlayerViewModel playerVm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Comments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                '${playerVm.comments.length}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (playerVm.comments.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.surfaceElevated,
                  child: Text(
                    playerVm.comments.first.author.isNotEmpty ? playerVm.comments.first.author[0] : 'U',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerVm.comments.first.author,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      Text(
                        playerVm.comments.first.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'No comments yet.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
