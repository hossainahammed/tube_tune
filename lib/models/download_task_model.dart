import 'video_model.dart';

/// Model representing a downloaded offline video file and its metadata.
class DownloadedVideoModel {
  final VideoModel video;
  final String localFilePath;
  final int fileSizeBytes;
  final DateTime downloadedAt;

  const DownloadedVideoModel({
    required this.video,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  String get formattedSize {
    if (fileSizeBytes <= 0) return 'Unknown size';
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'video': video.toJson(),
        'localFilePath': localFilePath,
        'fileSizeBytes': fileSizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedVideoModel.fromJson(Map<String, dynamic> json) {
    return DownloadedVideoModel(
      video: VideoModel.fromJson(json['video'] as Map<String, dynamic>),
      localFilePath: json['localFilePath'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
