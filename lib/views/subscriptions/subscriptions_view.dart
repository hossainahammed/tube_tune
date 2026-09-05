import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/subscription_service.dart';
import '../../models/channel_model.dart';
import '../../models/video_model.dart';
import '../../viewmodels/subscriptions_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/app_snackbar.dart';
import '../shared/channel_avatar_widget.dart';
import '../shared/timer_status_bar.dart';

/// Subscriptions Screen identical to official YouTube mobile with channel avatar row,
/// unread badges, channel management, sub-filter chips, and real-time live video feed.
class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400) {
      context.read<SubscriptionsViewModel>().loadMore();
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
    final subVm = context.watch<SubscriptionsViewModel>();
    final channels = subVm.channels;
    final filteredVideos = subVm.filteredVideos;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TimerStatusBar(),

          // 1. Horizontal Subscribed Channels Stories Carousel
          _buildChannelsCarousel(context, subVm, channels),

          // 2. Selected Channel Header Banner (when a specific channel is selected)
          if (subVm.selectedChannel != null)
            _buildSelectedChannelBanner(context, subVm, subVm.selectedChannel!),

          // 3. Subscriptions Filter Chips Row
          _buildFilterChipsRow(subVm),

          // 4. Subscribed Videos Feed with Pull-to-Refresh & Infinite Scroll
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => subVm.loadSubscriptionsFeed(isRefresh: true),
              color: AppColors.youtubeRed,
              child: _buildFeedContent(subVm, filteredVideos),
            ),
          ),
        ],
      ),
    );
  }

  /// Top horizontal stories carousel with unread indicators and "All" channels launcher
  Widget _buildChannelsCarousel(
    BuildContext context,
    SubscriptionsViewModel subVm,
    List<ChannelModel> channels,
  ) {
    return Container(
      height: 98,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: channels.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          // "All" / Manage channels button at the start or end
          if (index == channels.length) {
            return InkWell(
              onTap: () => _showAllChannelsModal(context),
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceLight, width: 1),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final ch = channels[index];
          final isSelected = subVm.selectedChannel?.name == ch.name;

          return InkWell(
            onTap: () => subVm.selectChannel(ch),
            borderRadius: BorderRadius.circular(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.youtubeRed
                              : (ch.hasNewUpload ? const Color(0xFF3EA6FF) : Colors.transparent),
                          width: 2,
                        ),
                      ),
                      child: ChannelAvatarWidget(
                        author: ch.name,
                        avatarUrl: ch.avatarUrl,
                        channelId: ch.id,
                        radius: 22,
                      ),
                    ),
                    // Blue YouTube Unread Upload Indicator Dot
                    if (ch.hasNewUpload && !isSelected)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3EA6FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 62,
                  child: Text(
                    ch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Banner displayed when a specific channel is selected
  Widget _buildSelectedChannelBanner(
    BuildContext context,
    SubscriptionsViewModel subVm,
    ChannelModel channel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          ChannelAvatarWidget(
            author: channel.name,
            avatarUrl: channel.avatarUrl,
            channelId: channel.id,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (channel.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle, size: 14, color: AppColors.accentCyan),
                    ],
                  ],
                ),
                Text(
                  channel.subscriberCount,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            tooltip: 'Show all channels',
            onPressed: () => subVm.selectChannel(null),
          ),
        ],
      ),
    );
  }

  /// Subscriptions sub-filters row ('All', 'Today', 'Videos', 'Shorts', 'Live')
  Widget _buildFilterChipsRow(SubscriptionsViewModel subVm) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: ['All', 'Today', 'Videos', 'Shorts', 'Live'].map((filter) {
          final isSelected = subVm.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => subVm.setFilter(filter),
              selectedColor: Colors.white,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0F0F0F) : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Body content for Subscriptions feed
  Widget _buildFeedContent(SubscriptionsViewModel subVm, List<VideoModel> videos) {
    // 1. Initial Loading state
    if (subVm.isLoading && videos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.youtubeRed),
      );
    }

    // 2. Empty state
    if (videos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          Center(
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
                    child: const Icon(Icons.subscriptions_outlined, size: 56, color: AppColors.youtubeRed),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subVm.selectedChannel != null
                        ? 'No new uploads from ${subVm.selectedChannel!.name}'
                        : 'No videos for this filter',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subVm.selectedChannel != null
                        ? 'Pull down to refresh or check back later for live broadcasts and updates.'
                        : 'Try selecting a different filter or explore recommended channels below.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  if (subVm.selectedChannel != null)
                    ElevatedButton.icon(
                      onPressed: () => subVm.selectChannel(null),
                      icon: const Icon(Icons.all_inclusive_rounded),
                      label: const Text('Show All Subscriptions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _showAllChannelsModal(context),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explore & Manage Channels'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.youtubeRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 3. Videos Feed (Responsive Grid on wide screens)
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final columns = constraints.maxWidth >= 1300
            ? 4
            : (constraints.maxWidth >= 950 ? 3 : 2);

        if (isWide) {
          final itemWidth = (constraints.maxWidth - (columns - 1) * 16 - 24) / columns;
          final itemHeight = itemWidth * 9 / 16 + 115;
          final ratio = itemWidth / itemHeight;

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: ratio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => VideoCardWidget(video: videos[index], isGrid: true),
                    childCount: videos.length,
                  ),
                ),
              ),
              if (subVm.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
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
                ),
            ],
          );
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: videos.length + (subVm.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (subVm.isLoadingMore && index == videos.length) {
              return const Padding(
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
              );
            }
            final video = videos[index];
            return VideoCardWidget(video: video);
          },
        );
      },
    );
  }

  /// Interactive YouTube "All Subscriptions" bottom sheet with channel management & recommendations
  void _showAllChannelsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalCtx) {
        return Consumer2<SubscriptionService, SubscriptionsViewModel>(
          builder: (ctx, subService, subVm, _) {
            final subbed = subService.subscribedChannels;
            final discover = subService.getDiscoverChannels();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Modal Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Subscriptions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${subbed.length} channels',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: AppColors.surfaceLight, height: 1),

                    // List of Channels
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          if (subbed.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                              child: Text(
                                'SUBSCRIBED CHANNELS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ...subbed.map((ch) {
                              return ListTile(
                                leading: ChannelAvatarWidget(
                                  author: ch.name,
                                  avatarUrl: ch.avatarUrl,
                                  channelId: ch.id,
                                  radius: 20,
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        ch.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (ch.isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.check_circle, size: 14, color: AppColors.accentCyan),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  ch.subscriberCount,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                                ),
                                trailing: OutlinedButton(
                                  onPressed: () async {
                                    await subService.unsubscribe(ch.name);
                                    if (ctx.mounted) {
                                      AppSnackBar.showInfo(
                                        ctx,
                                        'Unsubscribed from ${ch.name}',
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.surfaceLight),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Subscribed', style: TextStyle(fontSize: 12)),
                                ),
                                onTap: () {
                                  Navigator.pop(modalCtx);
                                  subVm.selectChannel(ch);
                                },
                              );
                            }),
                          ],

                          if (discover.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                              child: Text(
                                'RECOMMENDED CHANNELS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ...discover.map((ch) {
                              return ListTile(
                                leading: ChannelAvatarWidget(
                                  author: ch.name,
                                  avatarUrl: ch.avatarUrl,
                                  channelId: ch.id,
                                  radius: 20,
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        ch.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (ch.isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.check_circle, size: 14, color: AppColors.accentCyan),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  ch.subscriberCount,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    await subService.subscribe(ch);
                                    if (ctx.mounted) {
                                      AppSnackBar.showSuccess(
                                        ctx,
                                        'Subscribed to ${ch.name}',
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Subscribe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
