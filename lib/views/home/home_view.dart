import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../shared/custom_app_bar.dart';
import '../shared/timer_status_bar.dart';
import 'widgets/category_chips_widget.dart';
import 'widgets/shorts_shelf_widget.dart';
import 'widgets/video_card_widget.dart';

/// Home Screen with animated Category Chips, conditional Shorts shelf, and filtered videos feed.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Screen Time Lock Status Banner (if active)
          const TimerStatusBar(),

          // Category Whitelist Chips
          const CategoryChipsWidget(),

          const Divider(color: AppColors.surfaceLight, height: 1),

          // Feed Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.youtubeRed,
              onRefresh: () => homeVm.loadFeed(isRefresh: true),
              child: _buildFeedBody(homeVm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBody(HomeViewModel homeVm) {
    // 1. Loading State
    if (homeVm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.youtubeRed),
      );
    }

    // 2. Error State
    if (homeVm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              homeVm.errorMessage!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => homeVm.loadFeed(isRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.youtubeRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // 3. Empty Feed / Filter Blocked Everything
    if (homeVm.videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.filter_list_off_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No Videos Match Your Active Filter',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Content outside your selected categories has been safely blocked. Adjust your category filters in Settings if needed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => homeVm.loadFeed(isRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Feed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Safe List Building with dynamic Shorts Shelf Insertion
    final hasShortsShelf = homeVm.showShortsShelf && homeVm.shorts.isNotEmpty;
    // Insert Shorts shelf after 2 videos if available, otherwise at the end
    final shelfIndex = homeVm.videos.length >= 2 ? 2 : homeVm.videos.length;
    final totalItemCount = homeVm.videos.length + (hasShortsShelf ? 1 : 0);

    return ListView.builder(
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (hasShortsShelf && index == shelfIndex) {
          return ShortsShelfWidget(shorts: homeVm.shorts);
        }

        final videoIndex = (hasShortsShelf && index > shelfIndex) ? index - 1 : index;
        if (videoIndex >= 0 && videoIndex < homeVm.videos.length) {
          return VideoCardWidget(video: homeVm.videos[videoIndex]);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
