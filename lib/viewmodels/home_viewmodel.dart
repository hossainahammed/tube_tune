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

  void _onSettingsChanged() {
    // When filters or categories change in settings, refresh current feed
    loadFeed(category: _selectedCategory, isRefresh: true);
  }

  Future<void> selectCategory(String categoryId) async {
    if (_selectedCategory == categoryId) return;
    _selectedCategory = categoryId;
    
    // Instant switch to curated content for the selected category
    if (categoryId == AppCategories.categoryAll) {
      final enabledIds = settingsViewModel.enabledCategories.map((c) => c.id).toSet();
      _videos = youtubeService.getAllCuratedVideos()
          .where((v) => enabledIds.isEmpty || enabledIds.contains(v.categoryTag))
          .toList();
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

      _videos = allowed;

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
      // If error occurs, keep existing curated videos if available
      if (_videos.isEmpty) {
        _errorMessage = 'Unable to load feed. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
