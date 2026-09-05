import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../shared/custom_app_bar.dart';
import '../shared/timer_status_bar.dart';
import 'widgets/breaking_news_shelf_widget.dart';
import 'widgets/category_chips_widget.dart';
import 'widgets/shorts_shelf_widget.dart';
import 'widgets/suggested_shelf_widget.dart';
import 'widgets/video_card_widget.dart';

/// Home Screen with animated Category Chips, conditional Live Broadcasts shelf, Shorts shelf, and infinite scrolling feed.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      context.read<HomeViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < 80) {
            return const SizedBox.shrink();
          }
          return Column(
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
          );
        },
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
    if (homeVm.videos.isEmpty && homeVm.liveStreams.isEmpty) {
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

    // 4. Authentic YouTube Segmented Feed with Infinite Scrolling & Personalized Suggestions
    final List<Widget> feedItems = [];

    // Live Streams / Breaking News Shelf
    if (homeVm.liveStreams.isNotEmpty) {
      feedItems.add(BreakingNewsShelfWidget(liveStreams: homeVm.liveStreams));
    }

    // First batch of regular feed videos
    final initialCount = homeVm.videos.length >= 2 ? 2 : homeVm.videos.length;
    for (int i = 0; i < initialCount; i++) {
      feedItems.add(VideoCardWidget(video: homeVm.videos[i]));
    }

    // YouTube-style Personalized Suggested Videos Shelf
    if (homeVm.suggestedVideos.isNotEmpty) {
      feedItems.add(SuggestedShelfWidget(suggestedVideos: homeVm.suggestedVideos));
    }

    // Second batch of regular videos
    final secondBatchEnd = homeVm.videos.length >= 5 ? 5 : homeVm.videos.length;
    for (int i = initialCount; i < secondBatchEnd; i++) {
      feedItems.add(VideoCardWidget(video: homeVm.videos[i]));
    }

    // Shorts Shelf
    if (homeVm.showShortsShelf && homeVm.shorts.isNotEmpty) {
      feedItems.add(ShortsShelfWidget(shorts: homeVm.shorts));
    }

    // Remaining regular feed videos
    for (int i = secondBatchEnd; i < homeVm.videos.length; i++) {
      feedItems.add(VideoCardWidget(video: homeVm.videos[i]));
    }

    // Bottom Infinite Scroll Spinner
    if (homeVm.isLoadingMore) {
      feedItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.youtubeRed,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: feedItems.length,
      itemBuilder: (context, index) => feedItems[index],
    );
  }
}
