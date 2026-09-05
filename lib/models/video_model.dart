/// Video Model representing a YouTube video / short item
class VideoModel {
  final String id;
  final String title;
  final String author;
  final String channelId;
  final String channelAvatarUrl;
  final String thumbnailUrl;
  final Duration duration;
  final int viewCount;
  final String uploadDate;
  final String description;
  final bool isShort;
  final bool isAgeRestricted;
  final String categoryTag;
  final int likeCount;
  final List<String> tags;
  final bool isLive;

  const VideoModel({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    this.channelAvatarUrl = '',
    required this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.uploadDate,
    this.description = '',
    this.isShort = false,
    this.isAgeRestricted = false,
    this.categoryTag = 'general',
    this.likeCount = 0,
    this.tags = const [],
    this.isLive = false,
  });

  String get durationFormatted {
    if (isLive) return 'LIVE';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get viewCountFormatted {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    }
    return '$viewCount views';
  }

  String get likeCountFormatted {
    if (likeCount >= 1000000) {
      return '${(likeCount / 1000000).toStringAsFixed(1)}M';
    } else if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    }
    return '$likeCount';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'channelId': channelId,
      'channelAvatarUrl': channelAvatarUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationMs': duration.inMilliseconds,
      'viewCount': viewCount,
      'uploadDate': uploadDate,
      'description': description,
      'isShort': isShort,
      'isAgeRestricted': isAgeRestricted,
      'categoryTag': categoryTag,
      'likeCount': likeCount,
      'tags': tags,
      'isLive': isLive,
    };
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      channelAvatarUrl: json['channelAvatarUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      viewCount: json['viewCount'] as int? ?? 0,
      uploadDate: json['uploadDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isShort: json['isShort'] as bool? ?? false,
      isAgeRestricted: json['isAgeRestricted'] as bool? ?? false,
      categoryTag: json['categoryTag'] as String? ?? 'general',
      likeCount: json['likeCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isLive: json['isLive'] as bool? ?? false,
    );
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? author,
    String? channelId,
    String? channelAvatarUrl,
    String? thumbnailUrl,
    Duration? duration,
    int? viewCount,
    String? uploadDate,
    String? description,
    bool? isShort,
    bool? isAgeRestricted,
    String? categoryTag,
    int? likeCount,
    List<String>? tags,
    bool? isLive,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      channelId: channelId ?? this.channelId,
      channelAvatarUrl: channelAvatarUrl ?? this.channelAvatarUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      uploadDate: uploadDate ?? this.uploadDate,
      description: description ?? this.description,
      isShort: isShort ?? this.isShort,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      categoryTag: categoryTag ?? this.categoryTag,
      likeCount: likeCount ?? this.likeCount,
      tags: tags ?? this.tags,
      isLive: isLive ?? this.isLive,
    );
  }
}
