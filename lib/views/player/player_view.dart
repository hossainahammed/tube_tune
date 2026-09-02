import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/constants/app_colors.dart';
import '../../models/video_model.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/timer_status_bar.dart';

/// Full Video Player Screen matching official YouTube mobile layout with Ad-Free playback.
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

            // 1. YouTube Video Player Frame with Ad-Blocked Shield
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
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accentGreen, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 12, color: AppColors.accentGreen),
                            SizedBox(width: 4),
                            Text(
                              'Ad-Blocked',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Video Details & Related Videos List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Text(
                        widget.video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Views & Upload Time Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Text(
                            '${widget.video.viewCountFormatted} • ${widget.video.uploadDate}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                            child: Text(
                              _isDescriptionExpanded ? '...less' : '...more',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expandable Description Box
                    if (_isDescriptionExpanded)
                      Container(
                        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.description.isNotEmpty
                                  ? widget.video.description
                                  : 'Watch and enjoy this high-definition video on YouTube.',
                              style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                            ),
                            if (widget.video.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: widget.video.tags.take(5).map((t) {
                                  return Text('#$t', style: const TextStyle(fontSize: 12, color: AppColors.accentCyan));
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Channel Bar (Avatar, Name, Subscribers, Subscribe Button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceElevated,
                            backgroundImage: widget.video.channelAvatarUrl.isNotEmpty
                                ? NetworkImage(widget.video.channelAvatarUrl)
                                : null,
                            child: widget.video.channelAvatarUrl.isEmpty
                                ? Text(
                                    widget.video.author.isNotEmpty ? widget.video.author[0] : 'Y',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.video.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '3.85M subscribers',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                                ),
                              ],
                            ),
                          ),
                          // YouTube Subscribe Button
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _isSubscribed = !_isSubscribed);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isSubscribed ? 'Subscribed to ${widget.video.author}' : 'Subscription removed'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSubscribed ? AppColors.surfaceElevated : Colors.white,
                              foregroundColor: _isSubscribed ? Colors.white : Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSubscribed) ...[
                                  const Icon(Icons.notifications_active, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _isSubscribed ? 'Subscribed' : 'Subscribe',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Actions Bar (Unified Like/Dislike, Share, Remix, Download, Save)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          // Unified YouTube Like / Dislike Pill Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => playerVm.toggleLike(widget.video.id),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                          size: 16,
                                          color: isLiked ? Colors.white : const Color(0xFFAAAAAA),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.video.likeCountFormatted,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: AppColors.surfaceLight,
                                ),
                                InkWell(
                                  onTap: () {},
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Icon(Icons.thumb_down_outlined, size: 16, color: Color(0xFFAAAAAA)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Share Button
                          _buildActionPill(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('https://youtu.be/${widget.video.id} link copied!'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),

                          // Remix Button
                          _buildActionPill(
                            icon: Icons.cut_outlined,
                            label: 'Remix',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),

                          // Download Button (Ad-Free)
                          _buildActionPill(
                            icon: Icons.download_outlined,
                            label: 'Download',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Downloading video (Ad-Free)...'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),

                          // Save to Watch Later Button
                          _buildActionPill(
                            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                            label: isSaved ? 'Saved' : 'Save',
                            onTap: () => playerVm.toggleWatchLater(widget.video),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Comments Teaser Card (YouTube mobile style)
                    InkWell(
                      onTap: () => _showCommentsBottomSheet(context, playerVm),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Comments',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${playerVm.comments.length * 48}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                                ),
                                const Spacer(),
                                const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFAAAAAA)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Color(0xFF4285F4),
                                  child: Icon(Icons.person, size: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    playerVm.comments.isNotEmpty
                                        ? playerVm.comments.first.text
                                        : 'MashaAllah! Very educational and inspiring content. Loved it!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Up Next / Related Videos List (Identical to YouTube Mobile)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: playerVm.relatedVideos.length,
                      itemBuilder: (context, index) {
                        final relatedVideo = playerVm.relatedVideos[index];
                        return VideoCardWidget(video: relatedVideo);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, PlayerViewModel playerVm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: playerVm.comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final c = playerVm.comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.surfaceElevated,
                            child: Text(
                              c.author.isNotEmpty ? c.author[0] : 'U',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.author,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFAAAAAA)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.publishedTime,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  c.text,
                                  style: const TextStyle(fontSize: 13, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
