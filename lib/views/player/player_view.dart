import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/pip_service.dart';
import '../../core/services/subscription_service.dart';
import '../../models/comment_model.dart';
import '../../models/video_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../notifications/notifications_view.dart';
import '../search/search_view.dart';
import '../shared/app_snackbar.dart';
import '../shared/cast_bottom_sheet.dart';
import '../shared/channel_avatar_widget.dart';
import '../shared/timer_status_bar.dart';

/// Fullscreen / In-depth Video Player Screen identical to official YouTube mobile.
class PlayerView extends StatefulWidget {
  final VideoModel video;

  const PlayerView({super.key, required this.video});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with WidgetsBindingObserver {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _positionUpdateTimer;
  bool _isControlsLocked = false;
  bool _isDescriptionExpanded = false;
  bool _isDisliked = false;
  bool _isInPip = false;
  bool _isFullScreen = false;
  final TextEditingController _commentInputController = TextEditingController();
  final TextEditingController _desktopCommentInputController = TextEditingController();
  final ScrollController _desktopScrollController = ScrollController();

  Function(bool)? _pipListener;

  // Ultra-smooth YouTube scrubber state
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;

  // Double-tap ±10s seek ripple animations
  int _seekRippleSide = 0; // -1: left, 1: right, 0: none
  int _doubleTapSeconds = 0;
  Timer? _seekRippleTimer;

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (!kIsWeb) {
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      final playerVm = context.read<PlayerViewModel>();
      final isPlaying = playerVm.videoController?.value.isPlaying ?? false;
      if (_showControls && isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final playerVm = context.read<PlayerViewModel>();
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
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.tune, color: Colors.white, size: 22),
                title: const Text('Quality', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(playerVm.selectedQuality, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 18),
                  ],
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showQualityPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white, size: 22),
                title: const Text('Playback speed', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${playerVm.playbackSpeed == 1.0 ? "1" : playerVm.playbackSpeed}x', style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 18),
                  ],
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSpeedPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.closed_caption_outlined, color: Colors.white, size: 22),
                title: const Text('Captions', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playerVm.showCaptions
                          ? (playerVm.subtitles.isNotEmpty ? 'Available' : 'On')
                          : 'Off',
                      style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 18),
                  ],
                ),
                onTap: () {
                  playerVm.toggleCaptions();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
                title: const Text('Lock screen', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  setState(() {
                    _isControlsLocked = !_isControlsLocked;
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                title: const Text('More', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 18),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedPicker(BuildContext context) {
    final playerVm = context.read<PlayerViewModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text('Playback speed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white12),
              ...speeds.map((s) => ListTile(
                dense: true,
                title: Text(s == 1.0 ? 'Normal' : '${s}x', style: const TextStyle(color: Colors.white)),
                trailing: playerVm.playbackSpeed == s ? const Icon(Icons.check, color: AppColors.youtubeRed) : null,
                onTap: () {
                  playerVm.setPlaybackSpeed(s);
                  Navigator.pop(ctx);
                },
              )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showQualityPicker(BuildContext context) {
    final playerVm = context.read<PlayerViewModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final qualities = ['Auto (720p)', '1080p60 HD', '720p60', '480p', '360p', '240p'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text('Quality for current video', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white12),
              ...qualities.map((q) => ListTile(
                dense: true,
                title: Text(q, style: const TextStyle(color: Colors.white)),
                trailing: playerVm.selectedQuality == q ? const Icon(Icons.check, color: AppColors.youtubeRed) : null,
                onTap: () {
                  playerVm.setQuality(q);
                  Navigator.pop(ctx);
                },
              )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Smooth periodic UI refresh for progress indicator and real subtitles
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) {
        final playerVm = context.read<PlayerViewModel>();
        if (playerVm.videoController?.value.isPlaying ?? false) {
          setState(() {});
        }
      }
    });

    // Ensure player viewmodel initializes video state and loads comments/subtitles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final playerVm = context.read<PlayerViewModel>();
        if (playerVm.currentVideo?.id != widget.video.id ||
            playerVm.videoController == null ||
            !playerVm.videoController!.value.isInitialized) {
          playerVm.playVideo(widget.video);
        }
      }
    });

    // Register local PiP mode listener for this view
    PipService.instance.init();
    _pipListener = (inPip) {
      if (!mounted) return;
      setState(() {
        _isInPip = inPip;
      });
    };
    PipService.instance.addPipModeListener(_pipListener!);
  }

  void _playNextVideo() {
    if (!mounted) return;
    final playerVm = context.read<PlayerViewModel>();
    final success = playerVm.playNextVideo();
    if (!success) {
      AppSnackBar.showInfo(
        context,
        'No next video in playlist',
        icon: Icons.skip_next_rounded,
      );
    }
  }

  void _playPrevOrRestart() {
    if (!mounted) return;
    context.read<PlayerViewModel>().seekTo(Duration.zero);
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _positionUpdateTimer?.cancel();
    _seekRippleTimer?.cancel();
    if (_pipListener != null) {
      PipService.instance.removePipModeListener(_pipListener!);
    }
    // NOTE: We deliberately do NOT dispose playerVm.videoController here!
    // This allows the video and audio to continue playing seamlessly in the Mini-Player!
    _commentInputController.dispose();
    _desktopCommentInputController.dispose();
    _desktopScrollController.dispose();
    if (!kIsWeb && _isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    final playerVm = context.read<PlayerViewModel>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      playerVm.handleAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      playerVm.handleAppForegrounded();
    }
  }

  void _handleScrubUpdate(double dx, double width, Duration totalDuration) {
    if (totalDuration <= Duration.zero || width <= 0) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    final targetPos = Duration(milliseconds: (totalDuration.inMilliseconds * ratio).round());
    setState(() {
      _isScrubbing = true;
      _scrubPosition = targetPos;
      _showControls = true;
    });
    _hideControlsTimer?.cancel();
    context.read<PlayerViewModel>().seekTo(targetPos);
  }

  void _handleScrubEnd() {
    final playerVm = context.read<PlayerViewModel>();
    playerVm.seekTo(_scrubPosition);
    setState(() {
      _isScrubbing = false;
    });
    _startHideControlsTimer();
  }

  void _onDoubleTapSeek(bool isForward, Duration currentPos, Duration duration) {
    if (duration <= Duration.zero) return;
    HapticFeedback.lightImpact();
    final delta = isForward ? const Duration(seconds: 10) : const Duration(seconds: -10);
    final newMs = (currentPos + delta).inMilliseconds.clamp(0, duration.inMilliseconds);
    final target = Duration(milliseconds: newMs);
    context.read<PlayerViewModel>().seekTo(target);

    setState(() {
      _seekRippleSide = isForward ? 1 : -1;
      _doubleTapSeconds = (_seekRippleSide == (isForward ? 1 : -1) ? _doubleTapSeconds : 0) + 10;
      _showControls = true;
    });

    _seekRippleTimer?.cancel();
    _seekRippleTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _seekRippleSide = 0;
          _doubleTapSeconds = 0;
        });
        _startHideControlsTimer();
      }
    });
  }

  Widget _buildSeekRipple(bool isRight) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isRight ? null : 0,
      right: isRight ? 0 : null,
      width: MediaQuery.of(context).size.width * 0.42,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.horizontal(
            left: isRight ? const Radius.circular(120) : Radius.zero,
            right: isRight ? Radius.zero : const Radius.circular(120),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRight ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                color: Colors.white,
                size: 38,
              ),
              const SizedBox(height: 4),
              Text(
                '${_doubleTapSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrubberBar(VideoPlayerController vc, Duration position, Duration duration, {required bool isInteractive}) {
    final effectivePos = _isScrubbing ? _scrubPosition : position;
    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final playedRatio = (effectivePos.inMilliseconds / totalMs).clamp(0.0, 1.0);

    // Buffered range
    double bufferedRatio = 0.0;
    if (vc.value.buffered.isNotEmpty) {
      final maxBuf = vc.value.buffered.map((r) => r.end.inMilliseconds).fold<int>(0, (max, v) => v > max ? v : max);
      bufferedRatio = (maxBuf / totalMs).clamp(0.0, 1.0);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbX = (width * playedRatio).clamp(0.0, width);

        final bar = SizedBox(
          height: isInteractive ? 36 : 3,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // Background track
              Positioned(
                left: 0,
                right: 0,
                child: Container(
                  height: (_isScrubbing || isInteractive) ? 3.5 : 2.0,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Buffered track
              Positioned(
                left: 0,
                width: width * bufferedRatio,
                child: Container(
                  height: (_isScrubbing || isInteractive) ? 3.5 : 2.0,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Played progress track (YouTube Red)
              Positioned(
                left: 0,
                width: width * playedRatio,
                child: Container(
                  height: (_isScrubbing || isInteractive) ? 3.5 : 2.0,
                  decoration: BoxDecoration(
                    color: AppColors.youtubeRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // YouTube Red Scrubber Thumb (Dot)
              if (isInteractive || _isScrubbing)
                Positioned(
                  left: (thumbX - (_isScrubbing ? 8.0 : 6.0)).clamp(0.0, width - (_isScrubbing ? 16.0 : 12.0)),
                  child: Container(
                    width: _isScrubbing ? 16 : 12,
                    height: _isScrubbing ? 16 : 12,
                    decoration: BoxDecoration(
                      color: AppColors.youtubeRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

        if (!isInteractive) return bar;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            HapticFeedback.selectionClick();
            _handleScrubUpdate(details.localPosition.dx, width, duration);
          },
          onTapUp: (_) {
            _handleScrubEnd();
          },
          onHorizontalDragStart: (details) {
            HapticFeedback.selectionClick();
            _handleScrubUpdate(details.localPosition.dx, width, duration);
          },
          onHorizontalDragUpdate: (details) {
            _handleScrubUpdate(details.localPosition.dx, width, duration);
          },
          onHorizontalDragEnd: (_) {
            _handleScrubEnd();
          },
          onHorizontalDragCancel: () {
            _handleScrubEnd();
          },
          child: bar,
        );
      },
    );
  }

  Widget _buildVideoPlayerSurface(PlayerViewModel playerVm, VideoModel currentVideo) {
    final vc = playerVm.videoController;
    if (playerVm.isNativeVideoReady && vc != null && vc.value.isInitialized) {
      final isPlaying = vc.value.isPlaying;
      final position = vc.value.position;
      final duration = vc.value.duration;

      return Stack(
        alignment: Alignment.center,
        children: [
          // 1. Native Video Player
          Center(
            child: AspectRatio(
              aspectRatio: vc.value.aspectRatio > 0 ? vc.value.aspectRatio : 16 / 9,
              child: VideoPlayer(vc),
            ),
          ),

          // 2. Gesture Detector for Single Tap (Toggle controls) & Double Tap (Seek -10s / +10s)
          Positioned.fill(
            child: Row(
              children: [
                // Left 40% (Seek -10s on double tap, Toggle controls on single tap)
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_isControlsLocked) {
                        setState(() {
                          _isControlsLocked = false;
                          _showControls = true;
                        });
                        _startHideControlsTimer();
                        return;
                      }
                      setState(() {
                        _showControls = !_showControls;
                      });
                      if (_showControls) _startHideControlsTimer();
                    },
                    onDoubleTap: () {
                      if (!_isControlsLocked && !currentVideo.isLive) {
                        _onDoubleTapSeek(false, position, duration);
                      }
                    },
                  ),
                ),

                // Center 20% (Toggle controls on tap)
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_isControlsLocked) {
                        setState(() {
                          _isControlsLocked = false;
                          _showControls = true;
                        });
                        _startHideControlsTimer();
                        return;
                      }
                      setState(() {
                        _showControls = !_showControls;
                      });
                      if (_showControls) _startHideControlsTimer();
                    },
                  ),
                ),

                // Right 40% (Seek +10s on double tap, Toggle controls on single tap)
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_isControlsLocked) {
                        setState(() {
                          _isControlsLocked = false;
                          _showControls = true;
                        });
                        _startHideControlsTimer();
                        return;
                      }
                      setState(() {
                        _showControls = !_showControls;
                      });
                      if (_showControls) _startHideControlsTimer();
                    },
                    onDoubleTap: () {
                      if (!_isControlsLocked && !currentVideo.isLive) {
                        _onDoubleTapSeek(true, position, duration);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. Double-tap Seek Animated Ripples
          if (_seekRippleSide == -1) _buildSeekRipple(false),
          if (_seekRippleSide == 1) _buildSeekRipple(true),

          // 4. YouTube Mobile Controls Overlay
          if (_showControls && !_isInPip) ...[
            // Dark gradient background scrim
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),

            // Top row: Collapse arrow, Autoplay toggle pill, Cast, CC, Settings
            Positioned(
              top: 6,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 26,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (_isFullScreen) {
                        _toggleFullScreen();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Autoplay switch pill
                          GestureDetector(
                            onTap: () {
                              playerVm.toggleAutoplay();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: playerVm.isAutoplayEnabled ? Colors.white : Colors.black54,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, size: 13, color: playerVm.isAutoplayEnabled ? Colors.black : Colors.white70),
                                  const SizedBox(width: 3),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: playerVm.isAutoplayEnabled ? AppColors.youtubeRed : Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedBuilder(
                            animation: CastService.instance,
                            builder: (context, _) {
                              final isConnected = CastService.instance.isConnected;
                              return IconButton(
                                icon: Icon(
                                  isConnected ? Icons.cast_connected_rounded : Icons.cast,
                                  color: isConnected ? const Color(0xFF4285F4) : Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => CastBottomSheet.show(context),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          // Captions toggle button
                          GestureDetector(
                            onTap: () {
                              playerVm.toggleCaptions();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: playerVm.showCaptions ? Colors.white : Colors.white60, width: 1.2),
                                borderRadius: BorderRadius.circular(3),
                                color: playerVm.showCaptions ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                              ),
                              child: Text(
                                'CC',
                                style: TextStyle(
                                  color: playerVm.showCaptions ? Colors.white : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showSettingsBottomSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Controls: Previous / Replay, Pause/Play, Play Next Video
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
                      tooltip: 'Replay',
                      onPressed: () {
                        _playPrevOrRestart();
                      },
                    ),
                  ),
                  const SizedBox(width: 32),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      iconSize: 36,
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        playerVm.togglePlayPause();
                        _startHideControlsTimer();
                      },
                    ),
                  ),
                  const SizedBox(width: 32),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
                      tooltip: 'Next video',
                      onPressed: () {
                        _playNextVideo();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Bar: Time Pill (Left) & Fullscreen Button (Right)
            Positioned(
              left: 12,
              right: 12,
              bottom: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentVideo.isLive
                          ? '🔴 LIVE'
                          : '${_formatDuration(_isScrubbing ? _scrubPosition : position)} / ${_formatDuration(duration)}',
                      style: TextStyle(
                        color: currentVideo.isLive ? AppColors.youtubeRed : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
            ),

            // Bottom Interactive Scrubber Bar with Red Dot (height 36 touch target)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildScrubberBar(vc, position, duration, isInteractive: true),
            ),
          ] else if (!_isInPip) ...[
            // When controls are hidden, keep sleek thin red line at bottom edge
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildScrubberBar(vc, position, duration, isInteractive: false),
            ),
          ],

          // Real YouTube Subtitles Bar overlay on video
          if (playerVm.showCaptions) ...[
            Builder(
              builder: (context) {
                final captionText = playerVm.getCaptionForPosition(_isScrubbing ? _scrubPosition : position);
                if (captionText.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  bottom: _showControls ? 52 : 14,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      captionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      );
    }

    // Loading / Buffer indicator with thumbnail
    if (playerVm.isLoadingStream) {
      return Stack(
        fit: StackFit.expand,
        children: [
          kIsWeb
              ? Image.network(
                  currentVideo.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, url, error) => Container(color: Colors.black),
                )
              : CachedNetworkImage(
                  imageUrl: currentVideo.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: Colors.black),
                ),
          Container(color: Colors.black54),
          const Center(
            child: CircularProgressIndicator(color: AppColors.youtubeRed),
          ),
        ],
      );
    }

    // Graceful fallback to Iframe if direct stream was unavailable (or on Web)
    final iframe = playerVm.iframeController;
    if (iframe != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          YoutubePlayer(
            key: ValueKey(currentVideo.id),
            controller: iframe,
            aspectRatio: 16 / 9,
          ),
          if (!kIsWeb)
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
        ],
      );
    }

    // Elegant Error / Retry Fallback Screen (Prevents any black/blue screen deadlock)
    return Stack(
      fit: StackFit.expand,
      children: [
        kIsWeb
            ? Image.network(
                currentVideo.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, url, error) => Container(color: Colors.black),
              )
            : CachedNetworkImage(
                imageUrl: currentVideo.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: Colors.black),
              ),
        Container(color: Colors.black87),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_disabled_rounded, color: Colors.white70, size: 40),
              const SizedBox(height: 10),
              const Text(
                'Stream buffering or temporarily busy',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  playerVm.playVideo(currentVideo);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Playing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.youtubeRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final playerVm = context.watch<PlayerViewModel>();

    // If app is locked by timer or schedule, pop out of PlayerView immediately
    if (settingsVm.timerService.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
      return const SizedBox.shrink();
    }

    final currentVideo = playerVm.currentVideo ?? widget.video;

    // If in native Picture-in-Picture mode, render ONLY the full-bleed video player
    if (_isInPip) {
      final vc = playerVm.videoController;
      final iframe = playerVm.iframeController;
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: playerVm.isNativeVideoReady && vc != null
                ? VideoPlayer(vc)
                : (iframe != null
                    ? YoutubePlayer(controller: iframe, aspectRatio: 16 / 9)
                    : const Center(child: CircularProgressIndicator(color: AppColors.youtubeRed))),
          ),
        ),
      );
    }

    final authVm = context.watch<AuthViewModel>();
    final isLiked = playerVm.isLiked(currentVideo.id);
    final displayLikeCount = playerVm.getDisplayLikeCount(currentVideo);

    if (_isFullScreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _toggleFullScreen();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: _buildVideoPlayerSurface(playerVm, currentVideo),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (_isFullScreen) {
          _toggleFullScreen();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktopWatchLayout(
              context,
              playerVm,
              currentVideo,
              authVm,
              isLiked,
              displayLikeCount,
            );
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              bottom: false,
              child: _buildMobileWatchLayout(
                context,
                constraints,
                playerVm,
                currentVideo,
                authVm,
                isLiked,
                displayLikeCount,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Authentic YouTube Web Desktop 2-Column Watch Page
  Widget _buildDesktopWatchLayout(
    BuildContext context,
    PlayerViewModel playerVm,
    VideoModel currentVideo,
    AuthViewModel authVm,
    bool isLiked,
    String displayLikeCount,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Feed',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset('assets/icons/app_icon.png', width: 26, height: 26),
            const SizedBox(width: 8),
            const Text(
              'TubeTune',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        actions: [
          // Cast icon
          AnimatedBuilder(
            animation: CastService.instance,
            builder: (context, _) {
              final isConnected = CastService.instance.isConnected;
              return IconButton(
                icon: Icon(
                  isConnected ? Icons.cast_connected_rounded : Icons.cast_outlined,
                  color: isConnected ? const Color(0xFF4285F4) : Colors.white,
                  size: 20,
                ),
                tooltip: 'Connect to a device',
                onPressed: () => CastBottomSheet.show(context),
              );
            },
          ),
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 21),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsView()));
            },
          ),
          // Search
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Colors.white, size: 22),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchView()));
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        controller: _desktopScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (Primary: Video Player, Title, Channel, Actions, Description, Full Comments)
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Player Surface (16:9) with rounded corners
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildVideoPlayerSurface(playerVm, currentVideo),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Video Title
                      Text(
                        currentVideo.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Channel Row & Actions Bar
                      Row(
                        children: [
                          // Channel Avatar
                          ChannelAvatarWidget(
                            author: currentVideo.author,
                            avatarUrl: currentVideo.channelAvatarUrl,
                            channelId: currentVideo.channelId,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          // Channel Name & Subscribers
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentVideo.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '3.85M subscribers',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                                ),
                              ],
                            ),
                          ),
                          // YouTube Subscribe Button
                          Consumer<SubscriptionService>(
                            builder: (context, subService, _) {
                              final isSubscribed = subService.isSubscribed(currentVideo.author);
                              return ElevatedButton(
                                onPressed: () async {
                                  final nowSubscribed = await subService.toggleSubscriptionFromVideo(currentVideo);
                                  if (context.mounted) {
                                    if (nowSubscribed) {
                                      AppSnackBar.showSuccess(
                                        context,
                                        'Subscribed to ${currentVideo.author}',
                                        icon: Icons.subscriptions_rounded,
                                      );
                                    } else {
                                      AppSnackBar.showInfo(
                                        context,
                                        'Subscription removed',
                                        icon: Icons.notifications_off_outlined,
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSubscribed ? AppColors.surfaceElevated : Colors.white,
                                  foregroundColor: isSubscribed ? Colors.white : Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: Text(
                                  isSubscribed ? 'Subscribed' : 'Subscribe',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),

                          // Actions Row (Like/Dislike, Share, Remix, Download, Save)
                          _buildDesktopActionPills(context, playerVm, currentVideo, isLiked, displayLikeCount),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Expandable Description Box
                      _buildDesktopDescriptionBox(currentVideo),
                      const SizedBox(height: 24),

                      // Desktop Inline Comments Section
                      _buildDesktopInlineComments(context, playerVm, authVm, currentVideo),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Sidebar Column ("Up Next" / Related Videos Queue)
                SizedBox(
                  width: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Up Next',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            '${playerVm.relatedVideos.length} safe videos',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...playerVm.relatedVideos.map((v) => _buildDesktopRelatedVideoCard(v, playerVm)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact YouTube Desktop Related Video Card
  Widget _buildDesktopRelatedVideoCard(VideoModel video, PlayerViewModel playerVm) {
    return InkWell(
      onTap: () {
        playerVm.playVideo(video);
        _desktopScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (168 x 94) with duration badge
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 168,
                height: 94,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url, error) => Container(
                              color: AppColors.surfaceElevated,
                              child: const Icon(Icons.play_circle_outline, size: 36, color: AppColors.textMuted),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.surfaceElevated),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceElevated,
                              child: const Icon(Icons.play_circle_outline, size: 36, color: AppColors.textMuted),
                            ),
                          ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: video.isLive ? AppColors.youtubeRed : Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.isLive ? 'LIVE' : video.durationFormatted,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Metadata Info: Title, Author, Views & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.isLive
                        ? '🔴 ${video.viewCountFormatted} watching'
                        : '${video.viewCountFormatted} • ${video.uploadDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Desktop Expandable Description Box
  Widget _buildDesktopDescriptionBox(VideoModel currentVideo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                currentVideo.viewCountFormatted,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                currentVideo.uploadDate,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentVideo.description.isNotEmpty
                ? currentVideo.description
                : 'No description provided for this video.',
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFFDDDDDD), height: 1.4),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Show less' : '...more',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop Inline Comments Section with Add Comment input & Interactive comments list
  Widget _buildDesktopInlineComments(
    BuildContext context,
    PlayerViewModel playerVm,
    AuthViewModel authVm,
    VideoModel currentVideo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment Count & Sort Row
        Row(
          children: [
            Text(
              '${playerVm.comments.length} Comments',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 24),
            PopupMenuButton<CommentSortOrder>(
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
                        color: playerVm.commentSortOrder == CommentSortOrder.top ? Colors.white : Colors.transparent,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Top comments',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: playerVm.commentSortOrder == CommentSortOrder.top ? FontWeight.bold : FontWeight.normal,
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
                        color: playerVm.commentSortOrder == CommentSortOrder.newest ? Colors.white : Colors.transparent,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Newest first',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: playerVm.commentSortOrder == CommentSortOrder.newest ? FontWeight.bold : FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.sort, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text('Sort by', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Add Comment Box (YouTube Desktop inline)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF4285F4),
              child: Text(
                authVm.currentUser.name.isNotEmpty ? authVm.currentUser.name[0] : 'Y',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _desktopCommentInputController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF717171)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        playerVm.addComment(currentVideo.id, val, authVm.currentUser);
                        _desktopCommentInputController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _desktopCommentInputController.text;
                      if (text.trim().isNotEmpty) {
                        playerVm.addComment(currentVideo.id, text, authVm.currentUser);
                        _desktopCommentInputController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3EA6FF),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Comment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // List of comments
        if (playerVm.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              ),
            ),
          )
        else
          ...playerVm.comments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildCommentTile(c, playerVm),
              )),
      ],
    );
  }

  /// Action Pills Row for Desktop
  Widget _buildDesktopActionPills(
    BuildContext context,
    PlayerViewModel playerVm,
    VideoModel currentVideo,
    bool isLiked,
    String displayLikeCount,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like / Dislike Pill
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
                  playerVm.toggleLike(currentVideo.id);
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
              Container(width: 1, height: 18, color: AppColors.surfaceLight),
              InkWell(
                onTap: () {
                  setState(() => _isDisliked = !_isDisliked);
                  if (_isDisliked && isLiked) playerVm.toggleLike(currentVideo.id);
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

        _buildActionPill(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () => _showShareBottomSheet(context),
        ),
        const SizedBox(width: 8),

        _buildActionPill(
          icon: Icons.cut_outlined,
          label: 'Remix',
          onTap: () => _showRemixBottomSheet(context),
        ),
        const SizedBox(width: 8),

        _buildActionPill(
          icon: playerVm.isWatchLater(currentVideo.id) ? Icons.bookmark : Icons.bookmark_border,
          label: playerVm.isWatchLater(currentVideo.id) ? 'Saved' : 'Save',
          onTap: () => playerVm.toggleWatchLater(currentVideo),
        ),
      ],
    );
  }

  /// Mobile Single-Column Watch Layout
  Widget _buildMobileWatchLayout(
    BuildContext context,
    BoxConstraints constraints,
    PlayerViewModel playerVm,
    VideoModel currentVideo,
    AuthViewModel authVm,
    bool isLiked,
    String displayLikeCount,
  ) {
    final playerHeight = constraints.maxWidth * 9 / 16;

    return Column(
      children: [
        const TimerStatusBar(),

        // Top Video Player Container (16:9)
        SizedBox(
          width: constraints.maxWidth,
          height: playerHeight,
          child: _buildVideoPlayerSurface(playerVm, currentVideo),
        ),

        // Scrollable Video Details & Feed (Always expanded and scrollable)
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Video Title
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Text(
                  currentVideo.title,
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
                            currentVideo.viewCountFormatted,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentVideo.uploadDate,
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
                      if (_isDescriptionExpanded && currentVideo.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentVideo.description,
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
                    ChannelAvatarWidget(
                      author: currentVideo.author,
                      avatarUrl: currentVideo.channelAvatarUrl,
                      channelId: currentVideo.channelId,
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentVideo.author,
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
                    Consumer<SubscriptionService>(
                      builder: (context, subService, _) {
                        final isSubscribed = subService.isSubscribed(currentVideo.author);
                        return ElevatedButton(
                          onPressed: () async {
                            final nowSubscribed = await subService.toggleSubscriptionFromVideo(currentVideo);
                            if (context.mounted) {
                              if (nowSubscribed) {
                                AppSnackBar.showSuccess(
                                  context,
                                  'Subscribed to ${currentVideo.author}',
                                  icon: Icons.subscriptions_rounded,
                                );
                              } else {
                                AppSnackBar.showInfo(
                                  context,
                                  'Subscription removed',
                                  icon: Icons.notifications_off_outlined,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubscribed ? AppColors.surfaceElevated : Colors.white,
                            foregroundColor: isSubscribed ? Colors.white : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSubscribed) ...[
                                const Icon(Icons.notifications_active, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                isSubscribed ? 'Subscribed' : 'Subscribe',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Actions Bar (Unified Like/Dislike, Share, Remix, Download, Save)
              _buildMobileActionsBar(context, playerVm, currentVideo, isLiked, displayLikeCount),

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
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile Actions Bar
  Widget _buildMobileActionsBar(
    BuildContext context,
    PlayerViewModel playerVm,
    VideoModel currentVideo,
    bool isLiked,
    String displayLikeCount,
  ) {
    return SingleChildScrollView(
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
                    playerVm.toggleLike(currentVideo.id);
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
                      playerVm.toggleLike(currentVideo.id);
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

          // Download Button (Real Offline Download)
          AnimatedBuilder(
            animation: DownloadService.instance,
            builder: (context, _) {
              final isDownloaded = DownloadService.instance.isDownloaded(currentVideo.id);
              final isDownloading = DownloadService.instance.isDownloading(currentVideo.id);
              final progress = (DownloadService.instance.getProgress(currentVideo.id) * 100).toInt();

              String label = 'Download';
              IconData icon = Icons.download_outlined;
              if (isDownloaded) {
                label = 'Downloaded';
                icon = Icons.download_done_rounded;
              } else if (isDownloading) {
                label = '$progress%';
                icon = Icons.downloading_rounded;
              }

              return _buildActionPill(
                icon: icon,
                label: label,
                onTap: () async {
                  if (kIsWeb) {
                    AppSnackBar.showInfo(
                      context,
                      'Offline video downloads are available on mobile app',
                      icon: Icons.smartphone_rounded,
                    );
                    return;
                  }
                  if (isDownloaded) {
                    AppSnackBar.showInfo(
                      context,
                      'This video is downloaded for offline playback',
                      icon: Icons.check_circle_rounded,
                    );
                    return;
                  }
                  if (isDownloading) {
                    AppSnackBar.showInfo(
                      context,
                      'Downloading in progress ($progress%)...',
                      icon: Icons.downloading_rounded,
                    );
                    return;
                  }

                  AppSnackBar.showInfo(
                    context,
                    'Downloading "${currentVideo.title}" for offline mode...',
                    icon: Icons.download_rounded,
                  );

                  final success = await DownloadService.instance.downloadVideo(currentVideo);
                  if (context.mounted) {
                    if (success) {
                      AppSnackBar.showSuccess(
                        context,
                        'Download complete! Ready for offline viewing in Library.',
                        icon: Icons.download_done_rounded,
                      );
                    } else {
                      AppSnackBar.showError(
                        context,
                        'Failed to download video. Please check your connection.',
                      );
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),

          // Save to Watch Later
          _buildActionPill(
            icon: playerVm.isWatchLater(currentVideo.id) ? Icons.bookmark : Icons.bookmark_border,
            label: playerVm.isWatchLater(currentVideo.id) ? 'Saved' : 'Save',
            onTap: () => playerVm.toggleWatchLater(currentVideo),
          ),
        ],
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
          child: ClipOval(
            child: c.authorAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: c.authorAvatar,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Text(
                      c.author.isNotEmpty ? c.author[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                : Text(
                    c.author.isNotEmpty ? c.author[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.video.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.black),
                                errorWidget: (context, url, error) => Container(color: Colors.black),
                              ),
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
    AppSnackBar.showInfo(context, message);
  }
}
