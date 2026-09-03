import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../../models/app_notification_model.dart';

/// Service managing YouTube notification feed, unread counters, and channel alert preferences.
class NotificationService with ChangeNotifier {
  static NotificationService? _instance;

  List<AppNotificationModel> _notifications = [];

  NotificationService._() {
    _initDefaultNotifications();
  }

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _safeNotifyListeners() {
    try {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        notifyListeners();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (_) {
      notifyListeners();
    }
  }

  void _initDefaultNotifications() {
    _notifications = [
      const AppNotificationModel(
        id: 'notif_somoy_live',
        channelName: 'Somoy TV',
        channelAvatarUrl: 'https://yt3.ggpht.com/ytc/AIdro_kU5y8v3C9rQp1w8M7Xq2Z3e6b8c9d0=s176-c-k-c0x00ffffff-no-rj',
        title: '🔴 Somoy TV is live: Somoy Breaking News Bulletin & National Updates',
        timeAgo: '12 minutes ago',
        videoId: '21X5lGlDOfg',
        videoThumbnailUrl: 'https://i.ytimg.com/vi/21X5lGlDOfg/hqdefault.jpg',
        isRead: false,
        isLive: true,
      ),
      const AppNotificationModel(
        id: 'notif_jamuna_upload',
        channelName: 'Jamuna TV',
        channelAvatarUrl: 'https://yt3.ggpht.com/ytc/AIdro_n8o2Z1w4M7Xq3rQp5y8v2Z3e6b8c9d0=s176-c-k-c0x00ffffff-no-rj',
        title: 'Jamuna TV uploaded: আজকের শীর্ষ খবর ও বিশেষ সংবাদ বিশ্লেষণ',
        timeAgo: '45 minutes ago',
        videoId: 'w_Ma8oQLmSM',
        videoThumbnailUrl: 'https://i.ytimg.com/vi/w_Ma8oQLmSM/hqdefault.jpg',
        isRead: false,
      ),
      const AppNotificationModel(
        id: 'notif_bbc_world',
        channelName: 'BBC News',
        channelAvatarUrl: 'https://yt3.ggpht.com/ytc/AIdro_l2Z1w3rQp5y8v4M7Xq8b8c9d0e6=s176-c-k-c0x00ffffff-no-rj',
        title: 'BBC World News: Global headlines & breaking economic developments',
        timeAgo: '2 hours ago',
        videoId: '9Auq9mYxFEE',
        videoThumbnailUrl: 'https://i.ytimg.com/vi/9Auq9mYxFEE/hqdefault.jpg',
        isRead: false,
      ),
      const AppNotificationModel(
        id: 'notif_channel24',
        channelName: 'Channel 24',
        channelAvatarUrl: 'https://yt3.ggpht.com/ytc/AIdro_k3rQp1w8M7Xq2Z5y8v3e6b8c9d0=s176-c-k-c0x00ffffff-no-rj',
        title: 'Channel 24: দেশজুড়ে তাজা খবর ও সরাসরি সম্প্রচার বুলেটিন',
        timeAgo: '4 hours ago',
        videoId: 'L_LUpnjgPso',
        videoThumbnailUrl: 'https://i.ytimg.com/vi/L_LUpnjgPso/hqdefault.jpg',
        isRead: true,
      ),
      const AppNotificationModel(
        id: 'notif_aljazeera',
        channelName: 'Al Jazeera English',
        channelAvatarUrl: 'https://yt3.ggpht.com/ytc/AIdro_m8c9d0e6b8k2Z1w3rQp5y8v4M7Xq=s176-c-k-c0x00ffffff-no-rj',
        title: 'Al Jazeera Live: Middle East and Global Diplomatic Summit Coverage',
        timeAgo: 'Yesterday',
        videoId: 'gCNeDWCI0vo',
        videoThumbnailUrl: 'https://i.ytimg.com/vi/gCNeDWCI0vo/hqdefault.jpg',
        isRead: true,
        isLive: true,
      ),
    ];
  }

  /// Mark all notifications as read (e.g. when visiting the Notifications screen)
  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _safeNotifyListeners();
  }

  /// Mark a single notification as read
  void markAsRead(String id) {
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    _safeNotifyListeners();
  }

  /// Remove a notification
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _safeNotifyListeners();
  }

  /// Mute or turn off notifications from a specific channel
  void muteChannel(String channelName) {
    _notifications.removeWhere((n) => n.channelName.toLowerCase() == channelName.toLowerCase());
    _safeNotifyListeners();
  }
}
