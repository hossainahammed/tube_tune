import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../models/video_model.dart';
import 'youtube_service.dart';

/// Service managing background audio playback when the user navigates away from the app.
class BackgroundAudioService extends ChangeNotifier {
  BackgroundAudioService._();
  static final BackgroundAudioService instance = BackgroundAudioService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  static const Map<String, String> _streamHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  };

  VideoModel? _currentVideo;
  String? _currentAudioVideoId;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  bool _isPreparing = false;
  bool _isStarting = false;
  VoidCallback? onPlaybackCompleted;

  VideoModel? get currentVideo => _currentVideo;
  String? get currentAudioVideoId => _currentAudioVideoId;
  bool get isPlaying => _isPlaying;
  bool get isPreparing => _isPreparing;
  AudioPlayer get player => _audioPlayer;

  void init() {
    AudioSession.instance.then((session) async {
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    }).catchError((_) {});

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        onPlaybackCompleted?.call();
      }
    });

    _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) async {
      // Stream expired or throttled by YouTube -> Auto-refresh audio stream and resume!
      if (_currentVideo != null && _isPlaying) {
        try {
          final freshUrl = await YoutubeService.instance.getDirectAudioStreamUrl(
            _currentVideo!.id,
            isLive: _currentVideo!.isLive,
          );
          if (freshUrl != null && freshUrl.isNotEmpty) {
            final pos = _audioPlayer.position;
            _currentAudioVideoId = _currentVideo!.id;
            _currentAudioUrl = freshUrl;
            final audioSource = AudioSource.uri(
              Uri.parse(freshUrl),
              headers: _streamHeaders,
              tag: MediaItem(
                id: _currentVideo!.id,
                album: _currentVideo!.author,
                title: _currentVideo!.title,
                artUri: _currentVideo!.thumbnailUrl.isNotEmpty ? Uri.parse(_currentVideo!.thumbnailUrl) : null,
              ),
            );
            await _audioPlayer.setAudioSource(audioSource, initialPosition: pos);
            await _audioPlayer.play();
          }
        } catch (_) {}
      }
    });
  }

  /// Prepare audio directly with an existing stream URL (no extra network fetch required)
  Future<void> prepareAudioWithUrl(VideoModel video, String audioUrl) async {
    _currentVideo = video;
    _currentAudioVideoId = video.id;
    _currentAudioUrl = audioUrl;
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(audioUrl),
        headers: _streamHeaders,
        tag: MediaItem(
          id: video.id,
          album: video.author,
          title: video.title,
          artUri: video.thumbnailUrl.isNotEmpty ? Uri.parse(video.thumbnailUrl) : null,
        ),
      );
      await _audioPlayer.setAudioSource(audioSource);
    } catch (_) {}
  }

  /// Prepare audio stream in advance for the currently playing video
  Future<void> prepareAudio(VideoModel video) async {
    if (_currentAudioVideoId == video.id && _currentAudioUrl != null && _audioPlayer.audioSource != null) return;
    _currentVideo = video;
    _isPreparing = true;
    notifyListeners();

    try {
      final audioUrl = await YoutubeService.instance.getDirectAudioStreamUrl(video.id, isLive: video.isLive);
      if (audioUrl != null && audioUrl.isNotEmpty) {
        _currentAudioVideoId = video.id;
        _currentAudioUrl = audioUrl;
        final audioSource = AudioSource.uri(
          Uri.parse(audioUrl),
          headers: _streamHeaders,
          tag: MediaItem(
            id: video.id,
            album: video.author,
            title: video.title,
            artUri: video.thumbnailUrl.isNotEmpty ? Uri.parse(video.thumbnailUrl) : null,
          ),
        );
        await _audioPlayer.setAudioSource(audioSource);
      }
    } catch (_) {} finally {
      _isPreparing = false;
      notifyListeners();
    }
  }

  /// Start playing audio in background starting from given position
  Future<void> startBackgroundPlay(VideoModel video, {Duration startPosition = Duration.zero, String? streamUrl}) async {
    if (_isPlaying && _currentAudioVideoId == video.id) return;
    if (_isStarting) return;
    _isStarting = true;
    _currentVideo = video;

    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (_) {}

    try {
      if (_currentAudioUrl == null || _currentAudioVideoId != video.id || _audioPlayer.audioSource == null) {
        String? audioUrl = streamUrl;
        if (audioUrl == null || audioUrl.isEmpty) {
          audioUrl = await YoutubeService.instance.getDirectAudioStreamUrl(video.id, isLive: video.isLive);
        }
        if (audioUrl != null && audioUrl.isNotEmpty) {
          _currentAudioVideoId = video.id;
          _currentAudioUrl = audioUrl;
          final audioSource = AudioSource.uri(
            Uri.parse(audioUrl),
            headers: _streamHeaders,
            tag: MediaItem(
              id: video.id,
              album: video.author,
              title: video.title,
              artUri: video.thumbnailUrl.isNotEmpty ? Uri.parse(video.thumbnailUrl) : null,
            ),
          );
          await _audioPlayer.setAudioSource(audioSource);
        }
      }

      if (!video.isLive && startPosition > Duration.zero) {
        try {
          await _audioPlayer.seek(startPosition);
        } catch (_) {}
      }

      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    } catch (_) {} finally {
      _isStarting = false;
    }
  }

  /// Pause background audio
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (_) {}
    _isPlaying = false;
    notifyListeners();
  }

  /// Resume background audio
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (_) {}
    _isPlaying = true;
    notifyListeners();
  }

  /// Stop and release background playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _currentVideo = null;
    _currentAudioVideoId = null;
    _currentAudioUrl = null;
    _isPlaying = false;
    notifyListeners();
  }

  Duration get position => _audioPlayer.position;
}
