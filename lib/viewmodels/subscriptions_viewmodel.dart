import 'package:flutter/foundation.dart';
import '../core/constants/app_categories.dart';
import '../core/services/filter_service.dart';
import '../core/services/subscription_service.dart';
import '../core/services/youtube_service.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

/// ViewModel managing the Subscriptions feed, channel avatars row, sub-filters, and live updates.
class SubscriptionsViewModel with ChangeNotifier {
  final YoutubeService youtubeService;
  final SubscriptionService subscriptionService;
  final SettingsViewModel settingsViewModel;

  List<VideoModel> _allSubscribedVideos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _selectedFilter = 'All';
  ChannelModel? _selectedChannel;
  String? _errorMessage;
  int _page = 0;

  SubscriptionsViewModel({
    required this.youtubeService,
    required this.subscriptionService,
    required this.settingsViewModel,
  }) {
    subscriptionService.addListener(_onSubscriptionsChanged);
    settingsViewModel.addListener(_onSettingsChanged);
    loadSubscriptionsFeed();
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_onSubscriptionsChanged);
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }

  // Getters
  List<ChannelModel> get channels => subscriptionService.subscribedChannels;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get selectedFilter => _selectedFilter;
  ChannelModel? get selectedChannel => _selectedChannel;
  String? get errorMessage => _errorMessage;

  List<VideoModel> get filteredVideos {
    return _allSubscribedVideos.where((v) {
      if (_selectedChannel != null) {
        final chName = _selectedChannel!.name.toLowerCase().trim();
        final author = v.author.toLowerCase().trim();
        if (author != chName && !author.contains(chName) && !chName.contains(author)) {
          return false;
        }
      }

      if (_selectedFilter == 'Live') {
        return v.isLive || v.uploadDate.toLowerCase().contains('live');
      }
      if (_selectedFilter == 'Videos') {
        return !v.isLive && !v.isShort;
      }
      if (_selectedFilter == 'Shorts') {
        return v.isShort;
      }
      if (_selectedFilter == 'Today') {
        final up = v.uploadDate.toLowerCase();
        return up.contains('hour') ||
            up.contains('minute') ||
            up.contains('today') ||
            up.contains('live') ||
            up.contains('recently');
      }
      return true;
    }).toList();
  }

  void _onSubscriptionsChanged() {
    loadSubscriptionsFeed(isRefresh: true);
  }

  void _onSettingsChanged() {
    loadSubscriptionsFeed(isRefresh: true);
  }

  void selectChannel(ChannelModel? channel) {
    if (_selectedChannel?.name == channel?.name) {
      _selectedChannel = null;
    } else {
      _selectedChannel = channel;
    }
    notifyListeners();

    if (_selectedChannel != null) {
      _fetchChannelSpecificFeed(_selectedChannel!);
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Load fresh live uploads directly from YouTube for all subscribed channels
  Future<void> loadSubscriptionsFeed({bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;

    _page = 0;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final subbedChannels = subscriptionService.subscribedChannels;
      if (subbedChannels.isEmpty) {
        _allSubscribedVideos = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<VideoModel> rawVideos = [];

      // Query real YouTube for recent uploads across subscribed channels in parallel
      final queries = subbedChannels.take(8).map((ch) {
        return youtubeService.searchLiveYouTube(
          '${ch.name} সংবাদ bulletin news today',
          categoryTag: AppCategories.categoryNews,
        );
      }).toList();

      final resultsList = await Future.wait(queries);
      for (final list in resultsList) {
        rawVideos.addAll(list);
      }

      // If results are few, enrich with channel's live streams
      if (rawVideos.length < 10) {
        final liveQueries = subbedChannels.take(4).map((ch) {
          return youtubeService.searchLiveYouTube(
            '${ch.name} live stream',
            categoryTag: AppCategories.categoryLiveTv,
          );
        });
        final liveResults = await Future.wait(liveQueries);
        for (final list in liveResults) {
          rawVideos.addAll(list);
        }
      }

      // Deduplicate by ID
      final seenIds = <String>{};
      final uniqueVideos = <VideoModel>[];
      for (final v in rawVideos) {
        if (!seenIds.contains(v.id)) {
          seenIds.add(v.id);
          uniqueVideos.add(v);
        }
      }

      // Filter via FilterService
      final filterResult = FilterService.instance.filterList(
        uniqueVideos,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );

      var allowed = filterResult.allowed;

      // Fallback: If network query returned 0 items, use curated catalog
      if (allowed.isEmpty) {
        final allCurated = youtubeService.getAllCuratedVideos();
        final curatedFilter = FilterService.instance.filterList(
          allCurated,
          enableShorts: settingsViewModel.enableShorts,
          block18Plus: settingsViewModel.block18Plus,
          strictCategoryMode: settingsViewModel.strictCategoryMode,
          enabledCategories: settingsViewModel.enabledCategories,
          customBlacklist: settingsViewModel.customBlacklist,
          hiddenVideoIds: settingsViewModel.hiddenVideoIds,
          blockedChannels: settingsViewModel.blockedChannels,
        );
        allowed = curatedFilter.allowed;
      }

      _allSubscribedVideos = allowed;
    } catch (e) {
      if (_allSubscribedVideos.isEmpty) {
        _errorMessage = 'Unable to load subscriptions. Please check your connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Specific feed query for a single selected channel
  Future<void> _fetchChannelSpecificFeed(ChannelModel channel) async {
    try {
      final results = await youtubeService.searchLiveYouTube(
        channel.name,
        categoryTag: AppCategories.categoryNews,
      );
      if (results.isNotEmpty) {
        final filterResult = FilterService.instance.filterList(
          results,
          enableShorts: settingsViewModel.enableShorts,
          block18Plus: settingsViewModel.block18Plus,
          strictCategoryMode: settingsViewModel.strictCategoryMode,
          enabledCategories: settingsViewModel.enabledCategories,
          customBlacklist: settingsViewModel.customBlacklist,
          hiddenVideoIds: settingsViewModel.hiddenVideoIds,
          blockedChannels: settingsViewModel.blockedChannels,
        );

        final existingIds = _allSubscribedVideos.map((v) => v.id).toSet();
        for (final v in filterResult.allowed) {
          if (!existingIds.contains(v.id)) {
            _allSubscribedVideos.insert(0, v);
            existingIds.add(v.id);
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Infinite pagination for Subscriptions feed
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      final subbedChannels = subscriptionService.subscribedChannels;
      if (subbedChannels.isEmpty) return;

      final channelIndex = _page % subbedChannels.length;
      final targetChannel = subbedChannels[channelIndex];

      final moreVideos = await youtubeService.searchLiveYouTube(
        '${targetChannel.name} popular highlights',
        categoryTag: AppCategories.categoryNews,
      );

      final filterResult = FilterService.instance.filterList(
        moreVideos,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );

      final existingIds = _allSubscribedVideos.map((v) => v.id).toSet();
      final newUnique = filterResult.allowed.where((v) => !existingIds.contains(v.id)).toList();

      if (newUnique.isNotEmpty) {
        _allSubscribedVideos.addAll(newUnique);
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleSubscription(ChannelModel channel) async {
    await subscriptionService.toggleSubscription(channel);
  }
}
