import 'package:flutter/foundation.dart';
import '../core/services/filter_service.dart';
import '../core/services/youtube_service.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

/// ViewModel managing Safe Search queries, category search filters, and strict result isolation.
class SearchViewModel with ChangeNotifier {
  final YoutubeService youtubeService;
  final SettingsViewModel settingsViewModel;

  List<VideoModel> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = '';
  bool _isQueryBlocked = false;
  String? _errorMessage;

  SearchViewModel({
    required this.youtubeService,
    required this.settingsViewModel,
  });

  // Getters
  List<VideoModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get currentQuery => _currentQuery;
  bool get isQueryBlocked => _isQueryBlocked;
  String? get errorMessage => _errorMessage;

  List<String> get popularSafeSuggestions {
    final enabled = settingsViewModel.enabledCategories;
    final List<String> suggestions = [];
    for (final cat in enabled) {
      if (cat.keywords.isNotEmpty) {
        suggestions.add(cat.keywords.first);
        if (cat.keywords.length > 1) {
          suggestions.add(cat.keywords[1]);
        }
      }
    }
    return suggestions.take(8).toList();
  }

  Future<void> performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    _currentQuery = trimmed;
    _isQueryBlocked = false;
    _errorMessage = null;

    // Check if query is 18+ / blacklisted or songs/movies under Safe Mode
    if (settingsViewModel.block18Plus &&
        (FilterService.instance.is18PlusText(trimmed, settingsViewModel.customBlacklist) ||
         FilterService.instance.isSongOrMovieQuery(trimmed))) {
      _isQueryBlocked = true;
      _searchResults = [];
      settingsViewModel.recordRejectionStats(filtered: 1, eighteenPlus: 1);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final rawResults = await youtubeService.searchVideos(trimmed);

      // Apply strict filter on search results
      final filterResult = FilterService.instance.filterList(
        rawResults,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
      );

      _searchResults = filterResult.allowed;

      if (filterResult.filteredCount > 0) {
        settingsViewModel.recordRejectionStats(
          filtered: filterResult.filteredCount,
          eighteenPlus: filterResult.eighteenPlusCount,
          shorts: filterResult.shortsCount,
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to execute search.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _searchResults = [];
    _isQueryBlocked = false;
    _errorMessage = null;
    notifyListeners();
  }
}
