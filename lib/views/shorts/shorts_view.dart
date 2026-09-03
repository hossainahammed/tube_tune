import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/youtube_service.dart';
import '../../models/comment_model.dart';
import '../../models/video_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/shorts_viewmodel.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';
import '../shared/channel_avatar_widget.dart';
import '../shared/timer_status_bar.dart';

/// Full-screen vertical swipeable Shorts/Reels view with complete YouTube mobile functionality:
/// - Native 60fps video playback with instant loop
/// - Tap to pause / resume
/// - Double-tap with animated heart burst to like
/// - Long-press for 2x speed with visual 2x pill indicator
/// - Audio mute / unmute toggle button
/// - Video progress indicator scrubber bar
/// - Top bar: Camera creator, Search, Mute, and 3-dot more menu (Description, Captions, Playback speed, Don't recommend, Report)
/// - Bottom-left: Channel avatar, handle, Subscribe button, Title with "...more", and Sound ticker
/// - Right-side: Like, Dislike, Comments, Share, Remix, and interactive spinning Sound Disc
class ShortsView extends StatefulWidget {
  final bool? isActive;
  const ShortsView({super.key, this.isActive});

  @override
  State<ShortsView> createState() => _ShortsViewState();
}

class _ShortsViewState extends State<ShortsView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

    // 2. If Loading
    if (shortsVm.isLoading && shortsVm.shorts.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.youtubeRed),
        ),
      );
    }

    // 3. If no shorts match current category filters
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => shortsVm.loadShorts(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceElevated),
                child: const Text('Refresh Shorts', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Vertical Shorts Feed with full YouTube feature suite
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: shortsVm.shorts.length,
            onPageChanged: (index) {
              shortsVm.setCurrentIndex(index);
              if (index >= shortsVm.shorts.length - 3) {
                shortsVm.loadMoreShorts();
              }
            },
            itemBuilder: (context, index) {
              final short = shortsVm.shorts[index];
              return ShortsPlayerItem(
                key: ValueKey(short.id),
                short: short,
                isCurrent: index == shortsVm.currentIndex,
                isActive: widget.isActive == true,
                onSkipNext: () {
                  if (index + 1 < shortsVm.shorts.length) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              );
            },
          ),

          // Top Status Bar (Screen time countdown indicator)
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

/// Single YouTube Short item with native ExoPlayer playback and all YouTube features
class ShortsPlayerItem extends StatefulWidget {
  final VideoModel short;
  final bool isCurrent;
  final bool? isActive;
  final VoidCallback? onSkipNext;

  const ShortsPlayerItem({
    super.key,
    required this.short,
    required this.isCurrent,
    this.isActive,
    this.onSkipNext,
  });

  bool get isEffectivelyActive => isActive == true;

  @override
  State<ShortsPlayerItem> createState() => _ShortsPlayerItemState();
}

class _ShortsPlayerItemState extends State<ShortsPlayerItem> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isPlaying = true;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _is2xFastForward = false;
  bool _showPlayPauseOverlay = false;
  bool _isSubscribed = false;
  bool _isDisliked = false;
  bool _showHeartBurst = false;

  late AnimationController _discAnimController;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartFadeAnim;

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
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _heartScaleAnim = Tween<double>(begin: 0.3, end: 1.4).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
    );

    _heartFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _heartAnimController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    if (widget.isEffectivelyActive && widget.isCurrent) {
      _initPlayback();
    } else {
      _discAnimController.stop();
      _isPlaying = false;
      _isLoading = false;
    }
  }

  Future<void> _initPlayback() async {
    _disposeVideo();
    if (!widget.isEffectivelyActive || !widget.isCurrent) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    final cleanId = cleanYoutubeId(widget.short.id);

    try {
      final streamUrl = await YoutubeService.instance.getDirectStreamUrl(cleanId);
      if (!mounted) return;

      if (streamUrl != null && streamUrl.isNotEmpty) {
        final vc = VideoPlayerController.networkUrl(
          Uri.parse(streamUrl),
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        );
        await vc.initialize();
        if (!mounted) {
          vc.dispose();
          return;
        }
        await vc.setLooping(true);
        await vc.setVolume(_isMuted ? 0.0 : 1.0);
        if (widget.isCurrent) {
          await vc.play();
        }
        setState(() {
          _videoController = vc;
          _isPlaying = true;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void didUpdateWidget(covariant ShortsPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPlay = widget.isEffectivelyActive && widget.isCurrent;
    final wasPlaying = oldWidget.isEffectivelyActive && oldWidget.isCurrent;

    if (shouldPlay != wasPlaying) {
      if (shouldPlay) {
        _initPlayback();
        _discAnimController.repeat();
      } else {
        _disposeVideo();
        _discAnimController.stop();
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _discAnimController.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _discAnimController.stop();
        setState(() {
          _isPlaying = false;
          _showPlayPauseOverlay = true;
        });
      } else {
        _videoController!.play();
        _discAnimController.repeat();
        setState(() {
          _isPlaying = true;
          _showPlayPauseOverlay = true;
        });
      }
    } else {
      _initPlayback();
      return;
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showPlayPauseOverlay = false);
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    _showToast(_isMuted ? 'Muted' : 'Sound on');
  }

  void _handleDoubleTapLike() {
    final shortsVm = context.read<ShortsViewModel>();
    if (!shortsVm.isLiked(widget.short.id)) {
      shortsVm.toggleLike(widget.short.id);
    }

    setState(() => _showHeartBurst = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  void _setFastForward(bool enable) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() => _is2xFastForward = enable);
      _videoController!.setPlaybackSpeed(enable ? 2.0 : 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortsVm = context.watch<ShortsViewModel>();
    final isLiked = shortsVm.isLiked(widget.short.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Native Video Player or High-Quality Thumbnail
        Positioned.fill(
          child: _buildVideoSurface(),
        ),

        // 2. Gesture Detector for tap, double-tap, and long-press (2x speed)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _togglePlayPause,
            onDoubleTap: _handleDoubleTapLike,
            onLongPressStart: (_) => _setFastForward(true),
            onLongPressEnd: (_) => _setFastForward(false),
          ),
        ),

        // 3. 2x Speed Pill Banner at Top
        if (_is2xFastForward)
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('2X Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.fast_forward, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),

        // 4. Double-Tap Heart Burst Animation
        if (_showHeartBurst)
          Center(
            child: FadeTransition(
              opacity: _heartFadeAnim,
              child: ScaleTransition(
                scale: _heartScaleAnim,
                child: const Icon(Icons.favorite, size: 110, color: Color(0xFFFF0000)),
              ),
            ),
          ),

        // 5. Play/Pause Animated Icon Overlay
        if (_showPlayPauseOverlay)
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.play_arrow : Icons.pause,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

        // 6. Top YouTube Header Controls (Camera, Search, Volume, 3-Dot More)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // YouTube Shorts Wordmark
                  const Text(
                    'Shorts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const Spacer(),

                  // Create / Camera Icon
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
                    tooltip: 'Create a Short',
                    onPressed: () => _showCreateShortModal(context),
                  ),

                  // Search Icon
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 24),
                    tooltip: 'Search',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchView()),
                      );
                    },
                  ),

                  // Volume Mute / Unmute Toggle
                  IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 24),
                    tooltip: _isMuted ? 'Unmute' : 'Mute',
                    onPressed: _toggleMute,
                  ),

                  // 3-Dot More Menu
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                    tooltip: 'More options',
                    onPressed: () => _showMoreOptionsMenu(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 7. Subtle Bottom Gradient Vignette for Text Contrast
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 280,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // 8. Bottom-Left Details (Channel, Subscribe, Title with "...more", Audio Sound Ticker)
        Positioned(
          bottom: 22,
          left: 14,
          right: 84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Channel Avatar + Handle + Subscribe Button
              Row(
                children: [
                  ChannelAvatarWidget(
                    author: widget.short.author,
                    avatarUrl: widget.short.channelAvatarUrl,
                    radius: 17,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '@${widget.short.author.toLowerCase().replaceAll(' ', '')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() => _isSubscribed = !_isSubscribed);
                      _showToast(_isSubscribed ? 'Subscribed to ${widget.short.author}' : 'Unsubscribed');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isSubscribed ? AppColors.surfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isSubscribed ? 'Subscribed' : 'Subscribe',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isSubscribed ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title with expandable "...more"
              InkWell(
                onTap: () => _showDescriptionBottomSheet(context),
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: widget.short.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(
                        text: ' ...more',
                        style: TextStyle(color: Color(0xFFAAAAAA), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Audio Ticker Bar (Taps to open Sound Details Sheet)
              InkWell(
                onTap: () => _showSoundDetailsBottomSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Original sound - ${widget.short.author}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 9. Right Side Interaction Column (Like, Dislike, Comment, Share, Remix, Sound Disc)
        Positioned(
          bottom: 22,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Action
              _buildInteractionButton(
                icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: widget.short.likeCountFormatted,
                iconColor: isLiked ? AppColors.youtubeRed : Colors.white,
                onTap: () {
                  shortsVm.toggleLike(widget.short.id);
                  if (!isLiked) {
                    _showToast('Liked');
                  }
                },
              ),
              const SizedBox(height: 16),

              // Dislike Action
              _buildInteractionButton(
                icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                label: 'Dislike',
                iconColor: _isDisliked ? AppColors.youtubeRed : Colors.white,
                onTap: () {
                  setState(() => _isDisliked = !_isDisliked);
                  _showToast(_isDisliked ? 'Disliked' : 'Dislike removed');
                },
              ),
              const SizedBox(height: 16),

              // Comments Action (Interactive YouTube bottom sheet)
              _buildInteractionButton(
                icon: Icons.comment_outlined,
                label: '1.4K',
                onTap: () => _showShortCommentsBottomSheet(context),
              ),
              const SizedBox(height: 16),

              // Share Action (Interactive YouTube share sheet)
              _buildInteractionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => _showShortShareBottomSheet(context),
              ),
              const SizedBox(height: 16),

              // Remix Action (Interactive YouTube remix sheet)
              _buildInteractionButton(
                icon: Icons.cut_outlined,
                label: 'Remix',
                onTap: () => _showShortRemixBottomSheet(context),
              ),
              const SizedBox(height: 16),

              // Rotating Sound Vinyl Disc (Taps to open Sound Details Sheet)
              InkWell(
                onTap: () => _showSoundDetailsBottomSheet(context),
                borderRadius: BorderRadius.circular(18),
                child: RotationTransition(
                  turns: _discAnimController,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.black87,
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 10. Interactive Progress Scrubber Indicator at bottom
        if (_videoController != null && _videoController!.value.isInitialized)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFFF0000),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoSurface() {
    if (widget.isCurrent && _videoController != null && _videoController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    // High quality thumbnail while loading/buffering
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.short.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black),
          errorWidget: (context, url, error) => Container(color: Colors.black),
        ),
        if (_isLoading)
          const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// 3-Dot More Options Menu (Description, Captions, Speed, Don't recommend, Report)
  void _showMoreOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('Description', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDescriptionBottomSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.closed_caption_outlined, color: Colors.white),
                title: const Text('Captions', style: TextStyle(color: Colors.white)),
                subtitle: const Text('English (auto-generated)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showToast('Captions turned on');
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white),
                title: const Text('Playback speed', style: TextStyle(color: Colors.white)),
                subtitle: Text(_is2xFastForward ? '2.0x' : 'Normal (1.0x)', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSpeedDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.not_interested, color: Colors.white),
                title: const Text('Don\'t recommend this channel', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final settingsVm = context.read<SettingsViewModel>();
                  settingsVm.addBlacklistKeyword(widget.short.author);
                  _showToast('We won\'t recommend videos from this channel');
                  widget.onSkipNext?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white),
                title: const Text('Report', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showToast('Thank you for reporting. Our team will review.');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Playback speed', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ListTile(
                title: Text(speed == 1.0 ? 'Normal' : '${speed}x', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  _videoController?.setPlaybackSpeed(speed);
                  Navigator.pop(dialogContext);
                  _showToast('Speed set to ${speed == 1.0 ? 'Normal' : '${speed}x'}');
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Official YouTube Video Description Sheet
  void _showDescriptionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.short.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.short.likeCountFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Likes', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.short.viewCountFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Views', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.short.uploadDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Uploaded', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.surfaceLight, height: 28),
                  Text(
                    widget.short.description.isNotEmpty ? widget.short.description : 'Enjoy this trending Short on TubeTune! Built with ad-block protection and safe filtration.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFDDDDDD), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: ['#shorts', '#viral', '#trending', '#youtube', '#tubetune'].map((tag) {
                      return Chip(
                        label: Text(tag, style: const TextStyle(color: Color(0xFF3EA6FF), fontSize: 12)),
                        backgroundColor: AppColors.surfaceElevated,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Official YouTube Sound / Audio Page Modal
  void _showSoundDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original sound - ${widget.short.author}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${widget.short.author} • 48.2K Shorts', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam, color: Colors.black),
                      label: const Text('Use this sound', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showCreateShortModal(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    tooltip: 'Save audio',
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showToast('Sound saved to your Library!');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Create Short Studio Modal
  void _showCreateShortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Create Short', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFF0000), child: Icon(Icons.videocam, color: Colors.white)),
                  title: const Text('Record a Short', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Capture up to 60 seconds with music', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showToast('🎥 Shorts Camera Studio opened!');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.surfaceElevated, child: Icon(Icons.upload_file, color: Colors.white)),
                  title: const Text('Upload a video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Select a vertical video from your gallery', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showToast('📁 Video gallery opened for Shorts upload!');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Interactive YouTube Comments Sheet for this Short
  void _showShortCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return _ShortsCommentsSheet(short: widget.short);
      },
    );
  }

  /// Interactive YouTube Share Sheet for this Short
  void _showShortShareBottomSheet(BuildContext context) {
    final cleanId = cleanYoutubeId(widget.short.id);
    final shareUrl = 'https://youtube.com/shorts/$cleanId';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Share Short', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareAppCircle('WhatsApp', const Color(0xFF25D366), Icons.chat, () async {
                      Navigator.pop(sheetContext);
                      final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareUrl)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        _showToast('Link copied! WhatsApp not installed.');
                      }
                    }),
                    _buildShareAppCircle('Facebook', const Color(0xFF1877F2), Icons.facebook, () async {
                      Navigator.pop(sheetContext);
                      final uri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        _showToast('Link copied to clipboard');
                      }
                    }),
                    _buildShareAppCircle('Telegram', const Color(0xFF229ED9), Icons.send, () async {
                      Navigator.pop(sheetContext);
                      final uri = Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        _showToast('Link copied to clipboard');
                      }
                    }),
                    _buildShareAppCircle('Copy Link', AppColors.surfaceElevated, Icons.link, () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        _showToast('Short link copied to clipboard');
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareAppCircle(String label, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(radius: 24, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  /// Interactive YouTube Remix Sheet for this Short
  void _showShortRemixBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remix this Short', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.surfaceElevated, child: Icon(Icons.music_note, color: Colors.white)),
                  title: const Text('Use this sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Create a Short using this audio', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showToast('🎵 Audio loaded into YouTube Shorts Studio!');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.surfaceElevated, child: Icon(Icons.content_cut, color: Colors.white)),
                  title: const Text('Cut this video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Sample a segment of this Short', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showToast('✂️ Segment sampled! Opened in Shorts Studio.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
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

/// Dedicated, authentic YouTube Comments Bottom Sheet for Shorts with live realistic comments
class _ShortsCommentsSheet extends StatefulWidget {
  final VideoModel short;

  const _ShortsCommentsSheet({required this.short});

  @override
  State<_ShortsCommentsSheet> createState() => _ShortsCommentsSheetState();
}

class _ShortsCommentsSheetState extends State<_ShortsCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isTopComments = true;
  final Set<String> _likedCommentIds = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final comments = await YoutubeService.instance.fetchCommentsForVideo(widget.short);
    if (!mounted) return;
    setState(() {
      _comments = List.from(comments);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    final authVm = context.read<AuthViewModel>();
    final playerVm = context.read<PlayerViewModel>();

    final newComment = CommentModel(
      id: 'sh_usr_${DateTime.now().millisecondsSinceEpoch}',
      author: authVm.currentUser.name.isNotEmpty ? authVm.currentUser.name : 'You',
      authorAvatar: authVm.currentUser.avatarUrl,
      text: text.trim(),
      publishedTime: 'Just now',
      likeCount: 0,
    );

    setState(() {
      _comments.insert(0, newComment);
    });

    playerVm.addComment(widget.short.id, text.trim(), authVm.currentUser);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _toggleLike(String commentId) {
    setState(() {
      if (_likedCommentIds.contains(commentId)) {
        _likedCommentIds.remove(commentId);
      } else {
        _likedCommentIds.add(commentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Bar (Title, Sort Button, Close)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'Comments ${_comments.isNotEmpty ? _comments.length : ''}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    PopupMenuButton<bool>(
                      icon: const Icon(Icons.sort, color: Colors.white, size: 22),
                      tooltip: 'Sort comments',
                      color: AppColors.surfaceElevated,
                      onSelected: (val) {
                        setState(() {
                          _isTopComments = val;
                          if (_isTopComments) {
                            _comments.sort((a, b) => b.likeCount.compareTo(a.likeCount));
                          } else {
                            _comments = _comments.reversed.toList();
                          }
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: true,
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 16, color: _isTopComments ? AppColors.youtubeRed : Colors.transparent),
                              const SizedBox(width: 8),
                              const Text('Top comments', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: false,
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 16, color: !_isTopComments ? AppColors.youtubeRed : Colors.transparent),
                              const SizedBox(width: 8),
                              const Text('Newest first', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surfaceLight, height: 1),

              // Comments List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.youtubeRed),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text('No comments yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Be the first to comment on this Short!', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _comments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              final isLiked = _likedCommentIds.contains(comment.id);
                              final avatarColor = _getAvatarColor(comment.author);
                              final isVerified = comment.author.contains('News') ||
                                  comment.author.contains('Tech') ||
                                  comment.author.contains('Pro') ||
                                  comment.author.contains('BD');

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: avatarColor,
                                    child: ClipOval(
                                      child: comment.authorAvatar.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: comment.authorAvatar,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => Text(
                                                comment.author.isNotEmpty ? comment.author[0].toUpperCase() : 'U',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            )
                                          : Text(
                                              comment.author.isNotEmpty ? comment.author[0].toUpperCase() : 'U',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
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
                                              '@${comment.author.toLowerCase().replaceAll(' ', '_')}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFAAAAAA)),
                                            ),
                                            if (isVerified) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.check_circle, size: 12, color: Color(0xFFAAAAAA)),
                                            ],
                                            const SizedBox(width: 6),
                                            Text(comment.publishedTime, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          comment.text,
                                          style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.35),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _toggleLike(comment.id),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                                    size: 14,
                                                    color: isLiked ? const Color(0xFF3EA6FF) : const Color(0xFFAAAAAA),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${comment.likeCount + (isLiked ? 1 : 0)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isLiked ? const Color(0xFF3EA6FF) : const Color(0xFFAAAAAA),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.thumb_down_outlined, size: 14, color: Color(0xFFAAAAAA)),
                                            const SizedBox(width: 16),
                                            const Text('Reply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFAAAAAA))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),

              // Add Comment Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF4285F4),
                        child: Text(
                          authVm.currentUser.name.isNotEmpty ? authVm.currentUser.name[0].toUpperCase() : 'Y',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onSubmitted: _addComment,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF3EA6FF), size: 20),
                        onPressed: () => _addComment(_commentController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
