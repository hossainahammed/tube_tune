import 'package:flutter/foundation.dart';
import '../core/constants/app_categories.dart';
import '../core/services/filter_service.dart';
import '../core/services/recommendation_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/youtube_service.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

/// ViewModel managing Home Feed state, active category chip, and Shorts shelf.
class HomeViewModel with ChangeNotifier {
  final YoutubeService youtubeService;
  final SettingsViewModel settingsViewModel;
  final StorageService? storageService;

  List<VideoModel> _videos = [];
  List<VideoModel> _liveStreams = [];
  List<VideoModel> _shorts = [];
  List<VideoModel> _suggestedVideos = [];
  bool _isLoading = false;
  String _selectedCategory = AppCategories.categoryAll;
  String? _errorMessage;

  HomeViewModel({
    required this.youtubeService,
    required this.settingsViewModel,
    this.storageService,
  }) {
    // 1. Immediately populate instant filtered curated videos for 0ms startup lag
    final allCurated = youtubeService.getAllCuratedVideos();
    final filterResult = FilterService.instance.filterList(
      allCurated,
      enableShorts: settingsViewModel.enableShorts,
      block18Plus: settingsViewModel.block18Plus,
      strictCategoryMode: settingsViewModel.strictCategoryMode,
      enabledCategories: settingsViewModel.enabledCategories,
      customBlacklist: settingsViewModel.customBlacklist,
      hiddenVideoIds: settingsViewModel.hiddenVideoIds,
      blockedChannels: settingsViewModel.blockedChannels,
    );
    _separateLiveAndFeed(filterResult.allowed);

    if (settingsViewModel.enableShorts) {
      final shortsFilter = FilterService.instance.filterList(
        youtubeService.getCuratedShorts(),
        enableShorts: true,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );
      _shorts = shortsFilter.allowed;
    } else {
      _shorts = [];
    }

    settingsViewModel.addListener(_onSettingsChanged);
    loadFeed();
  }

  bool _isLoadingMore = false;
  int _currentPage = 0;

  // Getters
  List<VideoModel> get videos => _videos;
  List<VideoModel> get liveStreams => _liveStreams;
  List<VideoModel> get shorts => _shorts;
  List<VideoModel> get suggestedVideos => _suggestedVideos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  bool get showShortsShelf => settingsViewModel.enableShorts && _shorts.isNotEmpty;

  bool _lastEnableShorts = true;
  bool _lastBlock18Plus = true;
  bool _lastStrictCategoryMode = true;
  String _lastCustomBlacklistHash = '';
  String _lastCategoriesHash = '';
  String _lastHiddenHash = '';
  String _lastBlockedHash = '';

  void _onSettingsChanged() {
    final enableShorts = settingsViewModel.enableShorts;
    final block18 = settingsViewModel.block18Plus;
    final strict = settingsViewModel.strictCategoryMode;
    final blacklistHash = settingsViewModel.customBlacklist.join(',');
    final categoriesHash = settingsViewModel.enabledCategories.map((c) => c.id).join(',');
    final hiddenHash = settingsViewModel.hiddenVideoIds.join(',');
    final blockedHash = settingsViewModel.blockedChannels.join(',');

    // Only refresh feed if actual filter settings or categories changed, NOT on 1-second timer ticks!
    if (enableShorts != _lastEnableShorts ||
        block18 != _lastBlock18Plus ||
        strict != _lastStrictCategoryMode ||
        blacklistHash != _lastCustomBlacklistHash ||
        categoriesHash != _lastCategoriesHash ||
        hiddenHash != _lastHiddenHash ||
        blockedHash != _lastBlockedHash) {
      _lastEnableShorts = enableShorts;
      _lastBlock18Plus = block18;
      _lastStrictCategoryMode = strict;
      _lastCustomBlacklistHash = blacklistHash;
      _lastCategoriesHash = categoriesHash;
      _lastHiddenHash = hiddenHash;
      _lastBlockedHash = blockedHash;
      loadFeed(category: _selectedCategory, isRefresh: true);
    }
  }

  Future<void> selectCategory(String categoryId) async {
    if (_selectedCategory == categoryId) return;
    _selectedCategory = categoryId;
    
    // Instant switch to curated content for the selected category
    if (categoryId == AppCategories.categoryAll) {
      final allCurated = youtubeService.getAllCuratedVideos();
      final filterResult = FilterService.instance.filterList(
        allCurated,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );
      _separateLiveAndFeed(filterResult.allowed);
    } else {
      final raw = youtubeService.getCuratedVideosByCategory(categoryId);
      final filtered = FilterService.instance.filterList(
        raw,
        enableShorts: false,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
        currentSelectedCategoryId: categoryId,
      ).allowed;
      _separateLiveAndFeed(filtered);
    }
    notifyListeners();

    await loadFeed(category: categoryId);
  }

  Future<void> loadFeed({String? category, bool isRefresh = false}) async {
    final catId = category ?? _selectedCategory;
    _currentPage = 0;
    _isLoadingMore = false;
    if (_videos.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    if (!isRefresh && _videos.isEmpty) notifyListeners();

    try {
      // 1. Fetch live and curated feed targeted specifically to active categories
      final rawVideos = await youtubeService.fetchFeedForCategories(
        currentCategoryId: catId,
        enabledCategories: settingsViewModel.enabledCategories,
        allow18Plus: !settingsViewModel.block18Plus,
        isRefresh: isRefresh,
      );

      // 2. Apply Master Filter Engine (Shorts, 18+, Category Isolation, Blacklist, Hidden/Blocked)
      final filterResult = FilterService.instance.filterList(
        rawVideos,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
        currentSelectedCategoryId: catId == AppCategories.categoryAll ? null : catId,
      );

      var allowed = filterResult.allowed;

      // Fallback: If live results didn't pass, ensure verified curated catalog is displayed
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
          currentSelectedCategoryId: catId == AppCategories.categoryAll ? null : catId,
        );
        allowed = curatedFilter.allowed;
      }

      _separateLiveAndFeed(allowed, isRefresh: isRefresh);

      // Record any blocked items for stats
      if (filterResult.filteredCount > 0) {
        settingsViewModel.recordRejectionStats(
          filtered: filterResult.filteredCount,
          eighteenPlus: filterResult.eighteenPlusCount,
          shorts: filterResult.shortsCount,
        );
      }

      // 3. Fetch personalized suggestions if on "All" feed
      if (catId == AppCategories.categoryAll) {
        try {
          final storage = storageService ?? await StorageService.getInstance();
          final rawSuggested = await RecommendationService.instance.fetchSuggestedVideos(
            youtubeService,
            storage,
          );
          final suggestedFilter = FilterService.instance.filterList(
            rawSuggested,
            enableShorts: false,
            block18Plus: settingsViewModel.block18Plus,
            strictCategoryMode: settingsViewModel.strictCategoryMode,
            enabledCategories: settingsViewModel.enabledCategories,
            customBlacklist: settingsViewModel.customBlacklist,
            hiddenVideoIds: settingsViewModel.hiddenVideoIds,
            blockedChannels: settingsViewModel.blockedChannels,
          );
          _suggestedVideos = suggestedFilter.allowed;
        } catch (_) {
          _suggestedVideos = [];
        }
      } else {
        _suggestedVideos = [];
      }

      // 4. Load and filter Shorts shelf if enabled
      if (settingsViewModel.enableShorts) {
        final rawShorts = youtubeService.getCuratedShorts();
        final shortsFilter = FilterService.instance.filterList(
          rawShorts,
          enableShorts: true,
          block18Plus: settingsViewModel.block18Plus,
          strictCategoryMode: settingsViewModel.strictCategoryMode,
          enabledCategories: settingsViewModel.enabledCategories,
          customBlacklist: settingsViewModel.customBlacklist,
          hiddenVideoIds: settingsViewModel.hiddenVideoIds,
          blockedChannels: settingsViewModel.blockedChannels,
        );
        _shorts = shortsFilter.allowed;
      } else {
        _shorts = [];
      }
    } catch (e) {
      if (_videos.isEmpty) {
        final fallbackCurated = youtubeService.getCuratedVideosByCategory(catId);
        final filteredCurated = FilterService.instance.filterList(
          fallbackCurated,
          enableShorts: false,
          block18Plus: settingsViewModel.block18Plus,
          strictCategoryMode: settingsViewModel.strictCategoryMode,
          enabledCategories: settingsViewModel.enabledCategories,
          customBlacklist: settingsViewModel.customBlacklist,
          hiddenVideoIds: settingsViewModel.hiddenVideoIds,
          blockedChannels: settingsViewModel.blockedChannels,
          currentSelectedCategoryId: catId == AppCategories.categoryAll ? null : catId,
        ).allowed;
        if (filteredCurated.isNotEmpty) {
          _separateLiveAndFeed(filteredCurated, isRefresh: isRefresh);
          _errorMessage = null;
        } else {
          _errorMessage = 'Unable to load feed. Please try again.';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Infinite Scroll: loads more content seamlessly when the user scrolls near the bottom
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newRawVideos = await youtubeService.fetchMoreFeed(
        currentCategoryId: _selectedCategory,
        page: nextPage,
        allow18Plus: !settingsViewModel.block18Plus,
      );

      final filterResult = FilterService.instance.filterList(
        newRawVideos,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
        currentSelectedCategoryId: _selectedCategory == AppCategories.categoryAll ? null : _selectedCategory,
      );

      final allowed = filterResult.allowed;
      if (allowed.isNotEmpty) {
        final existingIds = _videos.map((v) => v.id).toSet();
        final uniqueNew = allowed.where((v) => !existingIds.contains(v.id)).toList();
        if (uniqueNew.isNotEmpty) {
          _videos.addAll(uniqueNew);
          _currentPage = nextPage;
        }
      }
    } catch (_) {
      // Ignore network hiccups on pagination
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Infinite Scroll for specific subscribed channel
  Future<void> loadMoreForChannel(String channelName) async {
    if (_isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final query = '$channelName latest videos news';
      final newRawVideos = await youtubeService.searchLiveYouTube(query);

      final filterResult = FilterService.instance.filterList(
        newRawVideos,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );

      final allowed = filterResult.allowed;
      if (allowed.isNotEmpty) {
        final existingIds = _videos.map((v) => v.id).toSet();
        final uniqueNew = allowed.where((v) => !existingIds.contains(v.id)).toList();
        if (uniqueNew.isNotEmpty) {
          _videos.addAll(uniqueNew);
        }
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Real-time deletion and persistent exclusion for "Not interested"
  Future<void> markVideoNotInterested(VideoModel video) async {
    // 1. Instantly delete from current in-memory lists for 0ms lag
    _videos.removeWhere((v) => v.id == video.id);
    _liveStreams.removeWhere((v) => v.id == video.id);
    _shorts.removeWhere((v) => v.id == video.id);
    _suggestedVideos.removeWhere((v) => v.id == video.id);
    notifyListeners();

    // 2. Persist in storage via SettingsViewModel
    await settingsViewModel.addHiddenVideoId(video.id);
  }

  /// Real-time deletion and persistent exclusion for "Don't recommend channel"
  Future<void> blockChannel(String author, {String? channelId}) async {
    final normAuthor = author.trim().toLowerCase();
    final normId = channelId?.trim().toLowerCase();

    // 1. Instantly delete all videos matching this channel for 0ms lag
    _videos.removeWhere((v) =>
        v.author.trim().toLowerCase() == normAuthor ||
        (normId != null && v.channelId.trim().toLowerCase() == normId));
    _liveStreams.removeWhere((v) =>
        v.author.trim().toLowerCase() == normAuthor ||
        (normId != null && v.channelId.trim().toLowerCase() == normId));
    _shorts.removeWhere((v) =>
        v.author.trim().toLowerCase() == normAuthor ||
        (normId != null && v.channelId.trim().toLowerCase() == normId));
    _suggestedVideos.removeWhere((v) =>
        v.author.trim().toLowerCase() == normAuthor ||
        (normId != null && v.channelId.trim().toLowerCase() == normId));
    notifyListeners();

    // 2. Persist author and channelId
    await settingsViewModel.addBlockedChannel(author);
    if (channelId != null && channelId.isNotEmpty && channelId != author) {
      await settingsViewModel.addBlockedChannel(channelId);
    }
  }

  /// YouTube Feed Separation & Hour-by-Hour Recency Ranking:
  /// - Live Broadcasts are extracted into a dedicated live stream shelf (Breaking News)
  /// - Feed videos (Hourly bulletins & reports) are sorted strictly by recency (15m ago, 30m ago, 1h ago, 2h ago...)
  void _separateLiveAndFeed(List<VideoModel> items, {bool isRefresh = false}) {
    final live = <VideoModel>[];
    final feed = <VideoModel>[];
    final seenLiveChannels = <String>{};

    for (final v in items) {
      if (v.isLive ||
          v.uploadDate.toLowerCase().contains('live') ||
          v.duration == Duration.zero) {
        final key = v.author.toLowerCase().trim();
        if (!seenLiveChannels.contains(key)) {
          seenLiveChannels.add(key);
          live.add(v);
        }
      } else {
        feed.add(v);
      }
    }

    _liveStreams = live;
    _videos = feed;
  }

  @override
  void dispose() {
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
