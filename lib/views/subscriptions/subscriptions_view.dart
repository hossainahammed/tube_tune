import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/widgets/video_card_widget.dart';
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

  final List<Map<String, String>> _channels = [
    {'name': 'SOMOY TV', 'avatar': 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=120&auto=format&fit=crop&q=80', 'hasNew': 'true'},
    {'name': 'Jamuna TV', 'avatar': 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=120&auto=format&fit=crop&q=80', 'hasNew': 'true'},
    {'name': 'BBC Bangla', 'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&auto=format&fit=crop&q=80', 'hasNew': 'true'},
    {'name': 'Al Jazeera', 'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&auto=format&fit=crop&q=80', 'hasNew': 'false'},
    {'name': 'Azhari Media', 'avatar': 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=120&auto=format&fit=crop&q=80', 'hasNew': 'true'},
    {'name': 'As-Sunnah', 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&auto=format&fit=crop&q=80', 'hasNew': 'false'},
    {'name': 'UNICEF Kids', 'avatar': 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=120&auto=format&fit=crop&q=80', 'hasNew': 'true'},
    {'name': 'Flutter Dev', 'avatar': 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=120&auto=format&fit=crop&q=80', 'hasNew': 'false'},
  ];

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final videos = homeVm.videos;

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
              itemCount: _channels.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                if (index == _channels.length) {
                  return InkWell(
                    onTap: () {},
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.surfaceElevated,
                          child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text('All', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                final ch = _channels[index];
                return InkWell(
                  onTap: () {
                    // Filter or search by this channel
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(ch['avatar']!),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                          if (ch['hasNew'] == 'true')
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.background, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 58,
                        child: Text(
                          ch['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
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
              child: ListView.builder(
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
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
