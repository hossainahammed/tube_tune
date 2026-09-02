import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/video_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
import '../shared/channel_avatar_widget.dart';
import '../shared/custom_app_bar.dart';
import '../shared/timer_status_bar.dart';

/// Subscriptions Tab identical to official YouTube mobile with channel avatar row and video feed.
class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  String _selectedSubFilter = 'All';
  String? _selectedChannel;

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final allVideos = homeVm.videos;

    // Extract dynamic unique channels from the active feed
    final Map<String, VideoModel> uniqueChannels = {};
    for (final v in allVideos) {
      if (!uniqueChannels.containsKey(v.author)) {
        uniqueChannels[v.author] = v;
      }
    }
    final channelList = uniqueChannels.values.toList();

    // Filter videos according to selected channel & sub-filter chips
    final filteredVideos = allVideos.where((v) {
      if (_selectedChannel != null && v.author != _selectedChannel) {
        return false;
      }
      if (_selectedSubFilter == 'Live') {
        return v.isLive || v.uploadDate.toLowerCase().contains('live');
      }
      if (_selectedSubFilter == 'Videos') {
        return !v.isLive && !v.isShort;
      }
      if (_selectedSubFilter == 'Shorts') {
        return v.isShort;
      }
      if (_selectedSubFilter == 'Today') {
        final up = v.uploadDate.toLowerCase();
        return up.contains('hour') || up.contains('minute') || up.contains('today') || up.contains('live');
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          const TimerStatusBar(),

          // 1. Horizontal Subscribed Channels Avatars Row
          Container(
            height: 96,
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
              itemCount: channelList.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                if (index == channelList.length) {
                  return InkWell(
                    onTap: () => setState(() => _selectedChannel = null),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _selectedChannel == null
                              ? AppColors.youtubeRed.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          child: Icon(
                            Icons.all_inclusive_rounded,
                            size: 20,
                            color: _selectedChannel == null ? AppColors.youtubeRed : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _selectedChannel == null ? FontWeight.bold : FontWeight.normal,
                            color: _selectedChannel == null ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final ch = channelList[index];
                final isSelected = _selectedChannel == ch.author;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedChannel == ch.author) {
                        _selectedChannel = null;
                      } else {
                        _selectedChannel = ch.author;
                      }
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.youtubeRed : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ChannelAvatarWidget(
                          author: ch.author,
                          avatarUrl: ch.channelAvatarUrl,
                          radius: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(
                          ch.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. Subscriptions Filter Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: ['All', 'Today', 'Videos', 'Shorts', 'Live'].map((filter) {
                final isSelected = _selectedSubFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedSubFilter = filter),
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
          ),

          // 3. Subscribed Videos Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => homeVm.loadFeed(isRefresh: true),
              color: AppColors.youtubeRed,
              child: filteredVideos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.subscriptions_outlined, size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _selectedChannel != null
                                  ? 'No videos found for $_selectedChannel'
                                  : 'No videos available for this filter',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                            if (_selectedChannel != null) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => setState(() => _selectedChannel = null),
                                child: const Text('Show All Channels', style: TextStyle(color: AppColors.accentCyan)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredVideos.length,
                      itemBuilder: (context, index) {
                        final video = filteredVideos[index];
                        return VideoCardWidget(video: video);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
