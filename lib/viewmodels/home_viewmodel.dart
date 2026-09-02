import 'package:flutter/foundation.dart';
import '../core/constants/app_categories.dart';
import '../core/services/filter_service.dart';
import '../core/services/youtube_service.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

/// ViewModel managing Home Feed state, active category chip, and Shorts shelf.
class HomeViewModel with ChangeNotifier {
  final YoutubeService youtubeService;
  final SettingsViewModel settingsViewModel;

  List<VideoModel> _videos = [];
  List<VideoModel> _shorts = [];
  bool _isLoading = false;
  String _selectedCategory = AppCategories.categoryAll;
  String? _errorMessage;

  HomeViewModel({
    required this.youtubeService,
    required this.settingsViewModel,
  }) {
    // 1. Immediately populate instant curated videos for 0ms startup lag
    final enabledIds = settingsViewModel.enabledCategories.map((c) => c.id).toSet();
    final allCurated = youtubeService.getAllCuratedVideos();
    if (enabledIds.isEmpty) {
      _videos = allCurated;
    } else {
      _videos = allCurated.where((v) => enabledIds.contains(v.categoryTag)).toList();
    }
    _shorts = youtubeService.getCuratedShorts();

    settingsViewModel.addListener(_onSettingsChanged);
    loadFeed();
  }

  // Getters
  List<VideoModel> get videos => _videos;
  List<VideoModel> get shorts => _shorts;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  bool get showShortsShelf => settingsViewModel.enableShorts && _shorts.isNotEmpty;

  bool _lastEnableShorts = true;
  bool _lastBlock18Plus = true;
  bool _lastStrictCategoryMode = true;
  String _lastCustomBlacklistHash = '';
  String _lastCategoriesHash = '';

  void _onSettingsChanged() {
    final enableShorts = settingsViewModel.enableShorts;
    final block18 = settingsViewModel.block18Plus;
    final strict = settingsViewModel.strictCategoryMode;
    final blacklistHash = settingsViewModel.customBlacklist.join(',');
    final categoriesHash = settingsViewModel.enabledCategories.map((c) => c.id).join(',');

    // Only refresh feed if actual filter settings or categories changed, NOT on 1-second timer ticks!
    if (enableShorts != _lastEnableShorts ||
        block18 != _lastBlock18Plus ||
        strict != _lastStrictCategoryMode ||
        blacklistHash != _lastCustomBlacklistHash ||
        categoriesHash != _lastCategoriesHash) {
      _lastEnableShorts = enableShorts;
      _lastBlock18Plus = block18;
      _lastStrictCategoryMode = strict;
      _lastCustomBlacklistHash = blacklistHash;
      _lastCategoriesHash = categoriesHash;
      loadFeed(category: _selectedCategory, isRefresh: true);
    }
  }

  Future<void> selectCategory(String categoryId) async {
    if (_selectedCategory == categoryId) return;
    _selectedCategory = categoryId;
    
    // Instant switch to curated content for the selected category
    if (categoryId == AppCategories.categoryAll) {
      if (!settingsViewModel.block18Plus) {
        _videos = youtubeService.getAllCuratedVideos();
      } else {
        final enabledIds = settingsViewModel.enabledCategories.map((c) => c.id).toSet();
        _videos = youtubeService.getAllCuratedVideos()
            .where((v) => (enabledIds.isEmpty || enabledIds.contains(v.categoryTag)) && !FilterService.instance.isSongsOrMovies(v))
            .toList();
      }
    } else {
      _videos = youtubeService.getCuratedVideosByCategory(categoryId);
    }
    notifyListeners();

    await loadFeed(category: categoryId);
  }

  Future<void> loadFeed({String? category, bool isRefresh = false}) async {
    final catId = category ?? _selectedCategory;
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

      // 2. Apply Master Filter Engine (Shorts, 18+, Category Isolation, Blacklist)
      final filterResult = FilterService.instance.filterList(
        rawVideos,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
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
          currentSelectedCategoryId: catId == AppCategories.categoryAll ? null : catId,
        );
        allowed = curatedFilter.allowed;
      }

      _videos = _sortByVisibleTime(allowed);

      // Record any blocked items for stats
      if (filterResult.filteredCount > 0) {
        settingsViewModel.recordRejectionStats(
          filtered: filterResult.filteredCount,
          eighteenPlus: filterResult.eighteenPlusCount,
          shorts: filterResult.shortsCount,
        );
      }

      // 3. Load and filter Shorts shelf if enabled
      if (settingsViewModel.enableShorts) {
        final rawShorts = youtubeService.getCuratedShorts();
        final shortsFilter = FilterService.instance.filterList(
          rawShorts,
          enableShorts: true,
          block18Plus: settingsViewModel.block18Plus,
          strictCategoryMode: settingsViewModel.strictCategoryMode,
          enabledCategories: settingsViewModel.enabledCategories,
          customBlacklist: settingsViewModel.customBlacklist,
        );
        _shorts = shortsFilter.allowed;
      } else {
        _shorts = [];
      }
    } catch (e) {
      if (_videos.isEmpty) {
        final fallbackCurated = youtubeService.getCuratedVideosByCategory(catId);
        if (fallbackCurated.isNotEmpty) {
          _videos = _sortByVisibleTime(fallbackCurated);
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

  /// YouTube Visible Time Ranking:
  /// 1. 24/7 Live Broadcasts (Somoy, BBC, Jamuna, CNN, Al Jazeera, etc.) prioritized at top
  /// 2. Fresh Today / recent hours uploads positioned next
  /// 3. Older catalog videos follow
  List<VideoModel> _sortByVisibleTime(List<VideoModel> videos) {
    if (videos.isEmpty) return [];

    final liveVideos = <VideoModel>[];
    final otherVideos = <VideoModel>[];

    for (final v in videos) {
      if (v.isLive ||
          v.uploadDate.toLowerCase().contains('live') ||
          v.duration.inHours >= 10) {
        liveVideos.add(v);
      } else {
        otherVideos.add(v);
      }
    }

    final result = <VideoModel>[];
    int lIdx = 0;
    int oIdx = 0;

    // Place up to 2 top live broadcasts at the very top
    while (lIdx < liveVideos.length && lIdx < 2) {
      result.add(liveVideos[lIdx++]);
    }

    // Interleave remaining: 2 on-demand videos, then 1 live stream
    while (lIdx < liveVideos.length || oIdx < otherVideos.length) {
      for (int i = 0; i < 2 && oIdx < otherVideos.length; i++) {
        result.add(otherVideos[oIdx++]);
      }
      if (lIdx < liveVideos.length) {
        result.add(liveVideos[lIdx++]);
      }
    }

    return result;
  }

  @override
  void dispose() {
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
