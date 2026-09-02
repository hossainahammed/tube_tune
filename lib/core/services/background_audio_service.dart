import 'dart:async';
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

  VideoModel? _currentVideo;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  bool _isPreparing = false;

  VideoModel? get currentVideo => _currentVideo;
  bool get isPlaying => _isPlaying;
  bool get isPreparing => _isPreparing;
  AudioPlayer get player => _audioPlayer;

  void init() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  /// Prepare audio stream in advance for the currently playing video
  Future<void> prepareAudio(VideoModel video) async {
    if (_currentVideo?.id == video.id && _currentAudioUrl != null && _audioPlayer.audioSource != null) return;
    _currentVideo = video;
    _isPreparing = true;
    notifyListeners();

    try {
      final audioUrl = await YoutubeService.instance.getDirectAudioStreamUrl(video.id, isLive: video.isLive);
      if (audioUrl != null && audioUrl.isNotEmpty) {
        _currentAudioUrl = audioUrl;
        final audioSource = AudioSource.uri(
          Uri.parse(audioUrl),
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
  Future<void> startBackgroundPlay(VideoModel video, {Duration startPosition = Duration.zero}) async {
    _currentVideo = video;
    try {
      if (_currentAudioUrl == null || _currentVideo?.id != video.id || _audioPlayer.audioSource == null) {
        final audioUrl = await YoutubeService.instance.getDirectAudioStreamUrl(video.id, isLive: video.isLive);
        if (audioUrl != null && audioUrl.isNotEmpty) {
          _currentAudioUrl = audioUrl;
          final audioSource = AudioSource.uri(
            Uri.parse(audioUrl),
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
    } catch (_) {}
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
    _currentAudioUrl = null;
    _isPlaying = false;
    notifyListeners();
  }

  Duration get position => _audioPlayer.position;
}
