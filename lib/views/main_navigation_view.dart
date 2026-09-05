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
import 'settings/settings_view.dart';
import 'shared/custom_app_bar.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        final mainContent = Stack(
          children: [
            IndexedStack(index: _currentIndex, children: pages),

            // Floating Mini Player Bar
            if (playerVm.isMiniPlayerVisible &&
                playerVm.currentVideo != null &&
                (!enableShorts || _currentIndex != 1))
              Positioned(
                left: 16,
                right: isDesktop ? 24 : 16,
                bottom: isDesktop ? 16 : 8,
                child: _buildMiniPlayer(context, playerVm),
              ),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            // Full-width YouTube Top App Bar across the entire screen
            appBar: const CustomAppBar(),
            body: Row(
              children: [
                // YouTube Desktop Left Navigation Sidebar (sits directly underneath the top bar)
                Container(
                  width: 220,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      right: BorderSide(color: AppColors.surfaceLight, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Sidebar Navigation Items (YouTube Web styling)
                      _buildSidebarItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_filled,
                        label: 'Home',
                        isSelected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      if (enableShorts)
                        _buildSidebarItem(
                          icon: Icons.bolt_outlined,
                          activeIcon: Icons.bolt,
                          label: 'Shorts',
                          isSelected: _currentIndex == 1,
                          onTap: () {
                            context.read<PlayerViewModel>().pauseVideo();
                            setState(() => _currentIndex = 1);
                          },
                        ),
                      _buildSidebarItem(
                        icon: Icons.subscriptions_outlined,
                        activeIcon: Icons.subscriptions,
                        label: 'Subscriptions',
                        isSelected: _currentIndex == (enableShorts ? 2 : 1),
                        onTap: () => setState(() => _currentIndex = enableShorts ? 2 : 1),
                      ),
                      _buildSidebarItem(
                        icon: Icons.video_library_outlined,
                        activeIcon: Icons.video_library,
                        label: 'You',
                        isSelected: _currentIndex == (enableShorts ? 3 : 2),
                        onTap: () => setState(() => _currentIndex = enableShorts ? 3 : 2),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Divider(color: AppColors.surfaceLight, height: 1),
                      ),

                      _buildSidebarItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: 'Settings',
                        isSelected: false,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsView()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Main Content Area
                Expanded(child: mainContent),
              ],
            ),
          );
        }

        // Mobile Layout with Top App Bar and Bottom Navigation Bar
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: (enableShorts && _currentIndex == 1)
              ? null
              : (_currentIndex == (enableShorts ? 3 : 2)
                  ? null
                  : const CustomAppBar()),
          body: mainContent,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (_currentIndex != index) {
                if (index == 1 && enableShorts) {
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
      },
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
              size: 22,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
