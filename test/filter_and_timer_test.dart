import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_tune/core/constants/app_categories.dart';
import 'package:tube_tune/core/services/auth_service.dart';
import 'package:tube_tune/core/services/cast_service.dart';
import 'package:tube_tune/core/services/filter_service.dart';
import 'package:tube_tune/core/services/notification_service.dart';
import 'package:tube_tune/core/services/recommendation_service.dart';
import 'package:tube_tune/core/services/storage_service.dart';
import 'package:tube_tune/core/services/subscription_service.dart';
import 'package:tube_tune/models/channel_model.dart';
import 'package:tube_tune/models/download_task_model.dart';
import 'package:tube_tune/models/timer_model.dart';
import 'package:tube_tune/models/video_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TubeTune Comprehensive Filter & Protection Tests', () {
    final filterService = FilterService.instance;

    final islamicCategory = AppCategories.defaultCategories.firstWhere((c) => c.id == AppCategories.categoryIslamicWaz);
    final newsCategory = AppCategories.defaultCategories.firstWhere((c) => c.id == AppCategories.categoryNews);

    const wazVideo = VideoModel(
      id: 'w1',
      title: 'Mizanur Rahman Azhari New Waz and Tafseer 2026',
      author: 'Islamic Life BD',
      channelId: 'ch_waz',
      thumbnailUrl: '',
      duration: Duration(minutes: 45),
      viewCount: 150000,
      uploadDate: '2 days ago',
      categoryTag: AppCategories.categoryIslamicWaz,
      tags: ['waz', 'islamic', 'tafseer', 'azhari'],
    );

    const cartoonVideo = VideoModel(
      id: 'k1',
      title: 'Meena Cartoon Full Episode for Kids',
      author: 'UNICEF Animation',
      channelId: 'ch_kids',
      thumbnailUrl: '',
      duration: Duration(minutes: 15),
      viewCount: 200000,
      uploadDate: '1 week ago',
      categoryTag: AppCategories.categoryKidsCartoons,
      tags: ['cartoon', 'meena cartoon', 'kids', 'animation'],
    );

    const adultShort = VideoModel(
      id: 's_adult',
      title: '18+ Hot Viral Romantic Scene #shorts #hot',
      author: 'Sensual Shorts',
      channelId: 'ch_adult',
      thumbnailUrl: '',
      duration: Duration(seconds: 40),
      viewCount: 50000,
      uploadDate: 'Today',
      isShort: true,
      categoryTag: 'general',
      tags: ['18+', 'nsfw', 'hot', 'shorts'],
    );

    const islamicShort = VideoModel(
      id: 's_islamic',
      title: 'Heart Touching Quran Recitation Surah Rahman #shorts #quran',
      author: 'Quran Daily',
      channelId: 'ch_quran',
      thumbnailUrl: '',
      duration: Duration(seconds: 50),
      viewCount: 90000,
      uploadDate: 'Yesterday',
      isShort: true,
      categoryTag: AppCategories.categoryIslamicWaz,
      tags: ['quran', 'islamic', 'recitation', 'shorts'],
    );

    test('1. 18+ Reels are strictly blocked', () {
      expect(filterService.is18Plus(adultShort), isTrue);

      final isAllowed = filterService.isAllowedVideo(
        adultShort,
        enableShorts: true,
        block18Plus: true,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: [],
      );
      expect(isAllowed, isFalse, reason: '18+ shorts must be blocked');
    });

    test('2. Shorts Switch: When disabled, all shorts are rejected', () {
      final isAllowed = filterService.isAllowedVideo(
        islamicShort,
        enableShorts: false, // Shorts disabled
        block18Plus: true,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: [],
      );
      expect(isAllowed, isFalse, reason: 'Shorts must be rejected when enableShorts is false');
    });

    test('3. Out-of-category content is strictly blocked when specific category is selected', () {
      // User only selected Islamic & Waz
      final selectedCategories = [islamicCategory];

      // Waz video is allowed
      expect(
        filterService.isAllowedVideo(
          wazVideo,
          enableShorts: true,
          block18Plus: true,
          strictCategoryMode: true,
          enabledCategories: selectedCategories,
          customBlacklist: [],
        ),
        isTrue,
      );

      // Cartoon video is BLOCKED because it is out-of-category
      expect(
        filterService.isAllowedVideo(
          cartoonVideo,
          enableShorts: true,
          block18Plus: true,
          strictCategoryMode: true,
          enabledCategories: selectedCategories,
          customBlacklist: [],
        ),
        isFalse,
        reason: 'Out-of-category cartoon video must be blocked when only Islamic category is active',
      );
    });

    test('4. Custom blacklist blocks specific channels or keywords', () {
      const blacklistedVideo = VideoModel(
        id: 'b1',
        title: 'Celebrity Gossip & Drama News',
        author: 'Gossip Channel',
        channelId: 'ch_gossip',
        thumbnailUrl: '',
        duration: Duration(minutes: 10),
        viewCount: 10000,
        uploadDate: 'Today',
        categoryTag: AppCategories.categoryNews,
      );

      final isAllowed = filterService.isAllowedVideo(
        blacklistedVideo,
        enableShorts: true,
        block18Plus: true,
        strictCategoryMode: false,
        enabledCategories: [newsCategory],
        customBlacklist: ['gossip'],
      );
      expect(isAllowed, isFalse, reason: 'Custom blacklisted keyword must be rejected');
    });

    test('5. Multiple Schedule Windows validate allowed times accurately', () {
      const morningWindow = ScheduleWindow(
        id: 'w_morning',
        name: 'Morning Window',
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
      );

      const eveningWindow = ScheduleWindow(
        id: 'w_evening',
        name: 'Evening Window',
        startHour: 16,
        startMinute: 0,
        endHour: 20,
        endMinute: 0,
      );

      const timer = TimerModel(
        isScheduleEnabled: true,
        scheduleWindows: [morningWindow, eveningWindow],
      );

      // 09:00 AM is inside Morning window
      final morningTime = DateTime(2026, 9, 1, 9, 0);
      expect(timer.isOutsideSchedule(morningTime), isFalse);

      // 05:00 PM (17:00) is inside Evening window
      final eveningTime = DateTime(2026, 9, 1, 17, 0);
      expect(timer.isOutsideSchedule(eveningTime), isFalse);

      // 02:00 PM (14:00) is outside BOTH windows -> Locked!
      final outsideTime = DateTime(2026, 9, 1, 14, 0);
      expect(timer.isOutsideSchedule(outsideTime), isTrue);
    });

    test('6. 18+ Button Enabled: All contents like songs, movies, etc. are allowed as default YouTube', () {
      const songVideo = VideoModel(
        id: 'song_1',
        title: 'Top Hits Song - Official Music Video',
        author: 'Pop Star',
        channelId: 'ch_music',
        thumbnailUrl: '',
        duration: Duration(minutes: 3, seconds: 30),
        viewCount: 5000000,
        uploadDate: 'Yesterday',
        categoryTag: AppCategories.categoryMusicSongs,
      );

      const movieVideo = VideoModel(
        id: 'mov_1',
        title: 'Action Movie 2026 Full Cinema HD',
        author: 'Mega Cinema',
        channelId: 'ch_cinema',
        thumbnailUrl: '',
        duration: Duration(hours: 2),
        viewCount: 12000000,
        uploadDate: '3 days ago',
        categoryTag: AppCategories.categoryMoviesCinema,
      );

      // When 18+ button is ENABLED (block18Plus == false)
      expect(
        filterService.isAllowedVideo(
          songVideo,
          enableShorts: true,
          block18Plus: false, // 18+ button ENABLED
          strictCategoryMode: true,
          enabledCategories: AppCategories.defaultCategories,
          customBlacklist: [],
        ),
        isTrue,
        reason: 'Songs must be allowed when 18+ button is enabled',
      );

      expect(
        filterService.isAllowedVideo(
          movieVideo,
          enableShorts: true,
          block18Plus: false, // 18+ button ENABLED
          strictCategoryMode: true,
          enabledCategories: AppCategories.defaultCategories,
          customBlacklist: [],
        ),
        isTrue,
        reason: 'Movies must be allowed when 18+ button is enabled',
      );
    });

    test('7. 18+ Button Disabled: Songs, movies, and adult content are strictly blocked in safe mode', () {
      const songVideo = VideoModel(
        id: 'song_1',
        title: 'Top Hits Song - Official Music Video',
        author: 'Pop Star',
        channelId: 'ch_music',
        thumbnailUrl: '',
        duration: Duration(minutes: 3, seconds: 30),
        viewCount: 5000000,
        uploadDate: 'Yesterday',
        categoryTag: AppCategories.categoryMusicSongs,
      );

      // When 18+ button is DISABLED (block18Plus == true)
      expect(
        filterService.isAllowedVideo(
          songVideo,
          enableShorts: true,
          block18Plus: true, // 18+ button DISABLED (Safe Mode)
          strictCategoryMode: true,
          enabledCategories: AppCategories.defaultCategories,
          customBlacklist: [],
        ),
        isFalse,
        reason: 'Songs must be blocked when 18+ button is disabled',
      );
    });

    test('8. Live TV Category: Safely filters and allows 24/7 Live Broadcasts without throwing StateError', () {
      const liveStreamVideo = VideoModel(
        id: 'live_tv_1',
        title: 'SOMOY TV Live | সময় টিভি সরাসরি | 24/7 Live News Stream',
        author: 'SOMOY TV',
        channelId: 'ch_somoy',
        thumbnailUrl: '',
        duration: Duration.zero,
        viewCount: 3000000,
        uploadDate: 'Live Now',
        isLive: true,
        categoryTag: AppCategories.categoryNews,
      );

      const nonLiveVideo = VideoModel(
        id: 'doc_1',
        title: 'Ancient History Documentary Episode 1',
        author: 'History Channel',
        channelId: 'ch_history',
        thumbnailUrl: '',
        duration: Duration(minutes: 45),
        viewCount: 100000,
        uploadDate: '3 years ago',
        isLive: false,
        categoryTag: AppCategories.categoryEducationTech,
      );

      // Verify that selecting Live TV category does not throw StateError and allows live streams
      expect(
        filterService.isAllowedVideo(
          liveStreamVideo,
          enableShorts: true,
          block18Plus: true,
          strictCategoryMode: true,
          enabledCategories: AppCategories.defaultCategories,
          customBlacklist: [],
          currentSelectedCategoryId: AppCategories.categoryLiveTv,
        ),
        isTrue,
        reason: 'Live stream must be allowed under Live TV category',
      );

      expect(
        filterService.isAllowedVideo(
          nonLiveVideo,
          enableShorts: true,
          block18Plus: true,
          strictCategoryMode: true,
          enabledCategories: AppCategories.defaultCategories,
          customBlacklist: [],
          currentSelectedCategoryId: AppCategories.categoryLiveTv,
        ),
        isFalse,
        reason: 'Non-live catalog video must be filtered out under Live TV category',
      );
    });

    test('9. CastService: Discovers Smart TVs, connects, adjusts volume, and links TV code', () async {
      final castService = CastService.instance;
      expect(castService.isConnected, isFalse);

      await castService.startScanning();
      expect(castService.availableDevices.isNotEmpty, isTrue);

      final tv = castService.availableDevices.first;
      await castService.connectToDevice(tv);
      expect(castService.isConnected, isTrue);
      expect(castService.connectedDevice?.name, tv.name);

      castService.setVolume(0.5);
      expect(castService.volume, 0.5);

      castService.disconnect();
      expect(castService.isConnected, isFalse);

      final linked = await castService.linkWithTvCode('123456789012');
      expect(linked, isTrue);
      expect(castService.isConnected, isTrue);
      castService.disconnect();
    });

    test('10. NotificationService: Tracks unread count, marks as read, and removes notification', () {
      final notifService = NotificationService.instance;
      expect(notifService.notifications.isNotEmpty, isTrue);
      
      final initialUnread = notifService.unreadCount;
      expect(initialUnread, greaterThan(0));

      notifService.markAllAsRead();
      expect(notifService.unreadCount, 0);

      final initialLength = notifService.notifications.length;
      final firstId = notifService.notifications.first.id;
      notifService.removeNotification(firstId);
      expect(notifService.notifications.length, initialLength - 1);
    });

    test('11. AuthService: Name formatter extracts clean display names from real Gmails', () {
      expect(AuthService.formatNameFromEmail('hossain.ahmed@gmail.com'), 'Hossain Ahmed');
      expect(AuthService.formatNameFromEmail('tanvir_hasan_bd@gmail.com'), 'Tanvir Hasan Bd');
      expect(AuthService.formatNameFromEmail('simpleuser@gmail.com'), 'Simpleuser');
    });

    test('12. RecommendationService: Extracts top channels and keywords for personalized YouTube suggestions', () {
      final recService = RecommendationService.instance;
      const history = [
        VideoModel(
          id: 'v1',
          title: 'Flutter Advanced Architecture Tutorial',
          author: 'Flutter Dev',
          channelId: 'ch1',
          thumbnailUrl: '',
          duration: Duration(minutes: 10),
          viewCount: 1000,
          uploadDate: '1 day ago',
          categoryTag: AppCategories.categoryEducationTech,
        ),
        VideoModel(
          id: 'v2',
          title: 'Flutter Riverpod and State Management Guide',
          author: 'Flutter Dev',
          channelId: 'ch1',
          thumbnailUrl: '',
          duration: Duration(minutes: 15),
          viewCount: 2000,
          uploadDate: '2 days ago',
          categoryTag: AppCategories.categoryEducationTech,
        ),
        VideoModel(
          id: 'v3',
          title: 'Bangladesh vs India Cricket Highlights',
          author: 'Cricket World',
          channelId: 'ch2',
          thumbnailUrl: '',
          duration: Duration(minutes: 12),
          viewCount: 50000,
          uploadDate: '3 hours ago',
          categoryTag: AppCategories.categorySports,
        ),
      ];

      final topChannels = recService.getTopChannels(history);
      expect(topChannels.first, 'Flutter Dev');

      final keywords = recService.getTopInterestKeywords(history, ['Dart tips', 'Tech']);
      expect(keywords.contains('Dart tips'), isTrue);
      expect(keywords.contains('Tech'), isTrue);
      expect(keywords.contains('flutter'), isTrue);
    });

    test('13. DownloadedVideoModel: Formats file sizes and serializes correctly', () {
      const video = VideoModel(
        id: 'dl_1',
        title: 'Offline Flutter Video',
        author: 'Code Channel',
        channelId: 'ch_code',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        duration: Duration(minutes: 8),
        viewCount: 500,
        uploadDate: '1 week ago',
        categoryTag: AppCategories.categoryEducationTech,
      );

      final dl = DownloadedVideoModel(
        video: video,
        localFilePath: '/data/user/0/com.tubetune.app/downloads/dl_1.mp4',
        fileSizeBytes: 45 * 1024 * 1024, // 45 MB
        downloadedAt: DateTime(2026, 9, 3),
      );

      expect(dl.formattedSize, '45.0 MB');

      final json = dl.toJson();
      expect(json['localFilePath'], '/data/user/0/com.tubetune.app/downloads/dl_1.mp4');
      expect(json['fileSizeBytes'], 45 * 1024 * 1024);

      final parsed = DownloadedVideoModel.fromJson(json);
      expect(parsed.video.id, 'dl_1');
      expect(parsed.localFilePath, dl.localFilePath);
      expect(parsed.formattedSize, '45.0 MB');
    });

    test('14. Not Interested: FilterService blocks videos with IDs in hiddenVideoIds', () {
      final list = [wazVideo, cartoonVideo];
      final res = filterService.filterList(
        list,
        enableShorts: true,
        block18Plus: false,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: const [],
        hiddenVideoIds: [wazVideo.id],
      );

      expect(res.allowed.map((v) => v.id), contains(cartoonVideo.id));
      expect(res.allowed.map((v) => v.id), isNot(contains(wazVideo.id)));
      expect(res.filteredCount, 1);
    });

    test('15. Don\'t Recommend Channel: FilterService blocks channel author and channelId', () {
      final list = [wazVideo, cartoonVideo];

      // Block by author name (case insensitive)
      final resByAuthor = filterService.filterList(
        list,
        enableShorts: true,
        block18Plus: false,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: const [],
        blockedChannels: ['islamic life bd'],
      );
      expect(resByAuthor.allowed.map((v) => v.id), isNot(contains(wazVideo.id)));
      expect(resByAuthor.allowed.map((v) => v.id), contains(cartoonVideo.id));

      // Block by channelId
      final resById = filterService.filterList(
        list,
        enableShorts: true,
        block18Plus: false,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: const [],
        blockedChannels: ['ch_kids'],
      );
      expect(resById.allowed.map((v) => v.id), isNot(contains(cartoonVideo.id)));
      expect(resById.allowed.map((v) => v.id), contains(wazVideo.id));
    });

    test('16. Search Exception: Feed filter excludes hidden/blocked items, but Search query does not', () {
      final list = [wazVideo, cartoonVideo];

      // Normal Feed Filter: Blocks wazVideo because it was marked Not Interested
      final feedResult = filterService.filterList(
        list,
        enableShorts: true,
        block18Plus: false,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: const [],
        hiddenVideoIds: [wazVideo.id],
      );
      expect(feedResult.allowed.map((v) => v.id), isNot(contains(wazVideo.id)));

      // Explicit Search: Does not pass hiddenVideoIds, allowing the user to find it again
      final searchResult = filterService.filterList(
        list,
        enableShorts: true,
        block18Plus: false,
        strictCategoryMode: false,
        enabledCategories: AppCategories.defaultCategories,
        customBlacklist: const [],
      );
      expect(searchResult.allowed.map((v) => v.id), contains(wazVideo.id));
    });

    test('17. ChannelModel: JSON serialization, copyWith, and equality methods work correctly', () {
      const channel = ChannelModel(
        id: 'ch_test_101',
        name: 'Tech World BD',
        avatarUrl: 'https://example.com/avatar.jpg',
        subscriberCount: '1.5M subscribers',
        isVerified: true,
        isSubscribed: true,
        description: 'Test Channel description',
        hasNewUpload: true,
      );

      final json = channel.toJson();
      final restored = ChannelModel.fromJson(json);

      expect(restored.id, channel.id);
      expect(restored.name, channel.name);
      expect(restored.avatarUrl, channel.avatarUrl);
      expect(restored.subscriberCount, channel.subscriberCount);
      expect(restored.isVerified, isTrue);
      expect(restored.isSubscribed, isTrue);
      expect(restored.hasNewUpload, isTrue);

      final updated = channel.copyWith(isSubscribed: false, hasNewUpload: false);
      expect(updated.isSubscribed, isFalse);
      expect(updated.hasNewUpload, isFalse);
      expect(updated.name, channel.name);
    });

    test('18. SubscriptionService: Manages default channels, subscribes from VideoModel, and toggles subscriptions', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.getInstance();
      final subService = await SubscriptionService.getInstance(storage);

      // Verify default channels loaded
      expect(subService.subscribedChannels.isNotEmpty, isTrue);
      expect(subService.isSubscribed('SOMOY TV'), isTrue);
      expect(subService.isSubscribed('BBC News'), isTrue);

      // Subscribe from video
      const newVideo = VideoModel(
        id: 'vid_new_channel',
        title: 'New Breakthrough in Physics',
        author: 'Quantum Physics Lab',
        channelId: 'ch_quantum_99',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        channelAvatarUrl: 'https://example.com/quantum.jpg',
        duration: Duration(minutes: 10),
        viewCount: 50000,
        uploadDate: 'Today',
        categoryTag: AppCategories.categoryEducationTech,
      );

      expect(subService.isSubscribed(newVideo.author), isFalse);
      await subService.subscribeFromVideo(newVideo);
      expect(subService.isSubscribed(newVideo.author), isTrue);

      // Toggle subscription from video
      await subService.toggleSubscriptionFromVideo(newVideo);
      expect(subService.isSubscribed(newVideo.author), isFalse);

      // Discover channels
      final discover = subService.getDiscoverChannels();
      expect(discover, isA<List<ChannelModel>>());
    });
  });
}
