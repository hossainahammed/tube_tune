import 'dart:math';
import '../../models/video_model.dart';
import 'storage_service.dart';
import 'youtube_service.dart';

/// YouTube-style Personalized Recommendation Engine.
/// Analyzes user watch history, search queries, and engagement to generate tailored video suggestions.
class RecommendationService {
  static final RecommendationService instance = RecommendationService._();

  RecommendationService._();

  /// Extract the user's most frequently watched channels from watch history
  List<String> getTopChannels(List<VideoModel> watchHistory) {
    if (watchHistory.isEmpty) return [];

    final Map<String, int> channelFrequency = {};
    for (final v in watchHistory) {
      final author = v.author.trim();
      if (author.isNotEmpty) {
        channelFrequency[author] = (channelFrequency[author] ?? 0) + 1;
      }
    }

    final sorted = channelFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).take(5).toList();
  }

  /// Extract the user's top interest keywords from watched titles and recent searches
  List<String> getTopInterestKeywords(List<VideoModel> watchHistory, List<String> recentSearches) {
    final Set<String> interests = {};

    // 1. Add recent search terms as high-priority user intent
    for (final query in recentSearches.take(4)) {
      if (query.trim().isNotEmpty) {
        interests.add(query.trim());
      }
    }

    // 2. Extract significant topics and categories from watched video titles
    final List<String> stopWords = [
      'the', 'and', 'for', 'with', 'video', 'news', 'live', 'official',
      'full', 'episode', '2024', '2025', '2026', 'part', 'আজকের', 'খবর',
      'এই', 'কি', 'না', 'হবে', 'থেকে', 'করে'
    ];

    final Map<String, int> wordCount = {};
    for (final v in watchHistory.take(15)) {
      final words = v.title
          .replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), ' ')
          .toLowerCase()
          .split(RegExp(r'\s+'));

      for (final w in words) {
        if (w.length > 3 && !stopWords.contains(w)) {
          wordCount[w] = (wordCount[w] ?? 0) + 1;
        }
      }
    }

    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedWords.take(4)) {
      interests.add(entry.key);
    }

    return interests.toList();
  }

  /// Generate personalized search query seeds based on user's behavioral profile
  List<String> getRecommendationSeeds(StorageService storage) {
    final history = storage.getWatchHistory();
    final searches = storage.getRecentSearches();

    final topChannels = getTopChannels(history);
    final topInterests = getTopInterestKeywords(history, searches);

    final List<String> seeds = [];

    // Seed 1: Top watched channels
    for (final channel in topChannels.take(2)) {
      seeds.add('$channel latest');
    }

    // Seed 2: Top recent searches / interests
    for (final interest in topInterests.take(2)) {
      seeds.add(interest);
    }

    // Seed 3: Time-of-day dynamic seed if seeds are sparse
    if (seeds.length < 3) {
      seeds.addAll(_getTimeOfDaySeeds());
    }

    return seeds;
  }

  /// Time-sensitive seeds to prevent stale/static data throughout the day
  List<String> _getTimeOfDaySeeds() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Morning
      return ['bangladesh morning news update', 'today prime bulletin', 'morning special report'];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      return ['midday news bulletin bangladesh', 'top stories today', 'latest development news'];
    } else if (hour >= 17 && hour < 21) {
      // Evening Prime
      return ['evening news bulletin live', 'prime news tonight', 'talk show analysis bangladesh'];
    } else {
      // Night / Late
      return ['night news wrap up', 'breaking headlines today', 'international news roundup'];
    }
  }

  /// Fetch personalized suggested videos directly from YouTube using user profile
  Future<List<VideoModel>> fetchSuggestedVideos(
    YoutubeService youtubeService,
    StorageService storage, {
    int maxResults = 10,
  }) async {
    final seeds = getRecommendationSeeds(storage);
    final List<VideoModel> pool = [];
    final seenIds = <String>{};

    // Exclude currently watched or recently watched IDs so recommendations are fresh
    final historyIds = storage.getWatchHistory().map((v) => v.id).toSet();

    for (final query in seeds.take(3)) {
      try {
        final results = await youtubeService.searchLiveYouTube(query);
        for (final v in results) {
          if (!seenIds.contains(v.id) && !historyIds.contains(v.id)) {
            seenIds.add(v.id);
            pool.add(v);
          }
        }
      } catch (_) {}
    }

    // If pool is still empty, fetch fresh time-of-day trending
    if (pool.isEmpty) {
      final timeSeeds = _getTimeOfDaySeeds();
      for (final query in timeSeeds) {
        try {
          final results = await youtubeService.searchLiveYouTube(query);
          for (final v in results) {
            if (!seenIds.contains(v.id)) {
              seenIds.add(v.id);
              pool.add(v);
            }
          }
        } catch (_) {}
      }
    }

    // Shuffle slightly for organic variety
    pool.shuffle(Random());
    return pool.take(maxResults).toList();
  }
}
