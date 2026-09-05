import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/services/background_audio_service.dart';
import '../core/services/download_service.dart';
import '../core/services/filter_service.dart';
import '../core/services/pip_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/youtube_service.dart';
import '../models/comment_model.dart';
import '../models/subtitle_model.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';
import 'settings_viewmodel.dart';

enum CommentSortOrder { top, newest }

/// ViewModel managing video playback, related videos, comments, subtitles, and watch history.
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
  CommentSortOrder _commentSortOrder = CommentSortOrder.top;

  // Video playback controller state
  VideoPlayerController? _videoController;
  YoutubePlayerController? _iframeController;
  bool _isNativeVideoReady = false;
  bool _isLoadingStream = false;
  bool _isAutoplayEnabled = true;
  double _playbackSpeed = 1.0;
  String _selectedQuality = 'Auto (720p)';

  // Real YouTube subtitles state
  List<SubtitleModel> _subtitles = [];
  bool _showCaptions = true;

  final Set<String> _likedVideoIds = {};
  List<VideoModel> _watchHistory = [];
  List<VideoModel> _watchLater = [];

  PlayerViewModel({
    required this.storage,
    required this.youtubeService,
    required this.settingsViewModel,
  }) {
    _loadSavedData();
    settingsViewModel.addListener(_onSettingsChanged);
    _initBackgroundAndPipIntegration();
  }

  void _onSettingsChanged() {
    if (settingsViewModel.timerService.isLocked) {
      handleAppLocked();
    }
  }

  void _initBackgroundAndPipIntegration() {
    BackgroundAudioService.instance.onPlaybackCompleted = () {
      if (_isAutoplayEnabled) {
        playNextVideo();
      }
    };

    PipService.instance.addPipPlayPauseListener((_) {
      togglePlayPause();
    });

    PipService.instance.addPipNextListener(() {
      playNextVideo();
    });

    PipService.instance.addPipPrevListener(() {
      seekTo(Duration.zero);
    });

    PipService.instance.addScreenOffListener(() {
      handleAppBackgrounded();
    });

    PipService.instance.addScreenOnListener(() {
      handleAppForegrounded();
    });

    PipService.instance.addPipModeListener((inPip) {
      if (inPip) {
        BackgroundAudioService.instance.pause();
        if (_videoController != null && _videoController!.value.isInitialized) {
          _videoController!.play();
          _isPlaying = true;
          notifyListeners();
        }
      }
    });
  }

  // Getters
  VideoModel? get currentVideo => _currentVideo;
  bool get isPlaying => _isPlaying;
  bool get isMiniPlayerVisible => _isMiniPlayerVisible;
  List<VideoModel> get relatedVideos => _relatedVideos;
  List<CommentModel> get comments => _comments;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isAdBlocked => settingsViewModel.enableAdBlock;
  CommentSortOrder get commentSortOrder => _commentSortOrder;

  VideoPlayerController? get videoController => _videoController;
  YoutubePlayerController? get iframeController => _iframeController;
  bool get isNativeVideoReady => _isNativeVideoReady;
  bool get isLoadingStream => _isLoadingStream;
  bool get isAutoplayEnabled => _isAutoplayEnabled;
  double get playbackSpeed => _playbackSpeed;
  String get selectedQuality => _selectedQuality;
  List<SubtitleModel> get subtitles => List.unmodifiable(_subtitles);
  bool get showCaptions => _showCaptions;

  List<VideoModel> get watchHistory => List.unmodifiable(_watchHistory);
  List<VideoModel> get watchLater => List.unmodifiable(_watchLater);
  Set<String> get likedVideoIds => Set.unmodifiable(_likedVideoIds);
  bool isLiked(String id) => _likedVideoIds.contains(id);
  bool isWatchLater(String id) => _watchLater.any((v) => v.id == id);

  static String cleanYoutubeId(String raw) {
    String clean = raw.trim();
    if (clean.contains('v=')) {
      clean = clean.split('v=')[1].split('&')[0];
    } else if (clean.contains('youtu.be/')) {
      clean = clean.split('youtu.be/')[1].split('?')[0];
    } else if (clean.contains('/shorts/')) {
      clean = clean.split('/shorts/')[1].split('?')[0];
    } else if (clean.contains('/live/')) {
      clean = clean.split('/live/')[1].split('?')[0];
    }
    if (clean.length > 11) {
      clean = clean.substring(0, 11);
    }
    return clean;
  }

  void _loadSavedData() {
    _watchHistory = storage.getWatchHistory();
    _watchLater = storage.getWatchLater();
    notifyListeners();
  }

  Future<void> playVideo(VideoModel video) async {
    // If exact same video is already playing, keep playing uninterrupted
    if (_currentVideo?.id == video.id && _videoController != null && _videoController!.value.isInitialized) {
      _isMiniPlayerVisible = true;
      if (!_videoController!.value.isPlaying) {
        await _videoController!.play();
        _isPlaying = true;
        PipService.instance.setVideoPlaying(true);
      }
      notifyListeners();
      return;
    }

    // Dispose old controller before switching to new video
    await _disposePlayerControllers();

    _currentVideo = video;
    _isPlaying = true;
    _isMiniPlayerVisible = true;
    _isLoadingStream = true;
    _isNativeVideoReady = false;
    _isLoadingDetails = true;
    _subtitles = [];
    notifyListeners();

    // Add to watch history
    _addToHistory(video);

    // Prepare or start background audio stream if background play is enabled
    if (settingsViewModel.enableBackgroundPlay) {
      if (BackgroundAudioService.instance.isPlaying) {
        BackgroundAudioService.instance.startBackgroundPlay(video);
      } else {
        BackgroundAudioService.instance.prepareAudio(video);
      }
      PipService.instance.setVideoPlaying(true);
    }

    // Load real subtitles from YouTube in parallel
    _loadSubtitles(video.id);

    // Initialize native video player stream
    await _initVideoPlayer(video);

    // Fetch comments & filtered related videos with real channel avatars
    try {
      final userSavedComments = storage.getUserComments(video.id);
      final dynamicComments = await youtubeService.fetchCommentsForVideo(video);

      // Fetch dynamic related videos directly from YouTube
      List<VideoModel> dynamicRelated = [];
      try {
        dynamicRelated = await youtubeService.fetchRelatedVideos(video);
      } catch (_) {}

      final rawRelated = dynamicRelated.isNotEmpty
          ? dynamicRelated
          : youtubeService
              .getCuratedVideosByCategory(video.categoryTag)
              .where((v) => v.id != video.id)
              .toList();

      // Deduplicate and ensure channel avatars from dynamic cache
      final seenIds = <String>{video.id};
      final uniqueRelated = <VideoModel>[];
      for (final v in rawRelated) {
        if (!seenIds.contains(v.id)) {
          seenIds.add(v.id);
          final resolvedAvatar = v.channelAvatarUrl.isNotEmpty
              ? v.channelAvatarUrl
              : YoutubeService.getCachedChannelAvatar(v.author, channelId: v.channelId);
          uniqueRelated.add(
            resolvedAvatar.isNotEmpty
                ? v.copyWith(channelAvatarUrl: resolvedAvatar)
                : v,
          );
        }
      }

      final filterResult = FilterService.instance.filterList(
        uniqueRelated,
        enableShorts: settingsViewModel.enableShorts,
        block18Plus: settingsViewModel.block18Plus,
        strictCategoryMode: settingsViewModel.strictCategoryMode,
        enabledCategories: settingsViewModel.enabledCategories,
        customBlacklist: settingsViewModel.customBlacklist,
        hiddenVideoIds: settingsViewModel.hiddenVideoIds,
        blockedChannels: settingsViewModel.blockedChannels,
      );

      _relatedVideos = filterResult.allowed;
      _comments = [...userSavedComments, ...dynamicComments];
      _sortComments();
    } catch (_) {
      _relatedVideos = [];
      _comments = storage.getUserComments(video.id);
      _sortComments();
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> _initVideoPlayer(VideoModel video) async {
    final cleanId = cleanYoutubeId(video.id);

    // 1. Check if the video is already downloaded locally for instant offline playback!
    final localPath = DownloadService.instance.getLocalFilePath(cleanId) ??
        DownloadService.instance.getLocalFilePath(video.id);
    if (localPath != null && localPath.isNotEmpty) {
      try {
        final localFile = File(localPath);
        if (localFile.existsSync() && localFile.lengthSync() > 0) {
          final vc = VideoPlayerController.file(localFile);
          await vc.initialize();
          if (_currentVideo?.id != video.id) {
            vc.dispose();
            return;
          }
          vc.addListener(_onVideoControllerUpdate);
          await vc.play();
          await vc.setPlaybackSpeed(_playbackSpeed);

          _videoController = vc;
          _isNativeVideoReady = true;
          _isLoadingStream = false;
          _isPlaying = true;
          PipService.instance.setVideoPlaying(true);
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error playing offline file: $e');
      }
    }

    try {
      final streamUrl = await youtubeService.getDirectStreamUrl(
        cleanId,
        isLive: video.isLive,
      );

      if (streamUrl != null && streamUrl.isNotEmpty) {
        final vc = VideoPlayerController.networkUrl(
          Uri.parse(streamUrl),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        );

        await vc.initialize();
        if (_currentVideo?.id != video.id) {
          vc.dispose();
          return;
        }

        vc.addListener(_onVideoControllerUpdate);
        await vc.play();
        await vc.setPlaybackSpeed(_playbackSpeed);

        _videoController = vc;
        _isNativeVideoReady = true;
        _isLoadingStream = false;
        _isPlaying = true;
        PipService.instance.setVideoPlaying(true);
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Fallback to iframe if direct stream is not available
    _initIframeFallback(cleanId);
  }

  void _initIframeFallback(String cleanId) {
    try {
      _iframeController = YoutubePlayerController.fromVideoId(
        videoId: cleanId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          playsInline: true,
          strictRelatedVideos: false,
        ),
      );
    } catch (_) {}
    _isNativeVideoReady = false;
    _isLoadingStream = false;
    notifyListeners();
  }

  void _onVideoControllerUpdate() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final isControllerPlaying = _videoController!.value.isPlaying;
    if (_isPlaying != isControllerPlaying) {
      _isPlaying = isControllerPlaying;
      PipService.instance.setVideoPlaying(_isPlaying);
      notifyListeners();
    }

    // Autoplay next video when current non-live video reaches the end
    if (_isAutoplayEnabled &&
        !(_currentVideo?.isLive ?? false) &&
        _videoController!.value.duration > const Duration(seconds: 10) &&
        _videoController!.value.position >= _videoController!.value.duration - const Duration(milliseconds: 600) &&
        !_videoController!.value.isBuffering) {
      final next = getNextVideo();
      if (next != null) {
        playVideo(next);
      }
    }
  }

  Future<void> _loadSubtitles(String rawVideoId) async {
    try {
      final cleanId = cleanYoutubeId(rawVideoId);
      final subs = await youtubeService.getSubtitles(cleanId);
      _subtitles = subs;
      notifyListeners();
    } catch (_) {
      _subtitles = [];
    }
  }

  /// Get caption for current playback position. Returns empty string if no caption is spoken.
  String getCaptionForPosition(Duration pos) {
    if (!_showCaptions || _subtitles.isEmpty) return '';
    for (final s in _subtitles) {
      if (pos >= s.start && pos <= s.end) {
        return s.text;
      }
    }
    return '';
  }

  void toggleCaptions() {
    _showCaptions = !_showCaptions;
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    _videoController?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  void setQuality(String quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  void toggleAutoplay() {
    _isAutoplayEnabled = !_isAutoplayEnabled;
    notifyListeners();
  }

  void seekTo(Duration position) {
    _videoController?.seekTo(position);
    _iframeController?.seekTo(seconds: position.inSeconds.toDouble());
  }

  void togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
        PipService.instance.setVideoPlaying(false);
      } else {
        _videoController!.play();
        _isPlaying = true;
        PipService.instance.setVideoPlaying(true);
      }
      notifyListeners();
    } else if (_iframeController != null) {
      if (_isPlaying) {
        _iframeController!.pauseVideo();
        _isPlaying = false;
      } else {
        _iframeController!.playVideo();
        _isPlaying = true;
      }
      notifyListeners();
    }
  }

  void pauseVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
        PipService.instance.setVideoPlaying(false);
        notifyListeners();
      }
    } else if (_iframeController != null && _isPlaying) {
      _iframeController!.pauseVideo();
      _isPlaying = false;
      notifyListeners();
    }
    BackgroundAudioService.instance.pause();
  }

  void resumeVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (!_videoController!.value.isPlaying) {
        _videoController!.play();
        _isPlaying = true;
        PipService.instance.setVideoPlaying(true);
        notifyListeners();
      }
    } else if (_iframeController != null && !_isPlaying) {
      _iframeController!.playVideo();
      _isPlaying = true;
      notifyListeners();
    }
  }

  void closeMiniPlayer() {
    _disposePlayerControllers();
    _isMiniPlayerVisible = false;
    _isPlaying = false;
    _currentVideo = null;
    BackgroundAudioService.instance.stop();
    PipService.instance.setVideoPlaying(false);
    notifyListeners();
  }

  Future<void> _disposePlayerControllers() async {
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoControllerUpdate);
      try {
        await _videoController!.pause();
      } catch (_) {}
      try {
        await _videoController!.dispose();
      } catch (_) {}
      _videoController = null;
    }
    if (_iframeController != null) {
      try {
        _iframeController!.close();
      } catch (_) {}
      _iframeController = null;
    }
    _isNativeVideoReady = false;
    _isLoadingStream = false;
  }

  /// Change comment sort order (Top comments vs Newest first)
  void setCommentSortOrder(CommentSortOrder order) {
    _commentSortOrder = order;
    _sortComments();
    notifyListeners();
  }

  void _sortComments() {
    if (_commentSortOrder == CommentSortOrder.top) {
      _comments.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    } else {
      _comments.sort((a, b) {
        if (a.id.startsWith('user_') && !b.id.startsWith('user_')) return -1;
        if (!a.id.startsWith('user_') && b.id.startsWith('user_')) return 1;
        return b.id.compareTo(a.id);
      });
    }
  }

  /// Post a new user comment and persist it
  void addComment(String videoId, String text, UserModel currentUser) {
    if (text.trim().isEmpty) return;
    final newComment = CommentModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      author: currentUser.name.isNotEmpty ? currentUser.name : 'You',
      authorAvatar: currentUser.avatarUrl,
      text: text.trim(),
      publishedTime: 'Just now',
      likeCount: 0,
      isLikedByMe: false,
    );
    _comments.insert(0, newComment);
    storage.saveUserComment(videoId, newComment);
    notifyListeners();
  }

  /// Toggle like state on a comment
  void toggleCommentLike(String commentId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final comment = _comments[index];
      final isLiked = comment.isLikedByMe;
      _comments[index] = comment.copyWith(
        isLikedByMe: !isLiked,
        likeCount: isLiked
            ? (comment.likeCount > 0 ? comment.likeCount - 1 : 0)
            : comment.likeCount + 1,
      );
      notifyListeners();
    }
  }

  /// Dynamic formatted like count reflecting user interaction
  String getDisplayLikeCount(VideoModel video) {
    final isLiked = _likedVideoIds.contains(video.id);
    final count = isLiked ? video.likeCount + 1 : video.likeCount;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
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

  void playNextInQueue(VideoModel video) {
    _relatedVideos.removeWhere((v) => v.id == video.id);
    _relatedVideos.insert(0, video);
    notifyListeners();
  }

  void hideRelatedVideo(String videoId) {
    _relatedVideos.removeWhere((v) => v.id == videoId);
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

  /// Get the next video to play from related videos or category queue
  VideoModel? getNextVideo() {
    if (_relatedVideos.isNotEmpty) {
      return _relatedVideos.first;
    }
    final allCurated = youtubeService.getCuratedVideosByCategory(_currentVideo?.categoryTag ?? 'all');
    final available = allCurated.where((v) => v.id != _currentVideo?.id).toList();
    if (available.isNotEmpty) {
      return available.first;
    }
    return null;
  }

  /// Play next video in queue with boolean outcome
  bool playNextVideo() {
    final next = getNextVideo();
    if (next != null) {
      playVideo(next);
      return true;
    }
    return false;
  }

  /// Stop all video playback and audio immediately
  void stopVideo() {
    _videoController?.pause();
    _iframeController?.pauseVideo();
    _isPlaying = false;
    _disposePlayerControllers();
    BackgroundAudioService.instance.stop();
    PipService.instance.setVideoPlaying(false);
    notifyListeners();
  }

  /// Global handler when Timer Locker locks the app
  void handleAppLocked() {
    stopVideo();
    _isMiniPlayerVisible = false;
    _currentVideo = null;
    notifyListeners();
  }

  /// Handle app entering background (minimized, screen locked, app switcher)
  Future<void> handleAppBackgrounded() async {
    if (!settingsViewModel.enableBackgroundPlay) return;
    if (!_isPlaying || _currentVideo == null) return;

    // If native Picture-in-Picture window is actively running, keep rendering video
    final inPip = await PipService.instance.isPipActive();
    if (inPip) return;

    // App is minimized or screen is off: Pause video player so Android does not kill surface decoding
    final pos = _videoController?.value.position ?? Duration.zero;
    if (_videoController != null && _videoController!.value.isInitialized) {
      try {
        await _videoController!.pause();
      } catch (_) {}
    }
    if (_iframeController != null) {
      try {
        _iframeController!.pauseVideo();
      } catch (_) {}
    }

    // Seamlessly hand off playback to foreground background audio service
    await BackgroundAudioService.instance.startBackgroundPlay(
      _currentVideo!,
      startPosition: pos,
    );
  }

  /// Handle app returning to foreground
  Future<void> handleAppForegrounded() async {
    if (BackgroundAudioService.instance.isPlaying) {
      final bgPos = BackgroundAudioService.instance.position;
      await BackgroundAudioService.instance.pause();

      if (_videoController != null && _videoController!.value.isInitialized) {
        if (!(_currentVideo?.isLive ?? false) && bgPos > Duration.zero) {
          try {
            await _videoController!.seekTo(bgPos);
          } catch (_) {}
        }
        await _videoController!.play();
        _isPlaying = true;
        PipService.instance.setVideoPlaying(true);
        notifyListeners();
      } else if (_iframeController != null) {
        if (!(_currentVideo?.isLive ?? false) && bgPos > Duration.zero) {
          try {
            _iframeController!.seekTo(seconds: bgPos.inSeconds.toDouble());
          } catch (_) {}
        }
        _iframeController!.playVideo();
        _isPlaying = true;
        notifyListeners();
      }
    } else if (_isPlaying) {
      if (_videoController != null && _videoController!.value.isInitialized && !_videoController!.value.isPlaying) {
        await _videoController!.play();
      }
    }
  }

  @override
  void dispose() {
    settingsViewModel.removeListener(_onSettingsChanged);
    _disposePlayerControllers();
    super.dispose();
  }
}
