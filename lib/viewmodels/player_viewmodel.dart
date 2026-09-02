import 'package:flutter/foundation.dart';
import '../core/services/filter_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/youtube_service.dart';
import '../models/comment_model.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

/// ViewModel managing video playback, related videos, comments, and watch history.
class PlayerViewModel with ChangeNotifier {
  final StorageService storage;
  final YoutubeService youtubeService;
  final SettingsViewModel settingsViewModel;

  VideoModel? _currentVideo;
  bool _isPlaying = false;
  bool _isMiniPlayerVisible = false;
  List<VideoModel> _relatedVideos = [];
  List<CommentModel> _comments = [];
  bool _isLoadingDetails = false;

  final Set<String> _likedVideoIds = {};
  List<VideoModel> _watchHistory = [];
  List<VideoModel> _watchLater = [];

  PlayerViewModel({
    required this.storage,
    required this.youtubeService,
    required this.settingsViewModel,
  }) {
    _loadSavedData();
  }

  // Getters
  VideoModel? get currentVideo => _currentVideo;
  bool get isPlaying => _isPlaying;
  bool get isMiniPlayerVisible => _isMiniPlayerVisible;
  List<VideoModel> get relatedVideos => _relatedVideos;
  List<CommentModel> get comments => _comments;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isAdBlocked => settingsViewModel.enableAdBlock;

  List<VideoModel> get watchHistory => List.unmodifiable(_watchHistory);
  List<VideoModel> get watchLater => List.unmodifiable(_watchLater);
  Set<String> get likedVideoIds => Set.unmodifiable(_likedVideoIds);
  bool isLiked(String id) => _likedVideoIds.contains(id);
  bool isWatchLater(String id) => _watchLater.any((v) => v.id == id);

  void _loadSavedData() {
    _watchHistory = storage.getWatchHistory();
    _watchLater = storage.getWatchLater();
    notifyListeners();
  }

  Future<void> playVideo(VideoModel video) async {
    _currentVideo = video;
    _isPlaying = true;
    _isMiniPlayerVisible = true;
    _isLoadingDetails = true;
    notifyListeners();

    // Add to watch history
    _addToHistory(video);

    // Fetch comments & filtered related videos
    try {
      final commentsFuture = youtubeService.fetchComments(video.id);
      final rawRelated = youtubeService.getCuratedVideosByCategory(video.categoryTag);

      final filterResult = FilterService.instance.filterList(
        rawRelated.where((v) => v.id != video.id).toList(),
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
      );

      _relatedVideos = filterResult.allowed;
      _comments = await commentsFuture;
    } catch (_) {
      _relatedVideos = [];
      _comments = [];
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void closeMiniPlayer() {
    _isMiniPlayerVisible = false;
    _isPlaying = false;
    _currentVideo = null;
    notifyListeners();
  }

  void toggleLike(String videoId) {
    if (_likedVideoIds.contains(videoId)) {
      _likedVideoIds.remove(videoId);
    } else {
      _likedVideoIds.add(videoId);
    }
    notifyListeners();
  }

  Future<void> toggleWatchLater(VideoModel video) async {
    if (isWatchLater(video.id)) {
      _watchLater = _watchLater.where((v) => v.id != video.id).toList();
    } else {
      _watchLater = [video, ..._watchLater];
    }
    await storage.saveWatchLater(_watchLater);
    notifyListeners();
  }

  void _addToHistory(VideoModel video) {
    _watchHistory = [
      video,
      ..._watchHistory.where((v) => v.id != video.id),
    ].take(30).toList();
    storage.saveWatchHistory(_watchHistory);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _watchHistory = [];
    await storage.saveWatchHistory([]);
    notifyListeners();
  }
}
