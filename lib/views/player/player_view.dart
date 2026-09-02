import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
                          onTap: () => _showShareBottomSheet(context),
                        ),
                        const SizedBox(width: 8),

                        // Remix Button
                        _buildActionPill(
                          icon: Icons.cut_outlined,
                          label: 'Remix',
                          onTap: () => _showRemixBottomSheet(context),
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
                                PopupMenuButton<CommentSortOrder>(
                                  icon: const Icon(Icons.sort, color: Colors.white, size: 22),
                                  tooltip: 'Sort by',
                                  color: AppColors.surfaceElevated,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (order) => playerVm.setCommentSortOrder(order),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: CommentSortOrder.top,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check,
                                            size: 18,
                                            color: playerVm.commentSortOrder == CommentSortOrder.top
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Top comments',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: playerVm.commentSortOrder == CommentSortOrder.top
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: CommentSortOrder.newest,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check,
                                            size: 18,
                                            color: playerVm.commentSortOrder == CommentSortOrder.newest
                                                ? Colors.white
                                                : Colors.transparent,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Newest first',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: playerVm.commentSortOrder == CommentSortOrder.newest
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

  Color _getAvatarColor(String author) {
    const colors = [
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF673AB7),
      Color(0xFF3F51B5),
      Color(0xFF2196F3),
      Color(0xFF009688),
      Color(0xFF4CAF50),
      Color(0xFFFF5722),
      Color(0xFF795548),
      Color(0xFF00BCD4),
    ];
    return colors[author.hashCode.abs() % colors.length];
  }

  Widget _buildCommentTile(CommentModel c, PlayerViewModel playerVm) {
    final avatarColor = _getAvatarColor(c.author);
    final isVerified = c.author.contains('News') || c.author.contains('TV') || c.author.contains('BBC') || c.author.contains('Al Jazeera');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: avatarColor,
          backgroundImage: c.authorAvatar.isNotEmpty
              ? CachedNetworkImageProvider(c.authorAvatar)
              : null,
          child: c.authorAvatar.isEmpty
              ? Text(
                  c.author.isNotEmpty ? c.author[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                )
              : null,
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
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle, size: 12, color: Color(0xFFAAAAAA)),
                  ],
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
                style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.35),
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

  /// Official YouTube Share Bottom Sheet with Social Apps & Copy Link
  void _showShareBottomSheet(BuildContext context) {
    final cleanId = cleanYoutubeId(widget.video.id);
    final shareUrl = 'https://youtu.be/$cleanId';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Share',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Video Preview Card
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: widget.video.thumbnailUrl,
                          width: 64,
                          height: 38,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(width: 64, height: 38, color: Colors.black26),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.video.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Share to',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFAAAAAA)),
                ),
                const SizedBox(height: 12),

                // Horizontal Social Apps List
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSocialAppIcon(
                        name: 'WhatsApp',
                        icon: Icons.chat,
                        bgColor: const Color(0xFF25D366),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareUrl)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            await Clipboard.setData(ClipboardData(text: shareUrl));
                            _showToast('Link copied! WhatsApp not installed.');
                          }
                        },
                      ),
                      _buildSocialAppIcon(
                        name: 'Facebook',
                        icon: Icons.facebook,
                        bgColor: const Color(0xFF1877F2),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final uri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            await Clipboard.setData(ClipboardData(text: shareUrl));
                            _showToast('Link copied to clipboard');
                          }
                        },
                      ),
                      _buildSocialAppIcon(
                        name: 'X',
                        icon: Icons.alternate_email,
                        bgColor: Colors.black,
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final uri = Uri.parse('https://twitter.com/intent/tweet?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(widget.video.title)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            await Clipboard.setData(ClipboardData(text: shareUrl));
                            _showToast('Link copied to clipboard');
                          }
                        },
                      ),
                      _buildSocialAppIcon(
                        name: 'Telegram',
                        icon: Icons.send,
                        bgColor: const Color(0xFF229ED9),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final uri = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(widget.video.title)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            await Clipboard.setData(ClipboardData(text: shareUrl));
                            _showToast('Link copied to clipboard');
                          }
                        },
                      ),
                      _buildSocialAppIcon(
                        name: 'Gmail',
                        icon: Icons.email,
                        bgColor: const Color(0xFFEA4335),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final uri = Uri.parse('mailto:?subject=${Uri.encodeComponent(widget.video.title)}&body=${Uri.encodeComponent(shareUrl)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            await Clipboard.setData(ClipboardData(text: shareUrl));
                            _showToast('Link copied to clipboard');
                          }
                        },
                      ),
                      _buildSocialAppIcon(
                        name: 'Messages',
                        icon: Icons.message,
                        bgColor: const Color(0xFF00897B),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final uri = Uri.parse('sms:?body=${Uri.encodeComponent(shareUrl)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            await Clipboard.setData(ClipboardData(text: shareUrl));
                            _showToast('Link copied to clipboard');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppColors.surfaceLight, height: 24),

                // Quick YouTube Actions Row (Copy Link, Create Post, Embed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareActionTile(
                      icon: Icons.link,
                      label: 'Copy link',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        if (bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                          _showToast('Link copied to clipboard');
                        }
                      },
                    ),
                    _buildShareActionTile(
                      icon: Icons.post_add_outlined,
                      label: 'Create post',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _showCreatePostDialog(shareUrl);
                      },
                    ),
                    _buildShareActionTile(
                      icon: Icons.code,
                      label: 'Embed',
                      onTap: () async {
                        final embed = '<iframe width="560" height="315" src="https://www.youtube.com/embed/$cleanId" frameborder="0" allowfullscreen></iframe>';
                        await Clipboard.setData(ClipboardData(text: embed));
                        if (bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                          _showToast('Embed code copied to clipboard');
                        }
                      },
                    ),
                    _buildShareActionTile(
                      icon: Icons.qr_code_2,
                      label: 'QR Code',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _showQrCodeDialog(shareUrl);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialAppIcon({
    required String name,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: bgColor,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceElevated,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Official YouTube Remix Bottom Sheet (Sound, Cut, Green Screen, Collab)
  void _showRemixBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remix',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 1. Use this sound
                _buildRemixOptionTile(
                  icon: Icons.music_note,
                  title: 'Use this sound',
                  subtitle: 'Create a Short with audio from this video',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showRemixStudioSheet(
                      context,
                      modeTitle: 'Sound Remix',
                      modeDescription: 'Using audio track from: ${widget.video.title}',
                      modeIcon: Icons.music_note,
                    );
                  },
                ),

                // 2. Cut this video
                _buildRemixOptionTile(
                  icon: Icons.content_cut,
                  title: 'Cut this video',
                  subtitle: 'Sample up to 5 seconds of this video for your Short',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showRemixStudioSheet(
                      context,
                      modeTitle: 'Cut Video Segment',
                      modeDescription: 'Sample video segment from: ${widget.video.title}',
                      modeIcon: Icons.content_cut,
                    );
                  },
                ),

                // 3. Green screen
                _buildRemixOptionTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Green screen',
                  subtitle: 'Use this video as the background for your Short',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showRemixStudioSheet(
                      context,
                      modeTitle: 'Green Screen Studio',
                      modeDescription: 'Projecting background from: ${widget.video.title}',
                      modeIcon: Icons.camera_alt_outlined,
                    );
                  },
                ),

                // 4. Collab
                _buildRemixOptionTile(
                  icon: Icons.view_sidebar_outlined,
                  title: 'Collab',
                  subtitle: 'Record next to this video in a split-screen Short',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showRemixStudioSheet(
                      context,
                      modeTitle: 'Collab Split-Screen',
                      modeDescription: 'Side-by-side recording with: ${widget.video.title}',
                      modeIcon: Icons.view_sidebar_outlined,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemixOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceElevated,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  /// Interactive YouTube Shorts Remix Studio modal
  void _showRemixStudioSheet(
    BuildContext context, {
    required String modeTitle,
    required String modeDescription,
    required IconData modeIcon,
  }) {
    int durationSec = 15;
    double startSeconds = 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(modeIcon, color: const Color(0xFFFF0000), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              modeTitle,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modeDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // 9:16 Shorts Studio Preview Card
                    Center(
                      child: Container(
                        width: 160,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF0000), width: 2),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(widget.video.thumbnailUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${durationSec}s',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.graphic_eq, size: 12, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '0:${startSeconds.toInt().toString().padLeft(2, '0')} - 0:${(startSeconds + durationSec).toInt().toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
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
                    const SizedBox(height: 16),

                    // Duration Toggle (15s vs 60s)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('15s'),
                          selected: durationSec == 15,
                          selectedColor: const Color(0xFFFF0000),
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: durationSec == 15 ? Colors.white : const Color(0xFFAAAAAA),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => durationSec = 15);
                          },
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('60s'),
                          selected: durationSec == 60,
                          selectedColor: const Color(0xFFFF0000),
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: durationSec == 60 ? Colors.white : const Color(0xFFAAAAAA),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => durationSec = 60);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Segment Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF0000),
                        inactiveTrackColor: AppColors.surfaceElevated,
                        thumbColor: Colors.white,
                        overlayColor: Colors.red.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: startSeconds,
                        min: 0.0,
                        max: 45.0,
                        onChanged: (val) {
                          setModalState(() => startSeconds = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Create Short Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.videocam, color: Colors.white),
                        label: const Text(
                          'Create Short',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showToast('🎉 Remix Short created from "${widget.video.title}"!');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePostDialog(String url) {
    final postController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create a post', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: postController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'What are your thoughts on this video?',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3EA6FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _showToast('Community post published!');
              },
              child: const Text('Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showQrCodeDialog(String url) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Scan to Watch', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 160, color: Colors.black),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: const Color(0xFF282828),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
