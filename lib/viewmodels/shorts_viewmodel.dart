import 'package:flutter/foundation.dart';
import '../core/services/filter_service.dart';
import '../core/services/youtube_service.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

/// ViewModel for vertical swipeable Reels/Shorts with strict 18+ and category filtration.
class ShortsViewModel with ChangeNotifier {
  final YoutubeService youtubeService;
  final SettingsViewModel settingsViewModel;

  List<VideoModel> _shorts = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _shortsPage = 0;
  final Set<String> _likedShortIds = {};

  ShortsViewModel({
    required this.youtubeService,
    required this.settingsViewModel,
  }) {
    settingsViewModel.addListener(_onSettingsChanged);
    loadShorts();
  }

  // Getters
  List<VideoModel> get shorts => _shorts;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool isLiked(String id) => _likedShortIds.contains(id);

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

    // Only reload if actual filter settings or categories changed, NOT on 1-second timer ticks!
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
      loadShorts();
    }
  }

  Future<void> loadShorts() async {
    if (!settingsViewModel.enableShorts) {
      _shorts = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _shortsPage = 0;
    _isLoadingMore = false;
    notifyListeners();

    try {
      final rawShorts = await youtubeService.fetchRealLiveShorts(
        page: 0,
        allow18Plus: !settingsViewModel.block18Plus,
      );

      // Master 18+ & Category Whitelist filtering on Reels/Shorts
      final filterResult = FilterService.instance.filterList(
        rawShorts,
        enableShorts: true,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );

      _shorts = filterResult.allowed;
    } catch (_) {
      final curated = youtubeService.getCuratedShorts();
      _shorts = FilterService.instance.filterList(
        curated,
        enableShorts: true,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      ).allowed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Infinite Scrolling for Shorts: automatically fetches more shorts as user swipes down
  Future<void> loadMoreShorts() async {
    if (_isLoading || _isLoadingMore || !settingsViewModel.enableShorts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _shortsPage + 1;
      final rawShorts = await youtubeService.fetchRealLiveShorts(
        page: nextPage,
        allow18Plus: !settingsViewModel.block18Plus,
      );

      final filterResult = FilterService.instance.filterList(
        rawShorts,
        enableShorts: true,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );

      final allowed = filterResult.allowed;
      if (allowed.isNotEmpty) {
        final existingIds = _shorts.map((s) => s.id).toSet();
        final uniqueNew = allowed.where((s) => !existingIds.contains(s.id)).toList();
        if (uniqueNew.isNotEmpty) {
          _shorts.addAll(uniqueNew);
          _shortsPage = nextPage;
        }
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Real-time deletion of a Short on "Not interested"
  Future<void> markShortNotInterested(VideoModel short) async {
    _shorts.removeWhere((s) => s.id == short.id);
    if (_currentIndex >= _shorts.length && _shorts.isNotEmpty) {
      _currentIndex = _shorts.length - 1;
    }
    notifyListeners();
    await settingsViewModel.addHiddenVideoId(short.id);
  }

  /// Real-time deletion of all Shorts from channel on "Don't recommend channel"
  Future<void> blockChannel(String author, {String? channelId}) async {
    final normAuthor = author.trim().toLowerCase();
    final normId = channelId?.trim().toLowerCase();
    _shorts.removeWhere((s) =>
        s.author.trim().toLowerCase() == normAuthor ||
        (normId != null && s.channelId.trim().toLowerCase() == normId));
    if (_currentIndex >= _shorts.length && _shorts.isNotEmpty) {
      _currentIndex = _shorts.length - 1;
    }
    notifyListeners();
    await settingsViewModel.addBlockedChannel(author);
    if (channelId != null && channelId.isNotEmpty && channelId != author) {
      await settingsViewModel.addBlockedChannel(channelId);
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _shorts.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void toggleLike(String shortId) {
    if (_likedShortIds.contains(shortId)) {
      _likedShortIds.remove(shortId);
    } else {
      _likedShortIds.add(shortId);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
