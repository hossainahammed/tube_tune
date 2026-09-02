import 'package:flutter_test/flutter_test.dart';
import 'package:tube_tune/core/constants/app_categories.dart';
import 'package:tube_tune/core/services/filter_service.dart';
import 'package:tube_tune/models/timer_model.dart';
import 'package:tube_tune/models/video_model.dart';

void main() {
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
  });
}
