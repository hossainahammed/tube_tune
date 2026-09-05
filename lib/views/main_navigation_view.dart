import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';
import '../core/services/background_audio_service.dart';
import '../viewmodels/player_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'home/home_view.dart';
import 'library/library_view.dart';
import 'lock/lock_screen_view.dart';
import 'player/player_view.dart';
import 'shorts/shorts_view.dart';
import 'subscriptions/subscriptions_view.dart';

import '../core/services/pip_service.dart';

/// Master Shell Navigation Screen with official YouTube 4-tab bar (Home, Shorts, Subscriptions, You).
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isInPip = false;
  Function(bool)? _pipListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackgroundAudioService.instance.init();
    PipService.instance.init();
    _pipListener = (inPip) {
      if (!mounted) return;
      setState(() {
        _isInPip = inPip;
      });
    };
    PipService.instance.addPipModeListener(_pipListener!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_pipListener != null) {
      PipService.instance.removePipModeListener(_pipListener!);
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

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final playerVm = context.watch<PlayerViewModel>();
    final isLocked = settingsVm.timerService.isLocked;

    // 1. If App is Locked by Auto-Lock Timer -> Show Lock Screen
    if (isLocked) {
      return const LockScreenView();
    }

    // 2. If in native Picture-in-Picture mode -> Render ONLY clean 16:9 full-bleed video (zero UI overflow)
    if (_isInPip) {
      final video = playerVm.currentVideo;
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: video != null
                ? CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.black),
                  )
                : Container(color: Colors.black),
          ),
        ),
      );
    }

    final enableShorts = settingsVm.enableShorts;
    final isShortsActive = enableShorts && _currentIndex == 1;

    // Construct tabs identical to official YouTube mobile app
    final List<Widget> pages = [
      const HomeView(),
      if (enableShorts) ShortsView(isActive: isShortsActive),
      const SubscriptionsView(),
      const LibraryView(),
    ];

    // Adjust current index if shorts was turned off
    if (!enableShorts && _currentIndex == 1) {
      _currentIndex = 0;
    } else if (!enableShorts && _currentIndex > 1) {
      _currentIndex = (_currentIndex - 1).clamp(0, pages.length - 1);
    } else {
      _currentIndex = _currentIndex.clamp(0, pages.length - 1);
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),

          // Floating Mini Player Bar (identical to YouTube mobile)
          if (playerVm.isMiniPlayerVisible &&
              playerVm.currentVideo != null &&
              (!enableShorts || _currentIndex != 1))
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _buildMiniPlayer(context, playerVm),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex != index) {
            // When switching to Shorts, pause main player to avoid dual audio
            if (index == 1) {
              context.read<PlayerViewModel>().pauseVideo();
            }
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFAAAAAA),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          if (enableShorts)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Shorts',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_outlined),
            activeIcon: Icon(Icons.subscriptions),
            label: 'Subscriptions',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'You',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, PlayerViewModel playerVm) {
    final video = playerVm.currentVideo!;

    return Material(
      color: Colors.transparent,
      elevation: 8,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => PlayerView(video: video)));
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 70,
                  height: 44,
                  child: (playerVm.videoController != null &&
                          playerVm.videoController!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: playerVm.videoController!.value.aspectRatio > 0
                              ? playerVm.videoController!.value.aspectRatio
                              : 16 / 9,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: playerVm.videoController!.value.size.width > 0
                                  ? playerVm.videoController!.value.size.width
                                  : 16,
                              height: playerVm.videoController!.value.size.height > 0
                                  ? playerVm.videoController!.value.size.height
                                  : 9,
                              child: VideoPlayer(playerVm.videoController!),
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          width: 70,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: Colors.black),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      video.author,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  playerVm.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => playerVm.togglePlayPause(),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFFAAAAAA),
                  size: 20,
                ),
                onPressed: () => playerVm.closeMiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
