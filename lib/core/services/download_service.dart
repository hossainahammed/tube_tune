import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import '../../models/download_task_model.dart';
import '../../models/video_model.dart';
import 'storage_service.dart';
import 'youtube_service.dart';

/// Service managing offline video downloads, storage persistence, and local playback resolution.
class DownloadService extends ChangeNotifier {
  static final DownloadService instance = DownloadService._();

  DownloadService._();

  final List<DownloadedVideoModel> _downloadedVideos = [];
  final Map<String, double> _downloadProgress = {};
  final Set<String> _activeDownloadIds = {};

  List<DownloadedVideoModel> get downloadedVideos => List.unmodifiable(_downloadedVideos);
  int get downloadedCount => _downloadedVideos.length;

  bool isDownloaded(String videoId) {
    return _downloadedVideos.any((d) => d.video.id == videoId);
  }

  bool isDownloading(String videoId) {
    return _activeDownloadIds.contains(videoId);
  }

  double getProgress(String videoId) {
    return _downloadProgress[videoId] ?? 0.0;
  }

  String? getLocalFilePath(String videoId) {
    try {
      final item = _downloadedVideos.firstWhere((d) => d.video.id == videoId);
      final file = File(item.localFilePath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return item.localFilePath;
      }
    } catch (_) {}
    return null;
  }

  Future<void> init() async {
    try {
      final storage = await StorageService.getInstance();
      final persisted = storage.getDownloadedVideos();

      _downloadedVideos.clear();
      for (final item in persisted) {
        final file = File(item.localFilePath);
        if (file.existsSync() && file.lengthSync() > 0) {
          _downloadedVideos.add(item);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing DownloadService: $e');
    }
  }

  Future<Directory> _getDownloadsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/downloads');
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }
    return downloadsDir;
  }

  /// Download a video for offline mode
  Future<bool> downloadVideo(VideoModel video) async {
    if (isDownloaded(video.id) || isDownloading(video.id)) {
      return true;
    }

    _activeDownloadIds.add(video.id);
    _downloadProgress[video.id] = 0.05;
    notifyListeners();

    IOSink? sink;
    File? targetFile;

    try {
      final dir = await _getDownloadsDir();
      targetFile = File('${dir.path}/${video.id}.mp4');
      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }

      final yt = yt_exp.YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient
            .getManifest(video.id)
            .timeout(const Duration(seconds: 15));

        // Prefer 720p or 480p muxed video/audio stream for compact offline playback
        yt_exp.MuxedStreamInfo? selectedStream;
        if (manifest.muxed.isNotEmpty) {
          final sorted = manifest.muxed.sortByVideoQuality();
          // Pick 720p or highest available muxed
          selectedStream = sorted.firstWhere(
            (s) => s.videoQuality.index <= yt_exp.VideoQuality.high720.index,
            orElse: () => sorted.last,
          );
        }

        if (selectedStream != null) {
          final stream = yt.videos.streamsClient.get(selectedStream);
          final totalBytes = selectedStream.size.totalBytes;
          var receivedBytes = 0;

          sink = targetFile.openWrite();

          await for (final chunk in stream) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0) {
              _downloadProgress[video.id] = (receivedBytes / totalBytes).clamp(0.05, 0.99);
              notifyListeners();
            }
          }
          await sink.flush();
          await sink.close();
          sink = null;
        } else {
          // Direct HTTP fallback if muxed manifest wasn't directly accessible
          final directUrl = await YoutubeService.instance.getDirectStreamUrl(video.id);
          if (directUrl == null || directUrl.isEmpty) {
            throw Exception('Could not resolve download stream');
          }

          final client = HttpClient();
          final request = await client.getUrl(Uri.parse(directUrl));
          final response = await request.close();

          final totalBytes = response.contentLength;
          var receivedBytes = 0;

          sink = targetFile.openWrite();
          await for (final chunk in response) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0) {
              _downloadProgress[video.id] = (receivedBytes / totalBytes).clamp(0.05, 0.99);
              notifyListeners();
            }
          }
          await sink.flush();
          await sink.close();
          sink = null;
          client.close();
        }
      } finally {
        yt.close();
      }

      final fileSizeBytes = targetFile.lengthSync();
      if (fileSizeBytes > 1000) {
        final downloadedItem = DownloadedVideoModel(
          video: video,
          localFilePath: targetFile.path,
          fileSizeBytes: fileSizeBytes,
          downloadedAt: DateTime.now(),
        );

        _downloadedVideos.insert(0, downloadedItem);
        _downloadProgress[video.id] = 1.0;

        final storage = await StorageService.getInstance();
        await storage.saveDownloadedVideos(_downloadedVideos);

        return true;
      } else {
        throw Exception('Downloaded file was empty');
      }
    } catch (e) {
      debugPrint('Download error for video ${video.id}: $e');
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (targetFile != null && targetFile.existsSync()) {
        try {
          targetFile.deleteSync();
        } catch (_) {}
      }
      return false;
    } finally {
      _activeDownloadIds.remove(video.id);
      _downloadProgress.remove(video.id);
      notifyListeners();
    }
  }

  /// Delete downloaded offline video from storage
  Future<void> deleteDownloadedVideo(String videoId) async {
    try {
      final index = _downloadedVideos.indexWhere((d) => d.video.id == videoId);
      if (index != -1) {
        final item = _downloadedVideos[index];
        final file = File(item.localFilePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
        _downloadedVideos.removeAt(index);
        final storage = await StorageService.getInstance();
        await storage.saveDownloadedVideos(_downloadedVideos);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting downloaded video: $e');
    }
  }
}
