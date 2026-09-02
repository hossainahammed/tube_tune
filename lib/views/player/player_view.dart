import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/constants/app_colors.dart';
import '../../models/comment_model.dart';
import '../../models/video_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/timer_status_bar.dart';

/// Fullscreen / In-depth Video Player Screen identical to official YouTube mobile.
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
  bool _isDisliked = false;
  final TextEditingController _commentInputController = TextEditingController();

  static String cleanYoutubeId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('v=')) {
      return trimmed.split('v=')[1].split('&')[0];
    }
    if (trimmed.length > 11) {
      return trimmed.substring(0, 11);
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    final cleanId = cleanYoutubeId(widget.video.id);

    _controller = YoutubePlayerController.fromVideoId(
      videoId: cleanId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        playsInline: true,
        strictRelatedVideos: false,
      ),
    );

    // Ensure player viewmodel initializes video state and loads realistic comments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlayerViewModel>().playVideo(widget.video);
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    _commentInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerVm = context.watch<PlayerViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final isLiked = playerVm.isLiked(widget.video.id);
    final displayLikeCount = playerVm.getDisplayLikeCount(widget.video);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TimerStatusBar(),

            // Top Video Player Container (16:9)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  YoutubePlayer(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  if (playerVm.isAdBlocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accentGreen, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 12, color: AppColors.accentGreen),
                            SizedBox(width: 4),
                            Text(
                              'Ad-Free',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Video Details & Feed
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Video Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
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

                  // Views, Upload Date, and Expandable Description Preview
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.video.viewCountFormatted,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.video.uploadDate,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isDescriptionExpanded ? 'Show less' : '...more',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_isDescriptionExpanded && widget.video.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.video.description,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFDDDDDD), height: 1.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Channel Row (Avatar, Name, Subscriber count, Subscribe Button)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceElevated,
                          backgroundImage: widget.video.channelAvatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(widget.video.channelAvatarUrl)
                              : null,
                          child: widget.video.channelAvatarUrl.isEmpty
                              ? const Icon(Icons.account_circle, size: 28, color: Color(0xFFAAAAAA))
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
                                content: Text(_isSubscribed
                                    ? 'Subscribed to ${widget.video.author}'
                                    : 'Subscription removed'),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (_isDisliked) setState(() => _isDisliked = false);
                                  playerVm.toggleLike(widget.video.id);
                                },
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                        size: 16,
                                        color: isLiked ? Colors.white : const Color(0xFFAAAAAA),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        displayLikeCount,
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
                                onTap: () {
                                  setState(() {
                                    _isDisliked = !_isDisliked;
                                  });
                                  if (_isDisliked && isLiked) {
                                    playerVm.toggleLike(widget.video.id);
                                  }
                                },
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Icon(
                                    _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                    size: 16,
                                    color: _isDisliked ? Colors.white : const Color(0xFFAAAAAA),
                                  ),
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
                                content: Text('https://youtu.be/${cleanYoutubeId(widget.video.id)} link copied!'),
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
                                content: Text('Downloading in 1080p (Ad-Free)...'),
                                duration: Duration(seconds: 2),
                                backgroundColor: AppColors.surfaceElevated,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // Save to Watch Later
                        _buildActionPill(
                          icon: playerVm.isWatchLater(widget.video.id) ? Icons.bookmark : Icons.bookmark_border,
                          label: playerVm.isWatchLater(widget.video.id) ? 'Saved' : 'Save',
                          onTap: () => playerVm.toggleWatchLater(widget.video),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Comments Teaser Card (Tap to open full interactive comments sheet)
                  InkWell(
                    onTap: () => _showCommentsBottomSheet(context),
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
                                '${playerVm.comments.length}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFAAAAAA)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF4285F4),
                                child: Text(
                                  authVm.currentUser.name.isNotEmpty
                                      ? authVm.currentUser.name[0]
                                      : 'Y',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  playerVm.comments.isNotEmpty
                                      ? playerVm.comments.first.text
                                      : 'Add a comment...',
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

                  // Up Next / Related Videos List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Up Next',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${playerVm.relatedVideos.length} safe videos',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...playerVm.relatedVideos.map(
                    (v) => VideoCardWidget(video: v),
                  ),

                  const SizedBox(height: 40),
                ],
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

  /// Authentic Interactive YouTube Comments Bottom Sheet with Add Comment input & Like interaction
  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Consumer2<PlayerViewModel, AuthViewModel>(
                builder: (context, playerVm, authVm, _) {
                  return Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Comments',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${playerVm.comments.length}',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.sort, color: Colors.white, size: 20),
                                  tooltip: 'Sort by',
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pop(bottomSheetContext),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.surfaceLight, height: 1),

                      // Scrollable list of realistic community comments
                      Expanded(
                        child: playerVm.comments.isEmpty
                            ? const Center(
                                child: Text(
                                  'No comments yet. Be the first to comment!',
                                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: playerVm.comments.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 18),
                                itemBuilder: (context, index) {
                                  final c = playerVm.comments[index];
                                  return _buildCommentTile(c, playerVm);
                                },
                              ),
                      ),

                      // Pinned Interactive Add Comment Bar (YouTube Mobile Style)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border(
                            top: BorderSide(color: AppColors.cardBorder, width: 0.5),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF4285F4),
                                child: Text(
                                  authVm.currentUser.name.isNotEmpty
                                      ? authVm.currentUser.name[0]
                                      : 'Y',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: TextField(
                                    controller: _commentInputController,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: 'Add a comment...',
                                      hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        playerVm.addComment(widget.video.id, val, authVm.currentUser);
                                        _commentInputController.clear();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send_rounded, color: Color(0xFF3EA6FF), size: 22),
                                onPressed: () {
                                  final text = _commentInputController.text;
                                  if (text.trim().isNotEmpty) {
                                    playerVm.addComment(widget.video.id, text, authVm.currentUser);
                                    _commentInputController.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(CommentModel c, PlayerViewModel playerVm) {
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
                    '@${c.author.toLowerCase().replaceAll(' ', '_')}',
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
                style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
              ),
              const SizedBox(height: 6),
              // Comment action buttons (Like, Dislike, Reply)
              Row(
                children: [
                  InkWell(
                    onTap: () => playerVm.toggleCommentLike(c.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            c.isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 14,
                            color: c.isLikedByMe ? const Color(0xFF3EA6FF) : const Color(0xFFAAAAAA),
                          ),
                          if (c.likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              c.likeCountFormatted,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.isLikedByMe ? const Color(0xFF3EA6FF) : const Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.thumb_down_outlined, size: 14, color: Color(0xFFAAAAAA)),
                  const SizedBox(width: 16),
                  const Text(
                    'Reply',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
