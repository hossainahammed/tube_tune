/// Model representing a YouTube-style video or channel notification.
class AppNotificationModel {
  final String id;
  final String channelName;
  final String channelAvatarUrl;
  final String title;
  final String timeAgo;
  final String videoId;
  final String videoThumbnailUrl;
  final bool isRead;
  final bool isLive;

  const AppNotificationModel({
    required this.id,
    required this.channelName,
    required this.channelAvatarUrl,
    required this.title,
    required this.timeAgo,
    required this.videoId,
    required this.videoThumbnailUrl,
    this.isRead = false,
    this.isLive = false,
  });

  AppNotificationModel copyWith({
    String? id,
    String? channelName,
    String? channelAvatarUrl,
    String? title,
    String? timeAgo,
    String? videoId,
    String? videoThumbnailUrl,
    bool? isRead,
    bool? isLive,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      channelName: channelName ?? this.channelName,
      channelAvatarUrl: channelAvatarUrl ?? this.channelAvatarUrl,
      title: title ?? this.title,
      timeAgo: timeAgo ?? this.timeAgo,
      videoId: videoId ?? this.videoId,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      isRead: isRead ?? this.isRead,
      isLive: isLive ?? this.isLive,
    );
  }
}
