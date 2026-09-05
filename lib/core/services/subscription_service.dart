import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/channel_model.dart';
import '../../models/video_model.dart';
import 'storage_service.dart';
import 'youtube_service.dart';

/// Subscription Service managing subscribed channels with persistent storage and real-time synchronization.
class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  final StorageService storageService;

  List<ChannelModel> _subscribedChannels = [];

  SubscriptionService._({required this.storageService}) {
    _loadSubscriptions();
  }

  static Future<SubscriptionService> getInstance(StorageService storageService) async {
    _instance ??= SubscriptionService._(storageService: storageService);
    return _instance!;
  }

  static SubscriptionService get instance {
    if (_instance == null) {
      throw StateError('SubscriptionService must be initialized before access');
    }
    return _instance!;
  }

  static const String _keySubscribedChannels = 'subscribed_channels_v2';

  List<ChannelModel> get subscribedChannels => List.unmodifiable(_subscribedChannels);

  void _loadSubscriptions() {
    final rawList = storageService.getStringList(_keySubscribedChannels);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        final loaded = rawList
            .map((item) => ChannelModel.fromJson(jsonDecode(item) as Map<String, dynamic>))
            .toList();

        final defaults = {for (final d in _getDefaultChannels()) d.name.toLowerCase().trim(): d.avatarUrl};

        _subscribedChannels = loaded.map((c) {
          final normName = c.name.toLowerCase().trim();
          if (defaults.containsKey(normName) && (c.avatarUrl.isEmpty || c.avatarUrl.contains('AIdro_k2Lg0Yq3qOQ') || !c.avatarUrl.startsWith('http'))) {
            return c.copyWith(avatarUrl: defaults[normName]!);
          }
          return c;
        }).toList();
        _saveSubscriptions();
      } catch (_) {
        _subscribedChannels = List<ChannelModel>.from(_getDefaultChannels());
      }
    } else {
      _subscribedChannels = List<ChannelModel>.from(_getDefaultChannels());
      _saveSubscriptions();
    }
    notifyListeners();
  }

  Future<void> _saveSubscriptions() async {
    final encoded = _subscribedChannels.map((c) => jsonEncode(c.toJson())).toList();
    await storageService.setStringList(_keySubscribedChannels, encoded);
  }

  /// Default verified channels matching safe family & educational focus
  List<ChannelModel> _getDefaultChannels() {
    return const [
      ChannelModel(
        id: 'ch_somoy_tv',
        name: 'SOMOY TV',
        avatarUrl: 'https://yt3.ggpht.com/HIVp56M09fDcVPKGpRXkl47xJcG7JGV5Mwn8E_7TlwmPgjgg1MQ7t_oxiy4xkmgo5fmWxilY3yU=s176-c-k-c0x00ffffff-no-rj',
        subscriberCount: '5.2M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Official 24/7 Live Broadcast News Channel from Bangladesh.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_jamuna_tv',
        name: 'Jamuna TV',
        avatarUrl: 'https://yt3.ggpht.com/54prTx28YpPxSpk_PfJGuOfQgcZbNdvbfk0adGePrAvINO4Mo9_bw3j-J4seXn6hNGuMr1ck=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '4.8M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Jamuna Television non-stop live news and investigative reports.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_channel24',
        name: 'Channel 24',
        avatarUrl: 'https://yt3.ggpht.com/8Q8MCd6ypr2Hzbp60VE_stJPl063kQYfeTxdIQkAXRfhdzxByLl0sJYHsk43uTM4W_cOzwcbPQ=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '3.6M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Channel 24 Live TV news bulletins and political discussions.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_independent_tv',
        name: 'Independent Television',
        avatarUrl: 'https://yt3.ggpht.com/JO8MicN497ze8WVXcu-wmA2WAMqhO8UIQhslV3VhiRu1kaQU3r9nOB4IVkmUt0ALC23DVSSp=s176-c-k-c0x00ffffff-no-rj',
        subscriberCount: '3.1M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Independent Television breaking news and talk shows.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_news24_bd',
        name: 'NEWS24',
        avatarUrl: 'https://yt3.ggpht.com/FK8kaDWHXG4F4yCVGbGP9gE5hNOOTBTXof6KFMrhj3BZ2yW0oHy7PxJRRP8QdMZfGWCNTG3L4g=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '2.9M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'NEWS24 national and international prime news bulletins.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_bbc_official',
        name: 'BBC News',
        avatarUrl: 'https://yt3.ggpht.com/v4JamQ9B-PUiJHjmZQs9UwTaoLQW8vijJMMpV5QvA2wHQ6iwWM8Q1s6O4jgTl0dtDigVWAi7SA=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '15.4M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'BBC News provides trusted world news and in-depth analysis.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_aljazeera',
        name: 'Al Jazeera English',
        avatarUrl: 'https://yt3.ggpht.com/XsTga3Nsfc1E6ZgC6HfHfzTG_3zhuZleOnsKxSK2aILMjwkkIm-0vdALFaU-yt0Lw07iLtbSifk=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '12.8M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Al Jazeera English global news coverage.',
        hasNewUpload: true,
      ),
      ChannelModel(
        id: 'ch_veritasium',
        name: 'Veritasium',
        avatarUrl: 'https://yt3.ggpht.com/7vCbvtCqtjQ3YLgsJt7Y952MQV1sBvhllSCSxHP8_sVZdcPCBrITfhkN2RdyCuwPnsByq-1GoA=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '16.2M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'An element of truth - videos about science, education, and physics.',
        hasNewUpload: false,
      ),
      ChannelModel(
        id: 'ch_ted_ed',
        name: 'TED-Ed',
        avatarUrl: 'https://yt3.ggpht.com/PKUi-Lc3VFjUfsIhjK3n-FJDNBf-XQLdg4G4bv4fPFF96D3MVnkbub9ePpLoWdmdFgl5I1Zd=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '19.5M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Lessons worth sharing - animated educational explanations.',
        hasNewUpload: false,
      ),
      ChannelModel(
        id: 'ch_nasa',
        name: 'NASA',
        avatarUrl: 'https://yt3.ggpht.com/eIf5fNPcIcj9ig-wZBeq4stFy1lgjWTW1nLT5dYlFkHZprZ03QBiMcbpwNMB6XSBjrSFGtAGQg=s176-c-k-c0x00ffffff-no-rj-mo',
        subscriberCount: '11.8M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Explore the universe and discover our home planet with NASA.',
        hasNewUpload: false,
      ),
      ChannelModel(
        id: 'ch_assunnah',
        name: 'As-Sunnah Foundation',
        avatarUrl: 'https://yt3.ggpht.com/ytc/AIdro_kmsjs7L9AOWOUX-vhwVh3Ody05f6C9rrjcSTkAFsbDGg=s176-c-k-c0x00ffffff-no-rj',
        subscriberCount: '4.2M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Islamic lectures, humanitarian activities, and peaceful life reminders.',
        hasNewUpload: true,
      ),
    ];
  }

  /// Check if a channel is subscribed by channel name or ID
  bool isSubscribed(String nameOrId) {
    if (nameOrId.isEmpty) return false;
    final clean = nameOrId.toLowerCase().trim();
    return _subscribedChannels.any(
      (c) => c.name.toLowerCase().trim() == clean || c.id.toLowerCase().trim() == clean,
    );
  }

  /// Subscribe to a channel
  Future<bool> subscribe(ChannelModel channel) async {
    final cleanName = channel.name.toLowerCase().trim();
    if (!isSubscribed(cleanName)) {
      final updated = channel.copyWith(isSubscribed: true);
      _subscribedChannels.insert(0, updated);
      await _saveSubscriptions();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Subscribe from video model
  Future<bool> subscribeFromVideo(VideoModel video) async {
    final cleanAuthor = video.author.trim();
    if (cleanAuthor.isEmpty) return false;

    final existingIndex = _subscribedChannels.indexWhere(
      (c) => c.name.toLowerCase().trim() == cleanAuthor.toLowerCase(),
    );

    if (existingIndex >= 0) {
      _subscribedChannels[existingIndex] = _subscribedChannels[existingIndex].copyWith(isSubscribed: true);
    } else {
      final avatar = video.channelAvatarUrl.isNotEmpty
          ? video.channelAvatarUrl
          : YoutubeService.getCachedChannelAvatar(video.author, channelId: video.channelId);

      _subscribedChannels.insert(
        0,
        ChannelModel(
          id: video.channelId.isNotEmpty ? video.channelId : 'ch_${video.id}',
          name: cleanAuthor,
          avatarUrl: avatar,
          subscriberCount: '1.2M subscribers',
          isVerified: true,
          isSubscribed: true,
          hasNewUpload: true,
        ),
      );
    }

    await _saveSubscriptions();
    notifyListeners();
    return true;
  }

  /// Unsubscribe from a channel
  Future<bool> unsubscribe(String nameOrId) async {
    final clean = nameOrId.toLowerCase().trim();
    final index = _subscribedChannels.indexWhere(
      (c) => c.name.toLowerCase().trim() == clean || c.id.toLowerCase().trim() == clean,
    );
    if (index >= 0) {
      _subscribedChannels.removeAt(index);
      await _saveSubscriptions();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Toggle subscription state
  Future<bool> toggleSubscription(ChannelModel channel) async {
    if (isSubscribed(channel.name)) {
      return unsubscribe(channel.name);
    } else {
      return subscribe(channel);
    }
  }

  /// Toggle subscription from video
  Future<bool> toggleSubscriptionFromVideo(VideoModel video) async {
    if (isSubscribed(video.author)) {
      return unsubscribe(video.author);
    } else {
      return subscribeFromVideo(video);
    }
  }

  /// Discover recommended popular channels
  List<ChannelModel> getDiscoverChannels() {
    final currentSubbed = _subscribedChannels.map((c) => c.name.toLowerCase().trim()).toSet();
    final all = _getDefaultChannels();
    return all.where((c) => !currentSubbed.contains(c.name.toLowerCase().trim())).toList();
  }
}
