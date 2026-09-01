import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/player_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'explore/explore_view.dart';
import 'home/home_view.dart';
import 'library/library_view.dart';
import 'lock/lock_screen_view.dart';
import 'player/player_view.dart';
import 'settings/settings_view.dart';
import 'shorts/shorts_view.dart';

/// Master Shell Navigation Screen with conditional Shorts tab, floating Mini-Player, and Auto-Lock Screen overlay.
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final playerVm = context.watch<PlayerViewModel>();
    final isLocked = settingsVm.timerService.isLocked;

    // 1. If App is Locked by Auto-Lock Timer -> Show Lock Screen
    if (isLocked) {
      return const LockScreenView();
    }

    final enableShorts = settingsVm.enableShorts;

    // Construct tabs based on Shorts toggle
    final List<Widget> pages = [
      const HomeView(),
      const ExploreView(),
      if (enableShorts) const ShortsView(),
      const LibraryView(),
      const SettingsView(),
    ];

    // Adjust current index if shorts was turned off
    if (!enableShorts && _currentIndex == 2) {
      _currentIndex = 1;
    } else if (!enableShorts && _currentIndex > 2) {
      _currentIndex = _currentIndex.clamp(0, pages.length - 1);
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex.clamp(0, pages.length - 1),
            children: pages,
          ),

          // Floating Mini Player Bar
          if (playerVm.isMiniPlayerVisible && playerVm.currentVideo != null && _currentIndex != 2)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _buildMiniPlayer(context, playerVm),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, pages.length - 1),
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          if (enableShorts)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Shorts',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Library',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            activeIcon: Icon(Icons.tune),
            label: 'Settings',
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerView(video: video)),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 58,
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
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  width: 70,
                  height: 46,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: Colors.black),
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
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      video.author,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => playerVm.closeMiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
